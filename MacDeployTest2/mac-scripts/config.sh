#!/bin/bash
# ===========================================================
# config.sh — Local signing & notarization configuration.
# This file is git-ignored and stays on this machine only.
# ===========================================================
#
# ⚠️  NOTE FOR PRODUCTION / CI USE:
#   Storing credentials in a plaintext file is fine for local
#   dev, but NOT for production. In a real pipeline you should:
#
#   1. Store the app-specific password in the macOS Keychain:
#        xcrun notarytool store-credentials "notarization" \
#          --apple-id "your@email.com" \
#          --team-id "YOURTEAMID"
#      Then replace --password / --apple-id / --team-id in
#      notarize.sh with just: --keychain-profile "notarization"
#
#   2. For CI (GitHub Actions, Azure DevOps, etc.) use
#      repository secrets / environment variables instead of
#      this file, and never check credentials into source control.
# ===========================================================

# Certificate names — copy exactly from:
#   security find-identity -v -p codesigning
APP_CERT="Developer ID Application: Mark Evans (D8FNB39Y9M)"
INSTALLER_CERT="Developer ID Installer: Mark Evans (D8FNB39Y9M)"

# Apple notarization credentials
APPLE_ID="apple@markevans.org"
APP_PASSWORD="vnax-kras-ooey-mnag"   # app-specific password from appleid.apple.com
TEAM_ID="D8FNB39Y9M"
