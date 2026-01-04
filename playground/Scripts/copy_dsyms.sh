#!/bin/bash
# Copy dSYM files to archive for App Store submission
# This script ensures all dSYMs (app, extensions, frameworks) are included in the archive
# It should run as a "Run Script Phase" AFTER the "Embed Frameworks" phase

# CRITICAL: Exit immediately to avoid sandbox permission issues
# Xcode automatically handles dSYM collection for archive builds
# This script is disabled due to sandbox restrictions - Xcode's built-in dSYM handling is sufficient
exit 0

# CRITICAL: Check for app extensions FIRST using only shell built-ins (no external commands)
# App extensions (including widgets) have dSYMs handled automatically by Xcode
# This script should only run for the main app target
# Using shell parameter expansion to avoid any external command calls
if [ "${PRODUCT_TYPE}" = "com.apple.product-type.app-extension" ] || [ "${PRODUCT_TYPE}" = "XPC!" ]; then
    # Silently exit - no need to log for extensions
    exit 0
fi

# Check bundle identifier for widget extensions (using shell pattern matching)
# This avoids calling grep which might not be available in sandbox
case "${PRODUCT_BUNDLE_IDENTIFIER}" in
    *.widget)
        exit 0
        ;;
esac

# Don't exit on error - gracefully handle permission issues
set +e

echo "📦 [dSYM Copy] Starting dSYM collection..."

# Only run for Archive builds (not Debug/Release builds)
if [ "${ACTION}" != "install" ]; then
    echo "📦 [dSYM Copy] Skipping - not an archive build (ACTION=${ACTION})"
    exit 0
fi

# The archive's dSYMs folder - this is where App Store Connect expects to find all dSYMs
# During archive, Xcode sets ARCHIVE_PRODUCTS_PATH and INSTALL_PATH
TARGET_DSYMS_DIR=""

if [ -n "$ARCHIVE_PRODUCTS_PATH" ] && [ -n "$INSTALL_PATH" ]; then
    TARGET_DSYMS_DIR="${ARCHIVE_PRODUCTS_PATH}${INSTALL_PATH}/../dSYMs"
elif [ -n "$DWARF_DSYM_FOLDER_PATH" ]; then
    # Use DWARF_DSYM_FOLDER_PATH parent directory
    TARGET_DSYMS_DIR="$(dirname "$DWARF_DSYM_FOLDER_PATH")/dSYMs"
elif [ -n "$CONFIGURATION_BUILD_DIR" ]; then
    TARGET_DSYMS_DIR="$(dirname "$CONFIGURATION_BUILD_DIR")/dSYMs"
fi

# If we still don't have a target directory, try to find it from the archive path
if [ -z "$TARGET_DSYMS_DIR" ] || [ ! -d "$(dirname "$TARGET_DSYMS_DIR")" ]; then
    # Try to find archive dSYMs folder
    if [ -n "$BUILT_PRODUCTS_DIR" ]; then
        TARGET_DSYMS_DIR="$(dirname "$BUILT_PRODUCTS_DIR")/dSYMs"
    fi
fi

# If we can't determine the target directory, exit gracefully
if [ -z "$TARGET_DSYMS_DIR" ]; then
    echo "⚠️  [dSYM Copy] Could not determine target dSYMs directory"
    echo "   This is normal for non-archive builds"
    exit 0
fi

# Create dSYMs directory if it doesn't exist (may fail due to permissions, that's OK)
mkdir -p "$TARGET_DSYMS_DIR" 2>/dev/null || {
    echo "⚠️  [dSYM Copy] Could not create target directory: $TARGET_DSYMS_DIR"
    echo "   This may be due to sandbox restrictions"
    exit 0
}

echo "📦 [dSYM Copy] Target directory: $TARGET_DSYMS_DIR"

# 1. Copy main app dSYM (if it exists)
if [ -n "$DWARF_DSYM_FOLDER_PATH" ] && [ -n "$DWARF_DSYM_FILE_NAME" ]; then
    MAIN_DSYM="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
    if [ -d "$MAIN_DSYM" ] && [ -r "$MAIN_DSYM" ]; then
        echo "📦 [dSYM Copy] Copying main app dSYM: $DWARF_DSYM_FILE_NAME"
        cp -R "$MAIN_DSYM" "$TARGET_DSYMS_DIR/" 2>/dev/null || {
            echo "⚠️  [dSYM Copy] Could not copy main app dSYM (permission issue?)"
        }
    else
        echo "⚠️  [dSYM Copy] Main app dSYM not found or not readable at: $MAIN_DSYM"
    fi
fi

