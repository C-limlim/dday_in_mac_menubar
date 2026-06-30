# D-Day 메뉴바

macOS 메뉴바에 D-Day 카운트다운을 표시하는 앱입니다.

## 설치

터미널에서 아래 명령어 한 줄을 실행하세요:

```bash
curl -fsSL https://raw.githubusercontent.com/C-limlim/dday_in_mac_manubar/main/install.sh | bash
```

> macOS 13 (Ventura) 이상 필요

## 사용법

1. 메뉴바 아이콘 클릭 → **설정...** → 이벤트 이름과 날짜 입력
2. **로그인 시 자동 실행** 켜기 → 부팅 후 자동으로 시작

## 직접 빌드

```bash
cd DdayApp
swift build -c release
```
