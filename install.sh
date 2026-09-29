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
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

# 새 번들을 완성한 뒤 기존 앱을 교체
echo "설치 중..."
mkdir -p "$INSTALL_DIR"
STAGING_DIR="$(mktemp -d "$INSTALL_DIR/.dday-install.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
STAGED_APP="$STAGING_DIR/$APP_NAME.app"
APP_PATH="$INSTALL_DIR/$APP_NAME.app"
mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
cp "$BIN_DIR/DdayApp" "$STAGED_APP/Contents/MacOS/"
cp "$SCRIPT_DIR/Info.plist" "$STAGED_APP/Contents/"
cp "$SCRIPT_DIR/Resources/AppIcon.icns" "$STAGED_APP/Contents/Resources/"

# 서명
codesign --force --deep --sign - "$STAGED_APP"

# 같은 설치 경로의 앱만 종료하고, 종료 실패 시 기존 앱 보존
swift - "$APP_PATH" <<'SWIFT'
import AppKit

let appURL = URL(fileURLWithPath: CommandLine.arguments[1]).resolvingSymlinksInPath()
let apps = NSWorkspace.shared.runningApplications.filter {
    $0.bundleURL?.resolvingSymlinksInPath() == appURL
}
for app in apps where !app.terminate() {
    print("앱을 종료하지 못했습니다. D-Day 메뉴에서 종료한 뒤 다시 설치하세요.")
    exit(1)
}
let deadline = Date().addingTimeInterval(5)
while apps.contains(where: { !$0.isTerminated }) && Date() < deadline {
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
}
guard apps.allSatisfy(\.isTerminated) else {
    print("앱 종료를 기다리다 중단했습니다. 기존 앱은 유지됩니다.")
    exit(1)
}
SWIFT

rm -rf "$APP_PATH"
mv "$STAGED_APP" "$APP_PATH"

echo "✅ 완료! 앱을 시작합니다."
open "$APP_PATH"
