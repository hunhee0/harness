# HTML 프레젠테이션 템플릿

슬라이드 프레젠테이션 생성 레퍼런스 아키텍처. 모든 프레젠테이션은 이 구조 따름.

## 베이스 HTML 구조

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Presentation Title</title>

    <!-- 폰트: Fontshare 또는 Google Fonts 사용 — 시스템 폰트 금지 -->
    <link rel="stylesheet" href="https://api.fontshare.com/v2/css?f[]=..." />

    <style>
      /* ===========================================
           CSS CUSTOM PROPERTIES (THEME)
           이를 변경하면 전체 외관 변경
           =========================================== */
      :root {
        /* 색상 — 선택한 스타일 preset에서 */
        --bg-primary: #0a0f1c;
        --bg-secondary: #111827;
        --text-primary: #ffffff;
        --text-secondary: #9ca3af;
        --accent: #00ffcc;
        --accent-glow: rgba(0, 255, 204, 0.3);

        /* 타이포그래피 — 반드시 clamp() 사용 */
        --font-display: "Clash Display", sans-serif;
        --font-body: "Satoshi", sans-serif;
        --title-size: clamp(2rem, 6vw, 5rem);
        --subtitle-size: clamp(0.875rem, 2vw, 1.25rem);
        --body-size: clamp(0.75rem, 1.2vw, 1rem);

        /* 간격 — 반드시 clamp() 사용 */
        --slide-padding: clamp(1.5rem, 4vw, 4rem);
        --content-gap: clamp(1rem, 2vw, 2rem);

        /* 애니메이션 */
        --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
        --duration-normal: 0.6s;
      }

      /* ===========================================
           BASE STYLES
           =========================================== */
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }

      /* --- 여기에 viewport-base.css 내용 붙여넣기 --- */

      /* ===========================================
           ANIMATIONS
           스크롤 시 JS가 추가하는 .visible 클래스로 트리거
           =========================================== */
      .reveal {
        opacity: 0;
        transform: translateY(30px);
        transition:
          opacity var(--duration-normal) var(--ease-out-expo),
          transform var(--duration-normal) var(--ease-out-expo);
      }

      .slide.visible .reveal {
        opacity: 1;
        transform: translateY(0);
      }

      /* 순차 reveal 위해 자식 stagger */
      .reveal:nth-child(1) {
        transition-delay: 0.1s;
      }
      .reveal:nth-child(2) {
        transition-delay: 0.2s;
      }
      .reveal:nth-child(3) {
        transition-delay: 0.3s;
      }
      .reveal:nth-child(4) {
        transition-delay: 0.4s;
      }

      /* ... preset 특화 스타일 ... */
    </style>
  </head>
  <body>
    <!-- 선택: 진행 바 -->
    <div class="progress-bar"></div>

    <!-- 선택: 네비게이션 도트 -->
    <nav class="nav-dots"><!-- JS가 생성 --></nav>

    <!-- 슬라이드 -->
    <section class="slide title-slide">
      <h1 class="reveal">Presentation Title</h1>
      <p class="reveal">Subtitle or author</p>
    </section>

    <section class="slide">
      <div class="slide-content">
        <h2 class="reveal">Slide Title</h2>
        <p class="reveal">Content...</p>
      </div>
    </section>

    <!-- 더 많은 슬라이드... -->

    <script>
      /* ===========================================
           SLIDE PRESENTATION CONTROLLER
           =========================================== */
      class SlidePresentation {
        constructor() {
          this.slides = document.querySelectorAll(".slide");
          this.currentSlide = 0;
          this.setupIntersectionObserver();
          this.setupKeyboardNav();
          this.setupTouchNav();
          this.setupProgressBar();
          this.setupNavDots();
        }

        setupIntersectionObserver() {
          // 슬라이드가 viewport 진입 시 .visible 클래스 추가
          // CSS 애니메이션을 효율적으로 트리거
        }

        setupKeyboardNav() {
          // 방향키·Space·Page Up/Down
        }

        setupTouchNav() {
          // 모바일용 터치/스와이프 지원
        }

        setupProgressBar() {
          // 스크롤 시 진행 바 업데이트
        }

        setupNavDots() {
          // 중요: 빌드 전 항상 clear — 도트가 렌더된 동안 outerHTML이
          // 캡처되었다면 재오픈 시 기존 위에 중복 셋이 추가됨.
          this.navDotsContainer.innerHTML = "";
          // 네비게이션 도트 생성·관리
        }
      }

      new SlidePresentation();
    </script>
  </body>
