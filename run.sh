#!/bin/bash
# Build and run Kodomon
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Kodomon"

echo "Building $APP_NAME..."
xcodebuild \
  -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Debug \
  build 2>&1 | grep -E "(error:|warning:.*\.swift|BUILD)" || true

# Find the built app
APP_PATH=$(xcodebuild \
  -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Debug \
  -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | head -1 | awk '{print $3}')

if [ -z "$APP_PATH" ]; then
  echo "Failed to find build output"
  exit 1
fi

FULL_APP="$APP_PATH/$APP_NAME.app"

if [ ! -d "$FULL_APP" ]; then
  echo "Build failed — app not found at $FULL_APP"
  exit 1
fi

# Kill existing instance
osascript -e "quit app \"$APP_NAME\"" 2>/dev/null || true
sleep 1

echo "Launching $APP_NAME..."
open "$FULL_APP"
echo "✓ $APP_NAME is running"
