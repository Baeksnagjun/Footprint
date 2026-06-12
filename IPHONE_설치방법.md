# iPhone에 앱 설치하기

## 1. Xcode 서명 설정 (필수)

1. Xcode에서 `miniproject.xcodeproj` 열기
2. 왼쪽 **miniproject** 프로젝트 클릭 → **TARGETS → miniproject**
3. **Signing & Capabilities** 탭
4. **Team** → 본인 Apple ID 선택 (없으면 **Add Account…**로 로그인)
5. **Automatically manage signing** 체크

> Team이 비어 있으면 실기기에 **절대 설치되지 않습니다.**

## 2. iPhone 준비

1. USB로 맥에 연결
2. iPhone **「이 컴퓨터를 신뢰」** 허용
3. **설정 → 개인정보 보호 및 보안 → 개발자 모드** → 켜기 (iOS 16 이상)
4. iPhone 잠금 해제 상태 유지

## 3. Xcode에서 실행

1. 상단 기기 선택 메뉴에서 **본인 iPhone** 선택 (시뮬레이터 아님)
2. **Run (⌘R)**
3. 첫 설치 후 iPhone: **설정 → 일반 → VPN 및 기기 관리** → 개발자 앱 **신뢰**

## 4. 자주 나오는 오류

| 메시지 | 해결 |
|--------|------|
| Requires a development team | Signing에서 Team 선택 |
| Unable to install | iOS 버전 확인 (앱 최소 iOS 17) |
| Untrusted Developer | 기기 관리에서 개발자 신뢰 |
| Could not launch | 개발자 모드 켜기 |

## 5. 앱 실행 후

- 서버 주소: `http://맥WiFiIP:8000` (127.0.0.1 사용 금지)
- 맥 IP: 터미널 `ipconfig getifaddr en0`
