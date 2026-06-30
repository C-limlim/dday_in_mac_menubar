#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="DdayMenuBar"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "빌드 중..."

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"

swiftc "$SCRIPT_DIR/Sources/main.swift" \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -sdk "$(xcrun --show-sdk-path --sdk macosx)"

cp "$SCRIPT_DIR/Info.plist" "$APP_BUNDLE/Contents/"

echo "빌드 완료: $APP_BUNDLE"
echo ""
echo "실행: open \"$APP_BUNDLE\""
