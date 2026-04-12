#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/.."

# Verify the scripts are in the right place - PROJECT_DIR must contain a .csproj
if ! ls "$PROJECT_DIR"/*.csproj 2>/dev/null | grep -q .; then
    echo ""
    echo "ERROR: No .csproj file found in $PROJECT_DIR"
    echo ""
    echo "The mac-scripts folder must be placed INSIDE your project folder"
    echo "(the folder that contains your .csproj), not at the solution level."
    echo ""
    echo "Correct structure:"
    echo "  YourProject/          <- .csproj lives here"
    echo "    mac-scripts/        <- scripts must be here"
    echo "    YourProject.csproj"
    echo ""
    echo "Current script location: $SCRIPT_DIR"
    echo "Looking for .csproj in:  $PROJECT_DIR"
    echo ""
    exit 1
fi

# Load all settings - copy config.sh.example to config.sh and fill in your values
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
