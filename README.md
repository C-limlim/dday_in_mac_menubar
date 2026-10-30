# D-Day 메뉴바

macOS 메뉴바에 D-Day 카운트다운을 표시하는 앱입니다.

> 🤖 100% AI Generated

## 설치

**1. 터미널(Terminal) 앱을 열어주세요.**  
Spotlight(`⌘ + Space`) → `Terminal` 검색

**2. 아래 명령어를 붙여넣고 실행하세요.**

```zsh
git clone https://github.com/C-limlim/dday_in_mac_manubar.git && cd dday_in_mac_manubar && ./install.sh
```

> **주의**: 반드시 Terminal(zsh)에서 실행해야 합니다. macOS 보안 권한 요청이 뜨면 허용을 눌러주세요.  
> **필요 환경**: macOS 13 (Ventura) 이상

## 사용법

1. 메뉴바의 D-Day 또는 달력 아이콘 → **D-Day 관리...** 클릭
2. **추가**로 이름과 날짜 입력. 변경사항은 자동 저장됩니다.
3. 체크박스로 메뉴바 표시 여부를 선택하고, 각 행의 **☰**를 드래그해 순서를 바꿉니다.
4. **전체 표시** 또는 **하나씩 표시**를 선택합니다. 하나씩 표시할 때는 전환 간격을 **0.5~60초** 범위에서 소수점으로 입력할 수 있습니다.
5. 로그인 시 자동 실행은 첫 설치 때 자동으로 켜지며 메뉴에서 변경할 수 있습니다.

## 개발 검증

Xcode 전체 설치 없이 Command Line Tools로 모델 및 드래그 종료 처리 회귀 검사를 실행할 수 있습니다.
테스트는 별도 임시 설정 저장소를 사용하므로 실제 D-Day 목록을 변경하지 않습니다.

```zsh
bash ./test.sh
swift build --package-path DdayApp -c release
```

## 제거

```zsh
rm -rf ~/Applications/DdayMenuBar.app
```
