#!/usr/bin/env python3
"""
Apply translations from JSON files to .strings files
Run after translations are added to JSON files
"""
import re
import os
import json

languages = ['es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko', 'ru', 'ar', 'hi']

print("Applying translations from JSON files...\n")

for lang_idx, lang in enumerate(languages, 1):
    json_file = f'translate_{lang}.json'
    strings_file = f'{lang}.lproj/Localizable.strings'
    
    if not os.path.exists(json_file):
        print(f"[{lang_idx}/12] {lang}: ⏭️  No JSON file found")
        continue
    
    # Read JSON with translations
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        translations = data.get('translations', {})
        if not translations:
            print(f"[{lang_idx}/12] {lang}: ⚠️  No translations in JSON")
            continue
    except Exception as e:
        print(f"[{lang_idx}/12] {lang}: ❌ Error reading JSON: {e}")
        continue
    
    # Read existing .strings file
    existing = {}
    lines_to_keep = []
    if os.path.exists(strings_file):
        with open(strings_file, 'r', encoding='utf-8') as f:
            for line in f:
                lines_to_keep.append(line)
                match = re.match(r'"([^"]+)"\s*=\s*"([^"]*)"\s*;', line)
                if match:
                    existing[match.group(1)] = match.group(2)
    
    # Update with translations
    new_lines = []
    updated_count = 0
    
    for line in lines_to_keep:
        match = re.match(r'"([^"]+)"\s*=\s*"([^"]*)"\s*;', line)
        if match and match.group(1) in translations:
            new_lines.append(f'"{match.group(1)}" = "{translations[match.group(1)]}";\n')
            updated_count += 1
        else:
            new_lines.append(line)
    
    # Save updated file
    with open(strings_file, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    print(f"[{lang_idx}/12] {lang}: ✅ Applied {updated_count} translations")

print("\n✅ All translations applied!")

