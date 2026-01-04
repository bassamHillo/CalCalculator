#!/usr/bin/env python3
"""
Translate all English strings to all supported languages
Run manually: python3 translate_strings.py
"""
import re
import os
import urllib.parse
import urllib.request
import json
import time
import sys

lang_codes = {
    'es': 'es', 'fr': 'fr', 'de': 'de', 'it': 'it', 'pt': 'pt',
    'zh': 'zh-CN', 'ja': 'ja', 'ko': 'ko', 'ru': 'ru',
    'ar': 'ar', 'hi': 'hi'
}

def translate_text(text, target_lang, max_retries=5):
    """Translate using MyMemory API (free) with retries and better rate limiting"""
    if '%' in text or len(text.strip()) < 2:
        return text
    
    for attempt in range(max_retries):
        try:
            url = f"https://api.mymemory.translated.net/get?q={urllib.parse.quote(text[:400])}&langpair=en|{target_lang}"
            with urllib.request.urlopen(url, timeout=10) as response:
                result = json.loads(response.read().decode())
                trans = result.get('responseData', {}).get('translatedText', text)
                trans = trans.replace('&quot;', '"').replace('&#39;', "'").replace('&amp;', '&')
                
                # Check if translation is valid
                if trans != text and not trans.startswith('MYMEMORY') and 'QUOTA' not in trans.upper() and '429' not in trans:
                    return trans
                
                # If rate limited, wait much longer
                if '429' in str(result) or 'QUOTA' in trans.upper():
                    if attempt < max_retries - 1:
                        wait = min(60, 10 * (attempt + 1))  # 10s, 20s, 30s, 40s, 50s, 60s max
                        print(f"    Rate limited, waiting {wait}s...", end=' ', flush=True)
                        time.sleep(wait)
                        continue
        except urllib.error.HTTPError as e:
            if e.code == 429:  # Rate limited
                if attempt < max_retries - 1:
                    wait = min(60, 10 * (attempt + 1))  # Longer waits: 10s, 20s, 30s, 40s, 50s, 60s max
                    print(f"    HTTP 429, waiting {wait}s...", end=' ', flush=True)
                    time.sleep(wait)
                    continue
            return text
        except Exception as e:
            if attempt < max_retries - 1:
                wait = min(10, 2 * (attempt + 1))
                time.sleep(wait)
                continue
    
    return text  # Return original if all retries fail

# Read all strings
print("Reading strings from AppStrings.swift...")
with open('Models/AppStrings.swift', 'r', encoding='utf-8') as f:
    content = f.read()
    all_strings = sorted(set(re.findall(r'static let \w+ = "([^"]+)"', content)))

print(f"Found {len(all_strings)} unique strings\n")

languages = ['es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko', 'ru', 'ar', 'hi']

# Process each language
for lang_idx, lang in enumerate(languages, 1):
    file_path = f'{lang}.lproj/Localizable.strings'
    
    # Read existing
    existing = {}
    lines_to_keep = []
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                lines_to_keep.append(line)
                match = re.match(r'"([^"]+)"\s*=\s*"([^"]*)"\s*;', line)
                if match:
                    existing[match.group(1)] = match.group(2)
    
    # Find untranslated strings
    to_translate = [s for s in all_strings if s in existing and existing[s] == s]
    
    if not to_translate:
        print(f"[{lang_idx}/12] {lang}: ✅ Already complete")
        continue
    
    print(f"[{lang_idx}/12] {lang}: Translating {len(to_translate)} strings...", end=' ', flush=True)
    translations = {}
    
    # Translate with progress updates
    for i, text in enumerate(to_translate):
        translations[text] = translate_text(text, lang_codes[lang])
        
        # Progress every 10 strings
        if (i + 1) % 10 == 0:
            print(f"{i+1}...", end=' ', flush=True)
            sys.stdout.flush()
        
        # Very slow rate limiting to avoid 429 errors (free API limits)
        time.sleep(2.0)  # 2 seconds between requests to respect rate limits
        
        # Save progress every 50 strings in case of interruption
        if (i + 1) % 50 == 0:
            new_lines = []
            for line in lines_to_keep:
                match = re.match(r'"([^"]+)"\s*=\s*"([^"]*)"\s*;', line)
                if match and match.group(1) in translations:
                    new_lines.append(f'"{match.group(1)}" = "{translations[match.group(1)]}";\n')
                else:
                    new_lines.append(line)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            print(f" [saved]", end=' ', flush=True)
    
    # Update file
    new_lines = []
    for line in lines_to_keep:
        match = re.match(r'"([^"]+)"\s*=\s*"([^"]*)"\s*;', line)
        if match and match.group(1) in translations:
            new_lines.append(f'"{match.group(1)}" = "{translations[match.group(1)]}";\n')
        else:
            new_lines.append(line)
    
    # Save immediately
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    translated_count = sum(1 for k, v in translations.items() if v != k)
    print(f"✅ {translated_count}/{len(to_translate)} translated")

print("\n✅ Translation complete for all languages!")