</html>
```

## 필수 JavaScript 기능

모든 프레젠테이션 포함 필수:

1. **SlidePresentation Class** — 메인 컨트롤러:
   - 키보드 네비게이션 (방향키·space·page up/down)
   - 터치/스와이프 지원
   - 마우스 휠 네비게이션
   - 진행 바 업데이트
   - 네비게이션 도트

2. **Intersection Observer** — 스크롤 트리거 애니메이션용:
   - 슬라이드가 viewport 진입 시 `.visible` 클래스 추가
   - CSS 전환을 효율적으로 트리거

3. **선택 향상** (선택한 스타일에 매칭):
   - trail 있는 커스텀 커서
   - 파티클 시스템 배경 (canvas)
   - parallax 효과
   - hover 시 3D tilt
   - 자석 버튼
   - 카운터 애니메이션

4. **인라인 편집** (사용자가 Phase 1에서 opt-in한 경우만 — No 답변 시 완전 건너뜀):
   - 편집 토글 버튼 (기본 숨김, hover hotzone 또는 `E` 키로 reveal)
   - localStorage 자동 저장
   - export/save 파일 기능
   - 아래 "인라인 편집 구현" 섹션 참조

## 인라인 편집 구현 (opt-in만)

**사용자가 Phase 1에서 인라인 편집에 "No" 선택 시 편집 관련 HTML·CSS·JS 어떤 것도 생성 금지.**

**hover 기반 show/hide에 CSS `~` sibling selector 사용 금지.** CSS-only 접근(`edit-hotzone:hover ~ .edit-toggle`)은 토글 버튼의 `pointer-events: none`이 hover 체인을 깨뜨려 실패: 사용자가 hotzone hover → 버튼 보임 → 마우스가 버튼 쪽 이동 → hotzone 떠남 → 클릭 전 버튼 사라짐.

**필수 접근: 400ms 지연 timeout 있는 JS 기반 hover.**

HTML:

```html
<div class="edit-hotzone"></div>
<button class="edit-toggle" id="editToggle" title="Edit mode (E)">Edit</button>
```

CSS (가시성은 JS 클래스로만 제어):

```css
/* 이를 위해 CSS ~ sibling selector 사용 금지!
   pointer-events: none이 hover 체인 깨뜨림.
   지연 timeout 있는 JS 사용 필수. */
.edit-hotzone {
  position: fixed;
  top: 0;
  left: 0;
  width: 80px;
  height: 80px;
  z-index: 10000;
  cursor: pointer;
}
.edit-toggle {
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.3s ease;
  z-index: 10001;
}
.edit-toggle.show,
.edit-toggle.active {
  opacity: 1;
  pointer-events: auto;
}
```

JS (세 가지 상호작용 방법):

```javascript
// 1. 토글 버튼의 클릭 핸들러
document.getElementById("editToggle").addEventListener("click", () => {
  editor.toggleEditMode();
});

// 2. 400ms 유예 기간이 있는 hotzone hover
const hotzone = document.querySelector(".edit-hotzone");
const editToggle = document.getElementById("editToggle");
let hideTimeout = null;

hotzone.addEventListener("mouseenter", () => {
  clearTimeout(hideTimeout);
  editToggle.classList.add("show");
});
hotzone.addEventListener("mouseleave", () => {
  hideTimeout = setTimeout(() => {
    if (!editor.isActive) editToggle.classList.remove("show");
  }, 400);
});
editToggle.addEventListener("mouseenter", () => {
  clearTimeout(hideTimeout);
});
editToggle.addEventListener("mouseleave", () => {
  hideTimeout = setTimeout(() => {
    if (!editor.isActive) editToggle.classList.remove("show");
  }, 400);
});

// 3. Hotzone 직접 클릭
hotzone.addEventListener("click", () => {
  editor.toggleEditMode();
});

