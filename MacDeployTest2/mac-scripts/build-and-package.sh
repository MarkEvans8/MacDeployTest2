#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/.."

# Load all settings — copy config.sh.example to config.sh and fill in your values
source "$SCRIPT_DIR/config.sh"

echo "======================================"
echo "Building and packaging $APP_NAME"
echo "======================================"
echo ""
echo "Certificates:"
echo "  App:       $APP_CERT"
echo "  Installer: $INSTALLER_CERT"
echo ""

cd "$PROJECT_DIR"

echo "Cleaning..."
dotnet clean -f net10.0-maccatalyst -c Release -r maccatalyst-arm64 -p:EnableXcodeValidation=true
rm -rf bin/Release obj/Release

echo ""
echo "Building..."
dotnet publish -f net10.0-maccatalyst -c Release -r maccatalyst-arm64 -p:EnableXcodeValidation=true

APP_PATH=$(find bin/Release/net10.0-maccatalyst/maccatalyst-arm64 \
    -name "${APP_NAME}.app" -type d 2>/dev/null | head -n 1)
echo "Found app: $APP_PATH"

echo ""
echo "Signing embedded binaries..."
while IFS= read -r -d '' binary; do
    echo "  $(basename "$binary")"
    codesign --force --options runtime --timestamp --sign "$APP_CERT" "$binary"
done < <(find "$APP_PATH" \( -name "*.dylib" -o -name "*.so" \) -type f -print0)

echo ""
echo "Signing app bundle..."
ENTITLEMENTS_TEMP=$(mktemp /tmp/entitlements.XXXXXX.plist)
cp "$PROJECT_DIR/Platforms/MacCatalyst/Entitlements.plist" "$ENTITLEMENTS_TEMP"
plutil -convert xml1 "$ENTITLEMENTS_TEMP"
codesign --force --verify --options runtime --timestamp \
    --entitlements "$ENTITLEMENTS_TEMP" \
    --sign "$APP_CERT" "$APP_PATH"
rm -f "$ENTITLEMENTS_TEMP"

echo ""
echo "Verifying signature..."
codesign --verify --deep --strict "$APP_PATH"

echo ""
echo "Creating .pkg installer..."
PKG_ROOT="$PROJECT_DIR/package_root"
rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT/Applications"
cp -R "$APP_PATH" "$PKG_ROOT/Applications/"

PKG_OUTPUT="$PROJECT_DIR/${APP_NAME}.pkg"
pkgbuild \
    --root "$PKG_ROOT" \
    --identifier "$BUNDLE_ID" \
    --version "$VERSION" \
    --install-location / \
    --sign "$INSTALLER_CERT" \
    "$PKG_OUTPUT"

rm -rf "$PKG_ROOT"

echo ""
echo "======================================"
echo "Done!"
echo "Package: $PKG_OUTPUT"
echo "Size:    $(du -h "$PKG_OUTPUT" | cut -f1)"
echo ""
echo "Next: run ./notarize.sh"
echo "======================================"
