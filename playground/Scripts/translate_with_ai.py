#!/usr/bin/env python3
"""
Complete AI translation workflow
This script will be used by AI to translate all strings at once
"""
import re
import os
import json

lang_codes = {
    'es': 'Spanish',
    'fr': 'French', 
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'zh': 'Chinese (Simplified)',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ru': 'Russian',
    'ar': 'Arabic',
    'hi': 'Hindi'
}

# Read all strings
print("Reading strings from AppStrings.swift...")
with open('Models/AppStrings.swift', 'r', encoding='utf-8') as f:
    content = f.read()
    all_strings = sorted(set(re.findall(r'static let \w+ = "([^"]+)"', content)))

print(f"Found {len(all_strings)} unique strings\n")

languages = ['es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko', 'ru', 'ar', 'hi']

# Collect all strings that need translation for each language
all_translations_needed = {}

for lang_idx, lang in enumerate(languages, 1):
    file_path = f'{lang}.lproj/Localizable.strings'
    
    # Read existing
    existing = {}
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                match = re.match(r'"([^"]+)"\s*=\s*"([^"]*)"\s*;', line)
                if match:
                    existing[match.group(1)] = match.group(2)
    
    # Find untranslated strings
    to_translate = [s for s in all_strings if s in existing and existing[s] == s]
    
    if to_translate:
        all_translations_needed[lang] = {
            'language': lang_codes[lang],
            'strings': to_translate
        }
        print(f"[{lang_idx}/12] {lang}: {len(to_translate)} strings need translation")
    else:
        print(f"[{lang_idx}/12] {lang}: ✅ Already complete")

if not all_translations_needed:
    print("\n✅ All translations complete!")
    exit(0)

# Create master JSON for AI translation
master_json = {
    "instructions": "Translate all English strings to the target languages. Preserve format strings like %@, %d, %.1f exactly as they appear. Return translations in the same structure.",
    "translations": all_translations_needed
}

with open('all_translations.json', 'w', encoding='utf-8') as f:
    json.dump(master_json, f, indent=2, ensure_ascii=False)

print(f"\n✅ Created all_translations.json with {len(all_translations_needed)} languages")
print(f"   Total strings to translate: {sum(len(v['strings']) for v in all_translations_needed.values())}")
print("\nThis file is ready for AI translation!")