# 2. Find and copy all dSYMs from build products (frameworks, extensions)
# This covers frameworks from Swift Packages, CocoaPods, and app extensions
if [ -n "$BUILT_PRODUCTS_DIR" ] && [ -d "$BUILT_PRODUCTS_DIR" ] && [ -r "$BUILT_PRODUCTS_DIR" ]; then
    echo "📦 [dSYM Copy] Searching for dSYMs in: $BUILT_PRODUCTS_DIR"
    
    # Search in the build products directory and parent directories
    find "$BUILT_PRODUCTS_DIR" -name "*.dSYM" -type d 2>/dev/null | while read dsym_path; do
        if [ ! -r "$dsym_path" ]; then
            continue
        fi
        
        dsym_name=$(basename "$dsym_path")
        
        # Skip if already copied (main app dSYM)
        if [ "$dsym_name" = "$DWARF_DSYM_FILE_NAME" ]; then
            continue
        fi
        
        # Check if already in target directory
        if [ ! -d "$TARGET_DSYMS_DIR/$dsym_name" ]; then
            echo "📦 [dSYM Copy] Copying: $dsym_name"
            cp -R "$dsym_path" "$TARGET_DSYMS_DIR/" 2>/dev/null || {
                echo "⚠️  [dSYM Copy] Could not copy $dsym_name (permission issue?)"
            }
        else
            echo "📦 [dSYM Copy] Already exists: $dsym_name"
        fi
    done
else
    echo "⚠️  [dSYM Copy] BUILT_PRODUCTS_DIR not accessible: $BUILT_PRODUCTS_DIR"
fi

# 3. Search in DWARF_DSYM_FOLDER_PATH for additional dSYMs
if [ -n "$DWARF_DSYM_FOLDER_PATH" ] && [ -d "$DWARF_DSYM_FOLDER_PATH" ] && [ -r "$DWARF_DSYM_FOLDER_PATH" ]; then
    echo "📦 [dSYM Copy] Searching in DWARF_DSYM_FOLDER_PATH: $DWARF_DSYM_FOLDER_PATH"
    
    find "$DWARF_DSYM_FOLDER_PATH" -name "*.dSYM" -type d 2>/dev/null | while read dsym_path; do
        if [ ! -r "$dsym_path" ]; then
            continue
        fi
        
        dsym_name=$(basename "$dsym_path")
        
        # Skip if already copied
        if [ "$dsym_name" = "$DWARF_DSYM_FILE_NAME" ]; then
            continue
        fi
        
        if [ ! -d "$TARGET_DSYMS_DIR/$dsym_name" ]; then
            echo "📦 [dSYM Copy] Copying from DWARF_DSYM_FOLDER_PATH: $dsym_name"
            cp -R "$dsym_path" "$TARGET_DSYMS_DIR/" 2>/dev/null || {
                echo "⚠️  [dSYM Copy] Could not copy $dsym_name (permission issue?)"
            }
        fi
    done
fi

# 4. Search in DerivedData for framework dSYMs (SPM packages)
# This is often where framework dSYMs from Swift Package Manager are located
# Note: This may fail due to sandbox restrictions, which is OK
DERIVED_DATA_PATH="${DERIVED_DATA_DIR:-$HOME/Library/Developer/Xcode/DerivedData}"
if [ -d "$DERIVED_DATA_PATH" ] && [ -r "$DERIVED_DATA_PATH" ]; then
    echo "📦 [dSYM Copy] Searching in DerivedData: $DERIVED_DATA_PATH"
    
    # Find project-specific DerivedData folder
    PROJECT_NAME=$(basename "$SRCROOT")
    find "$DERIVED_DATA_PATH" -name "${PROJECT_NAME}*" -type d -maxdepth 1 2>/dev/null | while read project_dir; do
        if [ ! -r "$project_dir" ]; then
            continue
        fi
        
        find "$project_dir" -name "*.dSYM" -type d 2>/dev/null | while read dsym_path; do
            if [ ! -r "$dsym_path" ]; then
                continue
            fi
            
            dsym_name=$(basename "$dsym_path")
            
            # Skip if already in target directory
            if [ ! -d "$TARGET_DSYMS_DIR/$dsym_name" ]; then
                echo "📦 [dSYM Copy] Copying from DerivedData: $dsym_name"
                cp -R "$dsym_path" "$TARGET_DSYMS_DIR/" 2>/dev/null || {
                    echo "⚠️  [dSYM Copy] Could not copy $dsym_name from DerivedData (permission issue?)"
                }
            fi
        done
    done
else
    echo "⚠️  [dSYM Copy] DerivedData not accessible (this is normal in sandboxed builds)"
fi

# 5. List all dSYMs in target directory for verification
echo ""
echo "📦 [dSYM Copy] Final dSYM list in archive:"
if [ -d "$TARGET_DSYMS_DIR" ] && [ -r "$TARGET_DSYMS_DIR" ]; then
    ls -la "$TARGET_DSYMS_DIR" 2>/dev/null | grep "\.dSYM" || echo "   (none found)"
else
    echo "   ⚠️  Target directory not accessible: $TARGET_DSYMS_DIR"
fi

echo "✅ [dSYM Copy] Completed"
