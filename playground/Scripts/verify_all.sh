#!/bin/bash
# Complete verification: Translation → Build → Tests
# Usage: ./verify_all.sh

set -e

cd "$(dirname "$0")"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Complete App Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Check translation status
echo "📝 Step 1: Checking translation status..."
python3 << 'PYEOF'
import re
import os
languages = ['es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko', 'ru', 'ar', 'hi']
with open('Models/AppStrings.swift', 'r') as f:
    all_strings = set(re.findall(r'static let \w+ = "([^"]+)"', f.read()))
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
    if needs == 0:
        complete += 1
if complete < 11:
    print(f"⚠️  Translation incomplete: {complete}/11 languages")
    print("   Run: python3 translate_strings.py")
else:
    print("✅ All translations complete")
PYEOF

echo ""
read -p "Continue with build? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Step 2: Build
echo ""
echo "🔨 Step 2: Building app..."
if ./build_app.sh; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

# Step 3: Run tests
echo ""
echo "🧪 Step 3: Running unit tests..."
if ./run_tests.sh; then
    echo "✅ All tests passed"
else
    echo "❌ Tests failed"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ All verifications passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

