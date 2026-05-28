# 스타일 Preset 레퍼런스

`frontend-slides`용 큐레이팅된 시각 스타일.

이 파일 사용처:
- 필수 viewport-fitting CSS 베이스
- preset 선택·분위기 매핑
- CSS gotcha·검증 규칙

추상 모양만. 사용자가 명시적으로 요청하지 않는 한 일러스트레이션 회피.

## Viewport Fit은 협상 불가

모든 슬라이드는 viewport 하나에 완전히 fit해야 함.

### 황금 규칙

```text
각 슬라이드 = 정확히 viewport 높이 하나.
컨텐츠 너무 많음 = 더 많은 슬라이드로 분할.
슬라이드 내부에서 절대 스크롤 금지.
```

### Density 한계

| Slide Type | Maximum Content |
|------------|-----------------|
| Title slide | 헤딩 1 + 부제 1 + 선택 태그라인 |
| Content slide | 헤딩 1 + bullet 4-6 또는 단락 2 |
| Feature grid | 최대 카드 6 |
| Code slide | 최대 8-10 라인 |
| Quote slide | quote 1 + attribution |
| Image slide | 이미지 1, 이상적으로 60vh 미만 |

## 필수 베이스 CSS

이 블록을 생성된 모든 프레젠테이션에 복사한 후 위에 테마 적용.

```css
/* ===========================================
   VIEWPORT FITTING: MANDATORY BASE STYLES
   =========================================== */

html, body {
    height: 100%;
    overflow-x: hidden;
}

html {
    scroll-snap-type: y mandatory;
    scroll-behavior: smooth;
}

.slide {
    width: 100vw;
    height: 100vh;
    height: 100dvh;
    overflow: hidden;
    scroll-snap-align: start;
    display: flex;
    flex-direction: column;
    position: relative;
}

.slide-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
    max-height: 100%;
    overflow: hidden;
    padding: var(--slide-padding);
}

:root {
    --title-size: clamp(1.5rem, 5vw, 4rem);
    --h2-size: clamp(1.25rem, 3.5vw, 2.5rem);
    --h3-size: clamp(1rem, 2.5vw, 1.75rem);
    --body-size: clamp(0.75rem, 1.5vw, 1.125rem);
    --small-size: clamp(0.65rem, 1vw, 0.875rem);

    --slide-padding: clamp(1rem, 4vw, 4rem);
    --content-gap: clamp(0.5rem, 2vw, 2rem);
    --element-gap: clamp(0.25rem, 1vw, 1rem);
}

.card, .container, .content-box {
    max-width: min(90vw, 1000px);
    max-height: min(80vh, 700px);
}

.feature-list, .bullet-list {
    gap: clamp(0.4rem, 1vh, 1rem);
}

.feature-list li, .bullet-list li {
    font-size: var(--body-size);
    line-height: 1.4;
}

.grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(min(100%, 250px), 1fr));
    gap: clamp(0.5rem, 1.5vw, 1rem);
}

img, .image-container {
    max-width: 100%;
    max-height: min(50vh, 400px);
    object-fit: contain;
}

@media (max-height: 700px) {
    :root {
        --slide-padding: clamp(0.75rem, 3vw, 2rem);
        --content-gap: clamp(0.4rem, 1.5vw, 1rem);
        --title-size: clamp(1.25rem, 4.5vw, 2.5rem);
        --h2-size: clamp(1rem, 3vw, 1.75rem);
    }
}

@media (max-height: 600px) {
    :root {
        --slide-padding: clamp(0.5rem, 2.5vw, 1.5rem);
        --content-gap: clamp(0.3rem, 1vw, 0.75rem);
        --title-size: clamp(1.1rem, 4vw, 2rem);
        --body-size: clamp(0.7rem, 1.2vw, 0.95rem);
    }

    .nav-dots, .keyboard-hint, .decorative {
        display: none;
    }
}

@media (max-height: 500px) {
    :root {
        --slide-padding: clamp(0.4rem, 2vw, 1rem);
        --title-size: clamp(1rem, 3.5vw, 1.5rem);
        --h2-size: clamp(0.9rem, 2.5vw, 1.25rem);
        --body-size: clamp(0.65rem, 1vw, 0.85rem);
    }
}

@media (max-width: 600px) {
    :root {
        --title-size: clamp(1.25rem, 7vw, 2.5rem);
    }

    .grid {
        grid-template-columns: 1fr;
    }
}

@media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
        animation-duration: 0.01ms !important;
        transition-duration: 0.2s !important;
    }

    html {
        scroll-behavior: auto;
    }
}
```

## Viewport 체크리스트

- 모든 `.slide`가 `height: 100vh`·`height: 100dvh`·`overflow: hidden` 가짐
- 모든 타이포그래피가 `clamp()` 사용
- 모든 간격이 `clamp()` 또는 viewport 단위 사용
- 이미지에 `max-height` 제약 있음
- 그리드가 `auto-fit` + `minmax()`로 적응
- `700px`·`600px`·`500px`에 short-height 브레이크포인트 존재
- 무엇이든 비좁게 느껴지면 슬라이드 분할

## 분위기→Preset 매핑

| Mood | Good Presets |
|------|--------------|
| Impressed / Confident | Bold Signal·Electric Studio·Dark Botanical |
| Excited / Energized | Creative Voltage·Neon Cyber·Split Pastel |
| Calm / Focused | Notebook Tabs·Paper & Ink·Swiss Modern |
| Inspired / Moved | Dark Botanical·Vintage Editorial·Pastel Geometry |

## Preset 카탈로그

### 1. Bold Signal

