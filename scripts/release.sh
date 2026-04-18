#!/bin/bash
# Kodomon release script — bumps versions, builds, signs, and ships
# Usage: ./scripts/release.sh v1.0.9
#
# This script does EVERYTHING:
#   1. Bumps version in Info.plist + project.pbxproj
#   2. Builds Release binary
#   3. Creates signed DMG
#   4. Generates appcast.xml (EdDSA signed)
#   5. Copies appcast to kodomon.app repo
#   6. Commits + pushes both repos
#   7. Creates GitHub release with DMG

set -e

BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

VERSION="$1"
if [[ -z "$VERSION" ]]; then
    echo "${RED}Usage: ./scripts/release.sh v1.0.9 [build]${RESET}"
    echo "  build defaults to auto-increment from current Info.plist value"
    exit 1
fi

# Strip leading 'v' for version strings (v1.0.9 → 1.0.9)
MARKETING_VERSION="${VERSION#v}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LANDING_DIR="$REPO_DIR/../kodomon.app"
RELEASES_DIR="$REPO_DIR/releases"
DMG_NAME="Kodomon.dmg"
DMG_PATH="$RELEASES_DIR/$DMG_NAME"
PLIST="$REPO_DIR/Kodomon/Info.plist"
PBXPROJ="$REPO_DIR/Kodomon.xcodeproj/project.pbxproj"

# Build number: use second arg if provided, else auto-increment from current.
# This decouples the build number (monotonic for Sparkle) from the marketing
# version (semver), so we can jump to 1.1.0 without resetting the build to 0.
if [[ -n "$2" ]]; then
    BUILD_NUMBER="$2"
else
    CURRENT_BUILD=$(plutil -extract CFBundleVersion raw -o - "$PLIST" 2>/dev/null || echo "0")
    BUILD_NUMBER=$((CURRENT_BUILD + 1))
fi

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

# ── Step 1: Bump versions ──────────────────────────────────────────
echo "Bumping version to ${MARKETING_VERSION} (build ${BUILD_NUMBER})..."

# Info.plist
sed -i '' "s|<string>[0-9]*</string><!-- CFBundleVersion -->|<string>${BUILD_NUMBER}</string><!-- CFBundleVersion -->|" "$PLIST" 2>/dev/null || true
# Use plutil for reliable plist editing
plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$PLIST"
plutil -replace CFBundleShortVersionString -string "$MARKETING_VERSION" "$PLIST"

# project.pbxproj (all occurrences in Debug + Release)
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" "$PBXPROJ"
sed -i '' "s/MARKETING_VERSION = [0-9.]*;/MARKETING_VERSION = ${MARKETING_VERSION};/g" "$PBXPROJ"

echo "  ${GREEN}Info.plist: ${MARKETING_VERSION} (${BUILD_NUMBER})${RESET}"
echo "  ${GREEN}project.pbxproj: ${MARKETING_VERSION} (${BUILD_NUMBER})${RESET}"

# ── Step 2: Build Release ──────────────────────────────────────────
echo "Building Release..."
cd "$REPO_DIR"
xcodebuild -scheme Kodomon -configuration Release -derivedDataPath build clean build 2>&1 | tail -1
echo "  ${GREEN}Build succeeded${RESET}"

# ── Step 3: Create DMG ────────────────────────────────────────────
mkdir -p "$RELEASES_DIR"
rm -f "$DMG_PATH"

echo "Creating DMG..."
hdiutil create -volname "Kodomon" -srcfolder "$REPO_DIR/build/Build/Products/Release/Kodomon.app" -ov -format UDZO "$DMG_PATH"
echo "  ${GREEN}DMG created${RESET}"

# ── Step 4: Generate appcast ──────────────────────────────────────
echo "Generating appcast..."
"$SPARKLE_DIR/generate_appcast" "$RELEASES_DIR" \
    --download-url-prefix "https://github.com/brysonkbarney/kodomon/releases/download/${VERSION}/"
echo "  ${GREEN}Appcast signed and generated${RESET}"

# ── Step 5: Copy appcast to landing page ──────────────────────────
if [[ -d "$LANDING_DIR" ]]; then
    cp "$RELEASES_DIR/appcast.xml" "$LANDING_DIR/appcast.xml"
    echo "  ${GREEN}Copied appcast.xml to kodomon.app repo${RESET}"
else
    echo "  ${RED}Landing page repo not found at $LANDING_DIR${RESET}"
    echo "  Copy $RELEASES_DIR/appcast.xml manually."
fi

# ── Step 6: Commit + push both repos ─────────────────────────────
echo "Committing and pushing..."

# Main repo
cd "$REPO_DIR"
git add -A
git commit -m "${VERSION}" || echo "  (nothing to commit in main repo)"
git push
echo "  ${GREEN}Pushed kodomon repo${RESET}"

# Landing page repo
if [[ -d "$LANDING_DIR" ]]; then
    cd "$LANDING_DIR"
    git add appcast.xml
    git commit -m "Update appcast for ${VERSION}" || echo "  (nothing to commit in landing repo)"
    git push
    echo "  ${GREEN}Pushed kodomon.app repo${RESET}"
fi

# ── Step 7: Create GitHub release ─────────────────────────────────
echo "Creating GitHub release..."
cd "$REPO_DIR"
gh release create "$VERSION" "$DMG_PATH" --title "$VERSION" --notes "Release $VERSION"

echo ""
echo "${GREEN}${BOLD}${VERSION} is live!${RESET}"
echo ""
