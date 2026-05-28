---
name: frontend-slides
description: 처음부터 또는 PowerPoint 파일을 변환해 애니메이션 풍부한 멋진 HTML 프레젠테이션 생성. 사용자가 프레젠테이션 구축·PPT/PPTX를 웹으로 변환·강연·피치용 슬라이드 생성 요청 시 사용. 비디자이너가 추상 선택이 아닌 시각 탐색으로 자신의 미학을 발견하도록 도움 (Create stunning, animation-rich HTML presentations from scratch or by converting PowerPoint files. Use when the user wants to build a presentation, convert a PPT/PPTX to web, or create slides for a talk/pitch. Helps non-designers discover their aesthetic through visual exploration rather than abstract choices).
origin: ECC
---

# Frontend Slides

브라우저에서 완전히 실행되는 zero-dependency·애니메이션 풍부 HTML 프레젠테이션 생성.

zarazhangrui의 작업에서 보여진 시각 탐색 접근에서 영감 (credit: @zarazhangrui).

## 활성화 시점

- 강연 deck·피치 deck·워크숍 deck·내부 프레젠테이션 생성
- `.ppt` 또는 `.pptx` 슬라이드를 HTML 프레젠테이션으로 변환
- 기존 HTML 프레젠테이션의 레이아웃·모션·타이포그래피 개선
- 디자인 선호를 아직 모르는 사용자와 프레젠테이션 스타일 탐색

## 협상 불가 사항

1. **Zero dependency**: 인라인 CSS·JS의 자체 포함 HTML 파일 하나가 기본.
2. **viewport fit 필수**: 모든 슬라이드는 내부 스크롤 없이 viewport 하나에 fit.
3. **보여주기, 설명 X**: 추상 스타일 질문지 대신 시각 미리보기 사용.
4. **독창적 디자인**: generic한 purple-gradient·Inter-on-white·템플릿 느낌 deck 회피.
5. **프로덕션 품질**: 코드 주석·접근성·반응성·고성능 유지.

생성 전에 viewport 안전 CSS 베이스·density 한계·preset 카탈로그·CSS gotcha를 위해 `STYLE_PRESETS.md` 읽기.

## 워크플로

### 1. 모드 감지

한 경로 선택:
- **신규 프레젠테이션**: 사용자가 주제·노트·전체 초안 보유
- **PPT 변환**: 사용자가 `.ppt` 또는 `.pptx` 보유
- **개선**: 사용자가 이미 HTML 슬라이드 보유, 개선 원함

### 2. 컨텐츠 발견

필요한 최소만 질문:
- 목적: 피치·교육·컨퍼런스 강연·내부 업데이트
- 길이: 짧음(5-10)·중간(10-20)·김(20+)
- 컨텐츠 상태: 완성된 카피·rough 노트·주제만

사용자가 컨텐츠 보유 시 스타일링 전에 붙여넣기 요청.

### 3. 스타일 발견

기본은 시각 탐색.

사용자가 원하는 preset을 이미 알면 미리보기 건너뛰고 직접 사용.

그 외:
1. deck이 만들 느낌 질문: impressed·energized·focused·inspired.
2. `.ecc-design/slide-previews/`에 **단일 슬라이드 미리보기 파일 3개** 생성.
3. 각 미리보기는 자체 포함, 타이포그래피·색상·모션을 명확히 보여주고, 슬라이드 컨텐츠 대략 100라인 미만 유지.
4. 사용자에게 유지할 미리보기 또는 혼합할 요소 질문.

분위기→스타일 매핑은 `STYLE_PRESETS.md`의 preset 가이드 사용.

### 4. 프레젠테이션 구축

다음 중 하나 출력:
- `presentation.html`
- `[presentation-name].html`

`assets/` 폴더는 deck에 추출되거나 사용자 제공 이미지가 있을 때만 사용.

필수 구조:
- 시맨틱 슬라이드 섹션
- `STYLE_PRESETS.md`의 viewport 안전 CSS 베이스
- 테마 값을 위한 CSS custom property
- 키보드·휠·터치 네비게이션용 프레젠테이션 컨트롤러 클래스
- reveal 애니메이션용 Intersection Observer
- reduced-motion 지원

### 5. Viewport Fit 강제

하드 게이트로 취급.

