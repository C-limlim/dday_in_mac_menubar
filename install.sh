#!/bin/bash
set -e

APP_NAME="DdayMenuBar"
INSTALL_DIR="$HOME/Applications"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📅 D-Day 메뉴바 설치 중..."

# Xcode Command Line Tools 확인
if ! command -v swift &>/dev/null; then
  echo "❌ Swift가 없습니다. 아래 명령어로 설치 후 다시 실행하세요:"
  echo "   xcode-select --install"
  exit 1
fi

# 빌드
echo "빌드 중..."
cd "$SCRIPT_DIR/DdayApp"
swift build -c release 2>&1 | tail -2

# 앱 번들 생성
echo "설치 중..."
rm -rf "$INSTALL_DIR/$APP_NAME.app"
mkdir -p "$INSTALL_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$INSTALL_DIR/$APP_NAME.app/Contents/Resources"
cp .build/release/DdayApp "$INSTALL_DIR/$APP_NAME.app/Contents/MacOS/"
cp "$SCRIPT_DIR/Info.plist" "$INSTALL_DIR/$APP_NAME.app/Contents/"
cp "$SCRIPT_DIR/Resources/AppIcon.icns" "$INSTALL_DIR/$APP_NAME.app/Contents/Resources/"

# 서명
codesign --force --deep --sign - "$INSTALL_DIR/$APP_NAME.app"

echo "✅ 완료! 앱을 시작합니다."
open "$INSTALL_DIR/$APP_NAME.app"
