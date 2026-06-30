# D-Day 메뉴바

macOS 메뉴바에 D-Day 카운트다운을 표시하는 앱입니다.

<img width="300" alt="preview" src="https://github.com/user-attachments/assets/placeholder">

## 설치

터미널에 아래 두 줄만 붙여넣으세요.

```bash
git clone https://github.com/C-limlim/dday_in_mac_manubar.git
cd dday_in_mac_manubar && ./install.sh
```

> **필요 환경**: macOS 13 (Ventura) 이상  
> Xcode Command Line Tools가 없으면 설치 중 자동으로 안내됩니다.

## 사용법

1. 메뉴바 달력 아이콘 클릭
2. **설정...** → 이벤트 이름 + 날짜 입력 → 저장
3. 로그인 시 자동 실행은 첫 설치 때 자동으로 켜집니다

## 제거

```bash
rm -rf ~/Applications/DdayMenuBar.app
```
