# 셋아카이브 (Set-Archive)

> "정리하지 마세요, 그냥 던지세요. 나머지는 AI가 합니다."

## 빠른 시작

### 1. 의존성 설치

```bash
brew install xcodegen
brew install supabase/tap/supabase
```

### 2. Xcode 프로젝트 생성

```bash
cd ~/SetArchive
xcodegen generate
open SetArchive.xcodeproj
```

### 3. Supabase 로컬 개발 환경

```bash
supabase start
supabase functions serve classify --env-file .env.local
```

`.env.local` 파일 생성:
```
ANTHROPIC_API_KEY=sk-ant-...
```

### 4. AppConfig.swift 업데이트

Supabase 대시보드에서 URL과 anon key를 확인 후 `AppConfig.swift`에 입력하거나,
Xcode의 Scheme 환경변수로 설정:
```
SUPABASE_URL = https://xxxx.supabase.co
SUPABASE_ANON_KEY = eyJh...
```

### 5. Apple Developer 설정 (필수)

Xcode > Signing & Capabilities:
- App Group: `group.com.setarchive.shared` 추가
- iCloud: CloudKit 활성화 (optional)
- Background Modes: Background fetch, Background processing 활성화

---

## 프로젝트 구조

```
SetArchive/
├── App/               # 앱 진입점
├── Core/
│   ├── Models/        # SwiftData 모델 (Item, SACategory)
│   ├── Storage/       # SwiftDataStack
│   ├── AI/            # ClassificationClient (Supabase Edge Function 호출)
│   ├── Background/    # QueueProcessor (BGTaskScheduler)
│   └── Config/        # AppConfig
├── Features/
│   ├── Home/          # 홈 화면
│   ├── Category/      # 카테고리별 뷰 (GridLayout, ReadingCardLayout)
│   └── Detail/        # 아이템 상세
├── Shared/            # ShareExtension과 공유 (SharedQueue)
└── Resources/

ShareExtension/        # iOS Share Extension
supabase/
└── functions/classify/ # Claude API 프록시 (Deno/TypeScript)
```

## 데이터 흐름

```
외부 앱 공유
    ↓
ShareExtension (바텀시트, 원탭)
    ↓  SharedQueue에 저장 → 즉시 닫힘 (<1초)
메인 앱 활성화 또는 BGTask
    ↓
QueueProcessor
    ↓  Supabase Edge Function 호출
Claude Haiku (분류·요약)
    ↓  confidence > 0.7 → 카테고리, 미만 → 미분류함
SwiftData 저장
    ↓
UI 반영
```

## MVP 체크리스트

- [ ] Share Extension PoC (메모리 < 80MB, 응답 < 1초)
- [ ] AI 분류 정확도 85%+ (100개 테스트셋)
- [ ] 카테고리 뷰 2종 (그리드, 리딩카드)
- [ ] TestFlight 베타 10명
- [ ] App Store 심사 제출
