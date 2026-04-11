#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/.."

# Load all settings — copy config.sh.example to config.sh and fill in your values
source "$SCRIPT_DIR/config.sh"

PKG_PATH="$PROJECT_DIR/${APP_NAME}.pkg"

echo "======================================"
echo "Notarizing ${APP_NAME}.pkg"
echo "======================================"
echo ""

echo "Submitting to Apple (takes 2-5 minutes)..."
xcrun notarytool submit "$PKG_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APP_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait

echo ""
echo "Stapling notarization ticket..."
xcrun stapler staple "$PKG_PATH"

echo ""
echo "======================================"
echo "Done! $PKG_PATH is notarized and ready to distribute."
echo "======================================"
