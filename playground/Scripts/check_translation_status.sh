#!/bin/bash
cd /Users/zoharbuchris/Documents/CalCalculator/playground
python3 << 'PYEOF'
import re
import os
languages = ['es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko', 'ru', 'ar', 'hi']
with open('Models/AppStrings.swift', 'r') as f:
    all_strings = set(re.findall(r'static let \w+ = "([^"]+)"', f.read()))
print("Translation Status:\n")
complete = 0
for lang in languages:
    path = f'{lang}.lproj/Localizable.strings'
    existing = {}
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            for line in f:
                m = re.match(r'"([^"]+)"\s*=\s*"([^"]*)"\s*;', line)
                if m:
                    existing[m.group(1)] = m.group(2)
    needs = len([s for s in all_strings if s in existing and existing[s] == s])
    translated = len([s for s in all_strings if s in existing and existing[s] != s])
    if needs == 0:
        complete += 1
        print(f"{lang}: ✅ Complete ({translated} strings)")
    else:
        pct = int((translated / len(all_strings)) * 100) if all_strings else 0
        print(f"{lang}: ⏳ {needs} remaining ({pct}% done, {translated}/{len(all_strings)})")
print(f"\nProgress: {complete}/11 languages complete")
PYEOF
