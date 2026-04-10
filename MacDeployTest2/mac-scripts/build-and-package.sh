#!/bin/bash

echo "======================================"
echo "Packaging MacDeployTest2 as .pkg"
echo "======================================"
echo ""
echo "NOTE: This script builds the app directly on this Mac using dotnet publish."
echo ""

# Configuration
APP_NAME="MacDeployTest2"
BUNDLE_ID="com.companyname.macdeploytest2"
VERSION="1.0"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Ã¢Å“â€œ $1${NC}"
    else
        echo -e "${RED}Ã¢Å“â€” $1 - FAILED${NC}"
        exit 1
    fi
}

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/.."

# Load config if present (git-ignored; see config.sh.example to set up)
CONFIG_FILE="$SCRIPT_DIR/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

echo "Project directory: $PROJECT_DIR"
echo ""

# Navigate to project directory
cd "$PROJECT_DIR"
check_status "Changed to project directory"

# Always do a fresh build so csproj changes (bundle ID, title, etc.) are always applied.
# Building for arm64 (Apple Silicon / M-series Macs).
# To also support Intel Macs, add a second publish for maccatalyst-x64 and use lipo.
echo ""
echo "Cleaning previous build artifacts..."
dotnet clean -f net10.0-maccatalyst -c Release -r maccatalyst-arm64 -p:EnableXcodeValidation=true
rm -rf obj/Release bin/Release
check_status "Clean"

echo ""
echo "Building app for maccatalyst-arm64..."
dotnet publish -f net10.0-maccatalyst -c Release -r maccatalyst-arm64 -p:EnableXcodeValidation=true
check_status "dotnet publish (arm64)"

APP_PATH=$(find bin/Release/net10.0-maccatalyst/maccatalyst-arm64 \
    -name "${APP_NAME}.app" -type d 2>/dev/null | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}Could not find ${APP_NAME}.app after build${NC}"
    ls -la bin/Release/net10.0-maccatalyst/ 2>/dev/null
    exit 1
fi

echo ""
echo "Found app at: $APP_PATH"

# Ask for signing certificate names if not already set in config.sh
if [ -z "$APP_CERT" ] || [ -z "$INSTALLER_CERT" ]; then
    echo ""
    echo "Available signing identities:"
    security find-identity -v -p codesigning
    echo ""
    echo "======================================"
    echo "Please enter your certificate info:"
    echo "======================================"
    echo ""
    [ -z "$APP_CERT" ] && read -p "Enter your 'Developer ID Application' name (e.g., 'Developer ID Application: John Doe (TEAM123)'): " APP_CERT
    [ -z "$INSTALLER_CERT" ] && read -p "Enter your 'Developer ID Installer' name (e.g., 'Developer ID Installer: John Doe (TEAM123)'): " INSTALLER_CERT
else
    echo "Using certificates from config.sh:"
    echo "  App:       $APP_CERT"
    echo "  Installer: $INSTALLER_CERT"
fi

# Sign embedded dylibs first (Apple requires inside-out signing; --deep is unreliable)
echo ""
echo "Signing embedded binaries..."
SIGN_FAILED=0
while IFS= read -r -d '' binary; do
    echo "  Signing: $(basename "$binary")"
    if ! codesign --force --options runtime --timestamp --sign "$APP_CERT" "$binary"; then
        echo -e "${RED}Failed to sign: $binary${NC}"
        SIGN_FAILED=1
        break
    fi
done < <(find "$APP_PATH" \( -name "*.dylib" -o -name "*.so" \) -type f -print0)

if [ $SIGN_FAILED -ne 0 ]; then
    echo -e "${RED}âœ— Signed embedded binaries - FAILED${NC}"
    exit 1
fi
echo -e "${GREEN}âœ“ Signed embedded binaries${NC}"

# Sign the app bundle (include entitlements so the sandbox works correctly)
echo ""
echo "Signing the app bundle..."
ENTITLEMENTS="$PROJECT_DIR/Platforms/MacCatalyst/Entitlements.plist"
if [ -f "$ENTITLEMENTS" ]; then
    echo "Using entitlements: $ENTITLEMENTS"
    # Normalise to Unix line endings and valid plist format (fixes Windows CRLF issue)
    ENTITLEMENTS_TEMP=$(mktemp /tmp/entitlements.XXXXXX.plist)
    cp "$ENTITLEMENTS" "$ENTITLEMENTS_TEMP"
    plutil -convert xml1 "$ENTITLEMENTS_TEMP"
    codesign --force --verify --verbose --options runtime --timestamp --entitlements "$ENTITLEMENTS_TEMP" --sign "$APP_CERT" "$APP_PATH"
    SIGN_RESULT=$?
    rm -f "$ENTITLEMENTS_TEMP"
    if [ $SIGN_RESULT -ne 0 ]; then
        echo -e "${RED}âœ— Signed the app - FAILED${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Warning: Entitlements.plist not found at $ENTITLEMENTS â€” signing without entitlements${NC}"
    codesign --force --verify --verbose --options runtime --timestamp --sign "$APP_CERT" "$APP_PATH"
fi
echo -e "${GREEN}âœ“ Signed the app${NC}"

# Verify the signature
echo ""
echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
check_status "Verified signature"

# Create package directory structure
echo ""
echo "Creating package structure..."
PKG_ROOT="$PROJECT_DIR/package_root"
rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT/Applications"
check_status "Created package structure"

# Copy app to package root
echo "Copying app to package structure..."
cp -R "$APP_PATH" "$PKG_ROOT/Applications/"
check_status "Copied app to package"

# Build the .pkg
PKG_OUTPUT="$PROJECT_DIR/${APP_NAME}.pkg"
echo ""
echo "Building the .pkg installer..."
pkgbuild --root "$PKG_ROOT" \
         --identifier "$BUNDLE_ID" \
         --version "$VERSION" \
         --install-location / \
         --sign "$INSTALLER_CERT" \
         "$PKG_OUTPUT"
check_status "Built the .pkg"

# Clean up
rm -rf "$PKG_ROOT"

# -------------------------------------------------------
# QUICK TEST: copy the signed .app directly to /Applications
# so you can verify the app runs without needing the pkg installer
# -------------------------------------------------------
# echo ""
# echo "Copying signed app directly to /Applications for quick testing..."
# sudo rm -rf "/Applications/${APP_NAME}.app"
# sudo cp -R "$APP_PATH" "/Applications/${APP_NAME}.app"
# if [ $? -eq 0 ]; then
#     echo -e "${GREEN}âœ“ App copied to /Applications/${APP_NAME}.app${NC}"
#     echo ""
#     echo "Opening /Applications in Finder..."
#     open /Applications
# else
#     echo -e "${YELLOW}âš  Direct copy failed (you can ignore this - the .pkg is still ready)${NC}"
# fi

echo ""
echo "======================================"
echo -e "${GREEN}SUCCESS!${NC}"
echo "======================================"
echo ""
echo "Your installer is ready at:"
echo "$PKG_OUTPUT"
echo ""
echo "File size: $(du -h "$PKG_OUTPUT" | cut -f1)"
echo ""
echo "NEXT STEP (OPTIONAL but recommended):"
echo "To distribute outside the Mac App Store, you should notarize this .pkg"
echo "Run: ./notarize.sh"
echo ""
