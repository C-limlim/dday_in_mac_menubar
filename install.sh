#!/bin/bash
set -e

GITHUB_REPO="C-limlim/dday_in_mac_manubar"
APP_NAME="DdayMenuBar"
INSTALL_DIR="$HOME/Applications"

echo "📅 D-Day 메뉴바 설치 중..."

# 최신 릴리즈 다운로드 URL 조회
DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
  | grep '"browser_download_url"' \
  | grep '\.zip' \
  | head -1 \
  | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
  echo "❌ 릴리즈를 찾을 수 없습니다. GitHub에 릴리즈가 배포되어 있는지 확인하세요."
  exit 1
fi

echo "다운로드 중: $DOWNLOAD_URL"
curl -L "$DOWNLOAD_URL" -o /tmp/DdayMenuBar.zip

# 설치 폴더 생성 및 기존 앱 제거
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME.app"

# 압축 해제
unzip -q /tmp/DdayMenuBar.zip -d "$INSTALL_DIR"
rm /tmp/DdayMenuBar.zip

# Gatekeeper 격리 속성 제거 (ad-hoc 서명 앱 실행 허용)
xattr -rd com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

echo "✅ 설치 완료!"
echo "앱을 실행합니다..."
open "$INSTALL_DIR/$APP_NAME.app"
echo ""
echo "💡 메뉴바 아이콘을 클릭한 뒤 '로그인 시 자동 실행'을 켜면 부팅 후 자동으로 시작됩니다."