// 4. 키보드 단축키 (E 키, 텍스트 편집 중일 때 건너뜀)
document.addEventListener("keydown", (e) => {
  if (
    (e.key === "e" || e.key === "E") &&
    !e.target.getAttribute("contenteditable")
  ) {
    editor.toggleEditMode();
  }
});
```

**중요: `exportFile()`은 outerHTML 캡처 전에 편집 상태를 제거해야 함.**

사용자가 편집 모드에서 Ctrl+S 누르면 `document.documentElement.outerHTML`이 라이브 DOM 캡처 —
`body.edit-active`·모든 텍스트 요소의 `contenteditable="true"`·토글 버튼과 배너의 `.active`/`.show` 클래스 포함.
저장된 파일을 여는 사람이 점선 outline·체크마크 버튼·편집 배너를 보게 됨. 마치 편집 모드에 영구히 갇힌 것처럼.

항상 `exportFile()`을 이렇게 구현:

```javascript
exportFile() {
    // 저장 파일이 깨끗이 열리도록 편집 상태 임시 제거
    const editableEls = Array.from(document.querySelectorAll('[contenteditable]'));
    editableEls.forEach(el => el.removeAttribute('contenteditable'));
    document.body.classList.remove('edit-active');

    // 토글 버튼·배너에서도 UI 클래스 제거
    const editToggle = document.getElementById('editToggle');
    const editBanner = document.querySelector('.edit-banner');
    editToggle?.classList.remove('active', 'show');
    editBanner?.classList.remove('active', 'show');

    const html = '<!DOCTYPE html>\n' + document.documentElement.outerHTML;

    // 사용자가 계속 편집 가능하도록 편집 상태 복원
    document.body.classList.add('edit-active');
    editableEls.forEach(el => el.setAttribute('contenteditable', 'true'));
    editToggle?.classList.add('active');
    editBanner?.classList.add('active');

    const blob = new Blob([html], { type: 'text/html' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'presentation.html';
    a.click();
    URL.revokeObjectURL(a.href);
}
```

## 이미지 파이프라인 (이미지 없으면 건너뜀)

사용자가 Phase 1에서 "이미지 없음" 선택 시 완전 건너뜀. 이미지 제공 시 HTML 생성 전에 처리.

**의존성:** `pip install Pillow`

### 이미지 처리

```python
from PIL import Image, ImageDraw

# 원형 crop (모던/깨끗한 스타일의 로고용)
def crop_circle(input_path, output_path):
    img = Image.open(input_path).convert('RGBA')
    w, h = img.size
    size = min(w, h)
    left, top = (w - size) // 2, (h - size) // 2
    img = img.crop((left, top, left + size, top + size))
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size, size], fill=255)
    img.putalpha(mask)
    img.save(output_path, 'PNG')

# 리사이즈 (HTML을 부풀리는 거대 이미지용)
def resize_max(input_path, output_path, max_dim=1200):
    img = Image.open(input_path)
    img.thumbnail((max_dim, max_dim), Image.LANCZOS)
    img.save(output_path, quality=85)
```

| Situation                        | Operation                     |
| -------------------------------- | ----------------------------- |
| 둥근 미학의 정사각 로고          | `crop_circle()`               |
| 이미지 > 1MB                     | `resize_max(max_dim=1200)`    |
| 잘못된 종횡비                    | `img.crop()`로 수동 crop      |

처리된 이미지를 `_processed` 접미사로 저장. 원본 덮어쓰기 절대 금지.

### 이미지 배치

**직접 파일 경로 사용** (base64 아님) — 프레젠테이션은 로컬에서 봄:

```html
<img src="assets/logo_round.png" alt="Logo" class="slide-image logo" />
<img
  src="assets/screenshot.png"
  alt="Screenshot"
  class="slide-image screenshot"
/>
```

```css
.slide-image {
  max-width: 100%;
  max-height: min(50vh, 400px);
  object-fit: contain;
  border-radius: 8px;
}
.slide-image.screenshot {
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}
.slide-image.logo {
  max-height: min(30vh, 200px);
}
```

**테두리·그림자 색상을 선택한 스타일의 액센트에 맞게 적응시킬 것.** 동일 이미지를 여러 슬라이드에 반복 금지 (타이틀·종료의 로고 제외).

**배치 패턴:** 타이틀 슬라이드 중앙에 로고. 텍스트와 함께 두 컬럼 레이아웃에 스크린샷. 텍스트 오버레이가 있는 슬라이드 배경으로 full-bleed 이미지 (절제 사용).

---

## 코드 품질

**주석:** 모든 섹션에 무엇을 하고 어떻게 수정하는지 설명하는 명확한 주석 필요.

**접근성:**

- 시맨틱 HTML (`<section>`·`<nav>`·`<main>`)
- 키보드 네비게이션 완전 동작
- 필요한 곳에 ARIA 라벨
- `prefers-reduced-motion` 지원 (viewport-base.css에 포함)

## 파일 구조

단일 프레젠테이션:

```
presentation.html    # 자체 포함, 모든 CSS/JS 인라인
assets/              # 이미지만, 있으면
```

한 프로젝트의 여러 프레젠테이션:

```
[name].html
[name]-assets/
```
