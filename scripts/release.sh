#!/bin/bash
# Kodomon release script
# Usage: ./scripts/release.sh v1.0.8
#
# Prerequisites:
#   1. Sparkle SPM package added to Xcode project
#   2. EdDSA keys generated (run: sparkle-generate-keys)
#   3. Build the Release archive in Xcode first
#
# This script:
#   - Creates a signed DMG from the built app
#   - Updates appcast.xml with the new release
#   - Outputs the GitHub release command to run

set -e

BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

VERSION="$1"
if [[ -z "$VERSION" ]]; then
    echo "${RED}Usage: ./scripts/release.sh v1.0.8${RESET}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LANDING_DIR="$REPO_DIR/../kodomon.app"
RELEASES_DIR="$REPO_DIR/releases"
APP_PATH="/Applications/Kodomon.app"
DMG_NAME="Kodomon.dmg"
DMG_PATH="$RELEASES_DIR/$DMG_NAME"

# Find Sparkle tools in DerivedData
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
SPARKLE_BIN=$(find "$DERIVED_DATA" -path "*/Sparkle/bin/generate_appcast" -type f 2>/dev/null | head -1)

if [[ -z "$SPARKLE_BIN" ]]; then
    echo "${RED}Sparkle tools not found in DerivedData.${RESET}"
    echo "Build the project in Xcode first so SPM resolves the package."
    exit 1
fi
SPARKLE_DIR="$(dirname "$SPARKLE_BIN")"

echo ""
echo "${BOLD}Kodomon Release ${VERSION}${RESET}"
echo ""

# Check the built app exists
if [[ ! -d "$APP_PATH" ]]; then
    echo "${RED}App not found at $APP_PATH${RESET}"
    echo "Build and archive in Xcode first."
    exit 1
fi

# Create releases dir
mkdir -p "$RELEASES_DIR"

# Remove old DMG if exists
rm -f "$DMG_PATH"

# Create DMG
echo "Creating DMG..."
hdiutil create -volname "Kodomon" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"
echo "  ${GREEN}DMG created${RESET}"

# Generate appcast (signs DMG + creates/updates appcast.xml)
echo "Generating appcast..."
"$SPARKLE_DIR/generate_appcast" "$RELEASES_DIR" \
    --download-url-prefix "https://github.com/brysonkbarney/kodomon/releases/download/${VERSION}/"
echo "  ${GREEN}Appcast generated${RESET}"

# Copy appcast to landing page repo
if [[ -d "$LANDING_DIR" ]]; then
    cp "$RELEASES_DIR/appcast.xml" "$LANDING_DIR/appcast.xml"
    echo "  ${GREEN}Copied appcast.xml to kodomon.app repo${RESET}"
else
    echo "  Landing page repo not found at $LANDING_DIR"
    echo "  Copy $RELEASES_DIR/appcast.xml to your kodomon.app repo manually."
fi

echo ""
echo "${GREEN}${BOLD}Release ready!${RESET}"
echo ""
echo "Next steps:"
echo "  1. Push appcast.xml to kodomon.app repo (deploys to Vercel)"
echo "  2. Create GitHub release:"
echo ""
echo "     gh release create ${VERSION} ${DMG_PATH} --title \"${VERSION}\" --notes \"Release ${VERSION}\""
echo ""
