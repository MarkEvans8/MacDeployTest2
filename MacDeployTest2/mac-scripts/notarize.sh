#!/bin/bash

echo "======================================"
echo "Notarizing MacDeployTest2.pkg"
echo "======================================"
echo ""

APP_NAME="MacDeployTest2"
PKG_FILE="${APP_NAME}.pkg"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/.."
PKG_PATH="$PROJECT_DIR/$PKG_FILE"

# Load config if present (git-ignored; see config.sh.example to set up)
CONFIG_FILE="$SCRIPT_DIR/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Check if .pkg exists
if [ ! -f "$PKG_PATH" ]; then
    echo -e "${RED}âœ— Could not find $PKG_FILE${NC}"
    echo "Please run ./build-and-package.sh first"
    exit 1
fi

echo "This script will submit your .pkg to Apple for notarization."
echo ""

# Prompt for credentials only if not already set in config.sh
if [ -z "$APPLE_ID" ] || [ -z "$APP_PASSWORD" ] || [ -z "$TEAM_ID" ]; then
    echo -e "${YELLOW}You will need:${NC}"
    echo "1. Your Apple ID email"
    echo "2. An app-specific password (NOT your regular Apple ID password)"
    echo "3. Your Team ID"
    echo ""
    echo "To create an app-specific password:"
    echo "  1. Go to https://appleid.apple.com"
    echo "  2. Sign in"
    echo "  3. Go to 'Sign-In and Security' -> 'App-Specific Passwords'"
    echo "  4. Click '+' to generate a new password"
    echo "  5. Copy the password (it looks like: xxxx-xxxx-xxxx-xxxx)"
    echo ""
    echo "To find your Team ID:"
    echo "  1. Go to https://developer.apple.com/account"
    echo "  2. Look for 'Membership details'"
    echo "  3. Your Team ID is a 10-character code"
    echo ""
    read -p "Press Enter when you have this information ready..."
    echo ""
    [ -z "$APPLE_ID" ]     && read -p "Enter your Apple ID email: " APPLE_ID
    [ -z "$APP_PASSWORD" ] && read -sp "Enter your app-specific password: " APP_PASSWORD && echo ""
    [ -z "$TEAM_ID" ]      && read -p "Enter your Team ID: " TEAM_ID
else
    echo "Using credentials from config.sh (Apple ID: $APPLE_ID, Team: $TEAM_ID)"
fi


echo ""
echo "Submitting to Apple for notarization..."
echo "This may take a few minutes..."
echo ""

NOTARY_OUTPUT=$(xcrun notarytool submit "$PKG_PATH" \
  --apple-id "$APPLE_ID" \
  --password "$APP_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait 2>&1)

echo "$NOTARY_OUTPUT"

SUBMISSION_ID=$(echo "$NOTARY_OUTPUT" | grep "^  id:" | head -n 1 | awk '{print $2}')
NOTARY_STATUS=$(echo "$NOTARY_OUTPUT" | grep "^  status:" | awk '{print $2}')

if [ "$NOTARY_STATUS" = "Accepted" ]; then
    echo ""
    echo -e "${GREEN}✓ Notarization successful!${NC}"
    echo ""
    echo "Stapling the notarization ticket to the .pkg..."
    xcrun stapler staple "$PKG_PATH"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Stapling successful!${NC}"
        echo ""
        echo "======================================"
        echo -e "${GREEN}COMPLETE!${NC}"
        echo "======================================"
        echo ""
        echo "Your .pkg is now notarized and ready to distribute!"
        echo "Location: $PKG_PATH"
        echo ""
    else
        echo -e "${RED}✗ Stapling failed${NC}"
        echo "The .pkg is notarized but the ticket couldn't be attached."
        echo "Users will still be able to install it, but they'll need an internet connection."
    fi
else
    echo ""
    echo -e "${RED}✗ Notarization failed (status: ${NOTARY_STATUS:-unknown})${NC}"
    echo ""
    if [ -n "$SUBMISSION_ID" ]; then
        echo "Fetching rejection log from Apple..."
        echo ""
        xcrun notarytool log "$SUBMISSION_ID" \
          --apple-id "$APPLE_ID" \
          --password "$APP_PASSWORD" \
          --team-id "$TEAM_ID"
        echo ""
    fi
    echo "Common issues:"
    echo "1. App not signed with hardened runtime (--options runtime)"
    echo "2. Unsigned binaries or frameworks inside the .app"
    echo "3. Wrong Apple ID, password, or Team ID"
    echo ""
    echo "Re-run ./build-and-package.sh and then ./notarize.sh after fixing the issue."
fi