규칙:
- 모든 `.slide`는 `height: 100vh; height: 100dvh; overflow: hidden;` 사용
- 모든 타입·간격은 `clamp()`로 스케일
- 컨텐츠가 fit 안 하면 여러 슬라이드로 분할
- 가독 가능 크기 미만으로 텍스트 축소해 overflow 해결 절대 금지
- 슬라이드 내 스크롤바 절대 허용 금지

`STYLE_PRESETS.md`의 density 한계·필수 CSS 블록 사용.

### 6. 검증

완성된 deck을 다음 크기에서 확인:
- 1920x1080
- 1280x720
- 768x1024
- 375x667
- 667x375

브라우저 자동화 사용 가능하면 슬라이드 overflow 없음과 키보드 네비게이션 동작 검증에 사용.

### 7. 전달

핸드오프 시:
- 사용자가 유지 원하지 않는 한 임시 미리보기 파일 삭제
- 유용할 때 플랫폼 적절한 오프너로 deck 열기
- 파일 경로·사용 preset·슬라이드 수·쉬운 테마 커스터마이징 포인트 요약

현재 OS의 올바른 오프너 사용:
- macOS: `open file.html`
- Linux: `xdg-open file.html`
- Windows: `start "" file.html`

## PPT / PPTX 변환

PowerPoint 변환:
1. 텍스트·이미지·노트 추출에 `python-pptx`가 있는 `python3` 선호.
2. `python-pptx` 사용 불가 시 설치 또는 manual/export 기반 워크플로 fallback 질문.
3. 슬라이드 순서·speaker note·추출 자산 보존.
4. 추출 후 신규 프레젠테이션과 동일한 스타일 선택 워크플로 실행.

변환은 cross-platform 유지. Python으로 가능한 작업에 macOS 전용 도구 의존 금지.

## 구현 요구사항

### HTML / CSS

- 사용자가 명시적으로 다중 파일 프로젝트 원하지 않는 한 인라인 CSS·JS 사용.
- 폰트는 Google Fonts 또는 Fontshare에서 올 수 있음.
- 분위기 있는 배경·강한 타입 계층·명확한 시각 방향 선호.
- 일러스트레이션보다 추상 모양·그라디언트·그리드·노이즈·기하학 사용.

### JavaScript

포함:
- 키보드 네비게이션
- 터치/스와이프 네비게이션
- 마우스 휠 네비게이션
- 진행 표시 또는 슬라이드 인덱스
- enter 시 reveal 애니메이션 트리거

### 접근성

- 시맨틱 구조 사용 (`main`·`section`·`nav`)
- 대비 가독성 유지
- 키보드 전용 네비게이션 지원
- `prefers-reduced-motion` 존중

## 컨텐츠 Density 한계

사용자가 명시적으로 더 빽빽한 슬라이드 요청하고 가독성 유지될 때 외에는 다음 최대값 사용:

| Slide type | Limit |
|------------|-------|
| Title | 헤딩 1 + 부제 1 + 선택 태그라인 |
| Content | 헤딩 1 + bullet 4-6 또는 짧은 단락 2 |
| Feature grid | 최대 카드 6 |
| Code | 최대 8-10 라인 |
| Quote | quote 1 + attribution |
| Image | viewport로 제한된 이미지 1 |

## 안티패턴

- 시각 정체성 없는 generic 스타트업 그라디언트
- 의도적으로 편집적이지 않은 한 시스템 폰트 deck
- 긴 bullet 벽
- 스크롤 필요한 코드 블록
- 짧은 화면에서 깨지는 고정 높이 컨텐츠 박스
- `-clamp(...)` 같은 잘못된 부정 CSS 함수

## 관련 ECC 스킬

- deck 주변 컴포넌트·상호작용 패턴에 `frontend-patterns`
- 프레젠테이션이 의도적으로 Apple 글래스 미학을 빌릴 때 `liquid-glass-design`
- 최종 deck에 자동 브라우저 검증 필요 시 `e2e-testing`

## 산출물 체크리스트

- 프레젠테이션이 브라우저의 로컬 파일에서 실행
- 모든 슬라이드가 스크롤 없이 viewport에 fit
- 스타일이 독창적이고 의도적
- 애니메이션이 의미 있고 노이즈 X
- reduced motion 존중
- 핸드오프 시 파일 경로·커스터마이징 포인트 설명