- Vibe: confident·high-impact·keynote-ready
- Best for: 피치 deck·런치·성명
- Fonts: Archivo Black + Space Grotesk
- Palette: charcoal base·hot orange focal card·crisp white text
- Signature: 거대 섹션 번호·다크 필드의 high-contrast 카드

### 2. Electric Studio

- Vibe: clean·bold·agency-polished
- Best for: 클라이언트 프레젠테이션·전략 리뷰
- Fonts: Manrope만
- Palette: black·white·saturated cobalt accent
- Signature: 두 패널 분할·날카로운 편집적 정렬

### 3. Creative Voltage

- Vibe: energetic·retro-modern·playful confidence
- Best for: 크리에이티브 스튜디오·브랜드 작업·제품 스토리텔링
- Fonts: Syne + Space Mono
- Palette: electric blue·neon yellow·deep navy
- Signature: halftone 텍스처·뱃지·강한 대비

### 4. Dark Botanical

- Vibe: elegant·premium·atmospheric
- Best for: 럭셔리 브랜드·사려 깊은 내러티브·프리미엄 제품 deck
- Fonts: Cormorant + IBM Plex Sans
- Palette: near-black·warm ivory·blush·gold·terracotta
- Signature: 블러 추상 원·미세 룰·절제된 모션

### 5. Notebook Tabs

- Vibe: editorial·organized·tactile
- Best for: 리포트·리뷰·구조화된 스토리텔링
- Fonts: Bodoni Moda + DM Sans
- Palette: charcoal 위 cream paper와 pastel 탭
- Signature: 종이 시트·컬러 사이드 탭·바인더 디테일

### 6. Pastel Geometry

- Vibe: approachable·modern·friendly
- Best for: 제품 개요·온보딩·가벼운 브랜드 deck
- Fonts: Plus Jakarta Sans만
- Palette: pale blue field·cream card·soft pink/mint/lavender accent
- Signature: 수직 pill·둥근 카드·부드러운 그림자

### 7. Split Pastel

- Vibe: playful·modern·creative
- Best for: 에이전시 인트로·워크숍·포트폴리오
- Fonts: Outfit만
- Palette: mint badge가 있는 peach + lavender 분할
- Signature: 분할 배경·둥근 태그·라이트 그리드 오버레이

### 8. Vintage Editorial

- Vibe: witty·personality-driven·magazine-inspired
- Best for: 개인 브랜드·의견 있는 강연·스토리텔링
- Fonts: Fraunces + Work Sans
- Palette: cream·charcoal·dusty warm accent
- Signature: 기하학 액센트·테두리 callout·강한 serif 헤드라인

### 9. Neon Cyber

- Vibe: futuristic·techy·kinetic
- Best for: AI·infra·dev 도구·future-of-X 강연
- Fonts: Clash Display + Satoshi
- Palette: midnight navy·cyan·magenta
- Signature: glow·파티클·그리드·data-radar 에너지

### 10. Terminal Green

- Vibe: developer-focused·hacker-clean
- Best for: API·CLI 도구·엔지니어링 데모
- Fonts: JetBrains Mono만
- Palette: GitHub dark + terminal green
- Signature: 스캔 라인·command-line 프레이밍·정확한 monospace 리듬

### 11. Swiss Modern

- Vibe: minimal·precise·data-forward
- Best for: 기업·제품 전략·분석
- Fonts: Archivo + Nunito
- Palette: white·black·signal red
- Signature: 가시 그리드·비대칭·기하학 규율

### 12. Paper & Ink

- Vibe: literary·thoughtful·story-driven
- Best for: 에세이·키노트 내러티브·매니페스토 deck
- Fonts: Cormorant Garamond + Source Serif 4
- Palette: warm cream·charcoal·crimson accent
- Signature: pull quote·드롭 캡·우아한 룰

## 직접 선택 프롬프트

사용자가 원하는 스타일을 이미 알면 미리보기 생성 강요 대신 위 preset 이름에서 직접 선택하게 함.

## 애니메이션 느낌 매핑

| Feeling | Motion Direction |
|---------|------------------|
| Dramatic / Cinematic | 느린 fade·parallax·큰 scale-in |
| Techy / Futuristic | glow·파티클·그리드 모션·scramble 텍스트 |
| Playful / Friendly | 스프링 easing·둥근 모양·플로팅 모션 |
| Professional / Corporate | 미묘한 200-300ms 전환·깨끗한 슬라이드 |
| Calm / Minimal | 매우 절제된 움직임·whitespace-first |
| Editorial / Magazine | 강한 계층·교차된 텍스트와 이미지 상호작용 |

## CSS Gotcha: 함수 부정

이렇게 절대 작성 금지:

```css
right: -clamp(28px, 3.5vw, 44px);
margin-left: -min(10vw, 100px);
```

브라우저가 조용히 무시.

항상 이렇게 작성:

```css
right: calc(-1 * clamp(28px, 3.5vw, 44px));
margin-left: calc(-1 * min(10vw, 100px));
```

## 검증 크기

최소 테스트:
- Desktop: `1920x1080`·`1440x900`·`1280x720`
- Tablet: `1024x768`·`768x1024`
- Mobile: `375x667`·`414x896`
- Landscape phone: `667x375`·`896x414`

## 안티패턴

사용 금지:
- purple-on-white 스타트업 템플릿
- 사용자가 명시적으로 실용적 중립 원하지 않는 한 시각 보이스로 Inter / Roboto / Arial
- bullet 벽·작은 타입·스크롤 필요한 코드 블록
- 추상 기하학이 더 잘 할 수 있는 일에 장식 일러스트레이션
