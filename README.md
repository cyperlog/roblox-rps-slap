# 가위바위보 뺨때리기 게임

## Roblox Studio에 넣는 방법

### 1단계: 새 프로젝트 (이미 했으면 스킵)
- Roblox Studio → Baseplate 템플릿

### 2단계: NPC 더미 배치 (이미 했으면 스킵)
- Toolbox → "R15 Dummy" 검색 → 삽입
- 이름을 "NPC"로 변경
- 스폰 위치 앞에 배치 (거리 5~8 정도)

### 3단계: RemoteEvent 만들기
- ReplicatedStorage 우클릭 → 개체 삽입 → RemoteEvent 3개:
  - "RPSChoice"
  - "RPSResult"  
  - "ChangeNPC"

### 4단계: 스크립트 교체
기존 스크립트 내용을 전부 지우고 새 내용으로 교체!

1. ServerScriptService > Script → `RPSServer.luau` 붙여넣기
2. StarterGui > ScreenGui > LocalScript 1 → `RPSGui.luau` 붙여넣기
3. StarterGui > ScreenGui > LocalScript 2 → `RPSClient.luau` 붙여넣기

### 5단계: 테스트
- Play 버튼!
- 캐릭터 선택 화면이 먼저 뜸
- 상대 고르고 "대결 시작!" 누르면 옆에서 카메라 비춤
