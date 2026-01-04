#!/bin/bash
# Build the app to verify everything compiles
# Usage: ./build_app.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "🔨 Building app..."
echo ""

# Find the Xcode project
PROJECT_FILE=$(find . -name "*.xcodeproj" -o -name "*.xcworkspace" | head -1)

if [ -z "$PROJECT_FILE" ]; then
    echo "❌ Error: No Xcode project found"
    exit 1
fi

echo "Found project: $PROJECT_FILE"
echo ""

# Get scheme
PROJECT_NAME=$(basename "$PROJECT_FILE" .xcodeproj)
PROJECT_NAME=$(basename "$PROJECT_NAME" .xcworkspace)
SCHEME="$PROJECT_NAME"

# Try to find actual scheme
if [[ "$PROJECT_FILE" == *.xcworkspace ]]; then
    SCHEMES=$(xcodebuild -workspace "$PROJECT_FILE" -list 2>/dev/null | grep -A 20 "Schemes:" | grep -v "Schemes:" | xargs)
    if [ -n "$SCHEMES" ]; then
        SCHEME=$(echo "$SCHEMES" | awk '{print $1}')
    fi
else
    SCHEMES=$(xcodebuild -project "$PROJECT_FILE" -list 2>/dev/null | grep -A 20 "Schemes:" | grep -v "Schemes:" | xargs)
    if [ -n "$SCHEMES" ]; then
        SCHEME=$(echo "$SCHEMES" | awk '{print $1}')
    fi
fi

echo "Building scheme: $SCHEME"
echo ""

# Check if xcpretty is available
if command -v xcpretty &> /dev/null; then
    PRETTY_CMD="xcpretty"
else
    PRETTY_CMD="cat"
fi

if [[ "$PROJECT_FILE" == *.xcworkspace ]]; then
    xcodebuild -workspace "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        clean build \
        2>&1 | $PRETTY_CMD || {
        echo ""
        echo "❌ Build failed!"
        exit 1
    }
else
    xcodebuild -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        clean build \
        2>&1 | $PRETTY_CMD || {
        echo ""
        echo "❌ Build failed!"
        exit 1
    }
fi

echo ""
echo "✅ Build successful!"

