---
name: ui-demo
description: Playwright로 폴리싱된 UI 데모 비디오 녹화. 사용자가 웹 애플리케이션의 데모·워크스루·스크린 녹화·튜토리얼 비디오 생성 요청 시 사용. 보이는 커서·자연스러운 페이싱·전문적 느낌의 WebM 비디오 생성 (Record polished UI demo videos using Playwright. Use when the user asks to create a demo, walkthrough, screen recording, or tutorial video of a web application. Produces WebM videos with visible cursor, natural pacing, and professional feel).
origin: ECC
---

# UI Demo 비디오 레코더

Playwright 비디오 녹화 + injected 커서 오버레이 + 자연스러운 페이싱 + 스토리텔링 흐름으로 폴리싱된 웹 애플리케이션 데모 비디오 녹화.

## 사용 시점

- 사용자가 "데모 비디오"·"스크린 녹화"·"워크스루"·"튜토리얼" 요청
- 사용자가 기능·워크플로를 시각적으로 보여주고 싶음
- 사용자가 문서·온보딩·이해관계자 발표용 비디오 필요

## 3-Phase 프로세스

모든 데모는 세 phase 거침: **Discover -> Rehearse -> Record**. 녹화로 바로 가지 말 것.

---

## Phase 1: Discover

스크립트 작성 전, 타겟 페이지를 탐색해 실제 무엇이 있는지 파악.

### 왜

본 적 없는 것을 스크립트로 만들 수 없음. 필드가 `<textarea>`가 아닌 `<input>`, 드롭다운이 `<select>`가 아닌 커스텀 컴포넌트, 댓글 박스가 `@mentions`·`#tags` 지원할 수 있음. 가정은 녹화를 조용히 깨뜨림.

### 어떻게

흐름의 각 페이지로 이동해 인터랙티브 요소 덤프:

```javascript
// 데모 스크립트 작성 전, 흐름의 각 페이지에 대해 이것 실행
const fields = await page.evaluate(() => {
  const els = [];
  document.querySelectorAll('input, select, textarea, button, [contenteditable]').forEach(el => {
    if (el.offsetParent !== null) {
      els.push({
        tag: el.tagName,
        type: el.type || '',
        name: el.name || '',
        placeholder: el.placeholder || '',
        text: el.textContent?.trim().substring(0, 40) || '',
        contentEditable: el.contentEditable === 'true',
        role: el.getAttribute('role') || '',
      });
    }
  });
  return els;
});
console.log(JSON.stringify(fields, null, 2));
```

### 무엇을 살필 것인가

- **폼 필드**: `<select>`·`<input>`·커스텀 드롭다운·콤보박스인가?
- **Select 옵션**: 옵션 값 AND 텍스트 덤프. 플레이스홀더는 종종 `value="0"` 또는 `value=""`로 비어보이지 않음. `Array.from(el.options).map(o => ({ value: o.value, text: o.text }))` 사용. 텍스트에 "Select"가 포함되거나 값이 `"0"`인 옵션은 건너뜀.
- **Rich text**: 댓글 박스가 `@mentions`·`#tags`·마크다운·이모지 지원? 플레이스홀더 텍스트 확인.
- **필수 필드**: 어느 필드가 폼 제출을 막는지? `required`, 라벨의 `*` 확인. 빈 채로 제출해 검증 에러 확인.
- **동적 컨텐츠**: 다른 필드 채워진 후 필드 출현?
- **버튼 라벨**: `"Submit"`·`"Submit Request"`·`"Send"` 같은 정확한 텍스트.
- **테이블 컬럼 헤더**: 테이블 기반 모달의 경우, 각 `input[type="number"]`를 컬럼 헤더에 매핑 (모든 숫자 input이 같은 의미라 가정 X).

### 출력

각 페이지의 필드 맵. 스크립트의 올바른 selector 작성에 사용. 예:

```text
/purchase-requests/new:
  - Budget Code: <select> (페이지 첫 select, 4 옵션)
  - Desired Delivery: <input type="date">
  - Context: <textarea> (input 아님)
  - BOM 테이블: 인라인 편집 셀 span.cursor-pointer -> input 패턴
  - Submit: <button> text="Submit"

/purchase-requests/N (상세):
  - Comment: <input placeholder="Type a message..."> @user와 #PR 태그 지원
  - Send: <button> text="Send" (입력에 컨텐츠 있을 때까지 비활성)
```

---

## Phase 2: Rehearse

녹화 없이 모든 단계 실행. 모든 selector 해결 검증.

### 왜

조용한 selector 실패가 데모 녹화 깨짐의 주된 원인. 리허설로 녹화 낭비 전 잡음.

### 어떻게

`ensureVisible` wrapper 사용. 로깅하고 소리 내 실패:

```javascript
async function ensureVisible(page, locator, label) {
  const el = typeof locator === 'string' ? page.locator(locator).first() : locator;
  const visible = await el.isVisible().catch(() => false);
  if (!visible) {
    const msg = `REHEARSAL FAIL: "${label}" not found - selector: ${typeof locator === 'string' ? locator : '(locator object)'}`;
    console.error(msg);
    const found = await page.evaluate(() => {
      return Array.from(document.querySelectorAll('button, input, select, textarea, a'))
        .filter(el => el.offsetParent !== null)
        .map(el => `${el.tagName}[${el.type || ''}] "${el.textContent?.trim().substring(0, 30)}"`)
        .join('\n  ');
    });
    console.error('  Visible elements:\n  ' + found);
    return false;
  }
  console.log(`REHEARSAL OK: "${label}"`);
  return true;
}
```

### 리허설 스크립트 구조

```javascript
const steps = [
  { label: 'Login email field', selector: '#email' },
  { label: 'Login submit', selector: 'button[type="submit"]' },
  { label: 'New Request button', selector: 'button:has-text("New Request")' },
  { label: 'Budget Code select', selector: 'select' },
  { label: 'Delivery date', selector: 'input[type="date"]:visible' },
  { label: 'Description field', selector: 'textarea:visible' },
  { label: 'Add Item button', selector: 'button:has-text("Add Item")' },
  { label: 'Submit button', selector: 'button:has-text("Submit")' },
];

let allOk = true;
for (const step of steps) {
  if (!await ensureVisible(page, step.selector, step.label)) {
    allOk = false;
  }
}
if (!allOk) {
  console.error('REHEARSAL FAILED - fix selectors before recording');
  process.exit(1);
}
console.log('REHEARSAL PASSED - all selectors verified');
```

### 리허설 실패 시

1. 보이는 요소 덤프 읽기.
2. 올바른 selector 찾기.
3. 스크립트 업데이트.
4. 리허설 재실행.
5. 모든 selector 통과 시에만 진행.

---

## Phase 3: Record

discovery·rehearsal 통과 후에만 녹화 생성.

### 녹화 원칙

#### 1. 스토리텔링 흐름

비디오를 스토리로 계획. 사용자 지정 순서를 따르거나 기본:

- **진입**: 시작점에 로그인·이동
- **컨텍스트**: 주변을 pan해 보는 사람이 orient
- **액션**: 메인 워크플로 단계 수행
- **변형**: 설정·테마·로컬라이제이션 같은 보조 기능 표시
- **결과**: 결과·확인·새 상태 표시

#### 2. 페이싱

- 로그인 후: `4s`
- 네비게이션 후: `3s`
- 버튼 클릭 후: `2s`
- 주요 단계 사이: `1.5-2s`
- 최종 액션 후: `3s`
- 타이핑 지연: 문자당 `25-40ms`

#### 3. 커서 오버레이

마우스 이동을 따라가는 SVG 화살표 커서 inject:

```javascript
async function injectCursor(page) {
  await page.evaluate(() => {
    if (document.getElementById('demo-cursor')) return;
    const cursor = document.createElement('div');
    cursor.id = 'demo-cursor';
    cursor.innerHTML = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M5 3L19 12L12 13L9 20L5 3Z" fill="white" stroke="black" stroke-width="1.5" stroke-linejoin="round"/>
    </svg>`;
    cursor.style.cssText = `
      position: fixed; z-index: 999999; pointer-events: none;
      width: 24px; height: 24px;
      transition: left 0.1s, top 0.1s;
      filter: drop-shadow(1px 1px 2px rgba(0,0,0,0.3));
    `;
    cursor.style.left = '0px';
    cursor.style.top = '0px';
    document.body.appendChild(cursor);
    document.addEventListener('mousemove', (e) => {
      cursor.style.left = e.clientX + 'px';
      cursor.style.top = e.clientY + 'px';
    });
  });
}
```

오버레이는 navigate 시 파괴되므로 매 페이지 이동 후 `injectCursor(page)` 호출.

#### 4. 마우스 이동

커서를 텔레포트하지 말 것. 클릭 전 타겟으로 이동:

```javascript
async function moveAndClick(page, locator, label, opts = {}) {
  const { postClickDelay = 800, ...clickOpts } = opts;
  const el = typeof locator === 'string' ? page.locator(locator).first() : locator;
  const visible = await el.isVisible().catch(() => false);
  if (!visible) {
    console.error(`WARNING: moveAndClick skipped - "${label}" not visible`);
    return false;
  }
  try {
    await el.scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);
    const box = await el.boundingBox();
    if (box) {
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, { steps: 10 });
      await page.waitForTimeout(400);
    }
    await el.click(clickOpts);
  } catch (e) {
    console.error(`WARNING: moveAndClick failed on "${label}": ${e.message}`);
    return false;
  }
  await page.waitForTimeout(postClickDelay);
  return true;
}
```

모든 호출에 디버깅용 서술적 `label` 포함.

#### 5. 타이핑

즉시 채우기 아닌 보이게 타이핑:

```javascript
async function typeSlowly(page, locator, text, label, charDelay = 35) {
  const el = typeof locator === 'string' ? page.locator(locator).first() : locator;
  const visible = await el.isVisible().catch(() => false);
  if (!visible) {
    console.error(`WARNING: typeSlowly skipped - "${label}" not visible`);
    return false;
  }
  await moveAndClick(page, el, label);
  await el.fill('');
  await el.pressSequentially(text, { delay: charDelay });
  await page.waitForTimeout(500);
  return true;
}
```

#### 6. 스크롤링

점프 대신 매끄러운 스크롤 사용:

```javascript
await page.evaluate(() => window.scrollTo({ top: 400, behavior: 'smooth' }));
await page.waitForTimeout(1500);
```

#### 7. 대시보드 패닝

대시보드·개요 페이지 표시 시 커서를 핵심 요소들 가로질러 이동:

```javascript
async function panElements(page, selector, maxCount = 6) {
  const elements = await page.locator(selector).all();
  for (let i = 0; i < Math.min(elements.length, maxCount); i++) {
    try {
      const box = await elements[i].boundingBox();
      if (box && box.y < 700) {
        await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, { steps: 8 });
        await page.waitForTimeout(600);
      }
    } catch (e) {
      console.warn(`WARNING: panElements skipped element ${i} (selector: "${selector}"): ${e.message}`);
    }
  }
}
```

#### 8. 자막

viewport 하단에 자막 바 inject:

```javascript
async function injectSubtitleBar(page) {
  await page.evaluate(() => {
    if (document.getElementById('demo-subtitle')) return;
    const bar = document.createElement('div');
    bar.id = 'demo-subtitle';
    bar.style.cssText = `
      position: fixed; bottom: 0; left: 0; right: 0; z-index: 999998;
      text-align: center; padding: 12px 24px;
      background: rgba(0, 0, 0, 0.75);
      color: white; font-family: -apple-system, "Segoe UI", sans-serif;
      font-size: 16px; font-weight: 500; letter-spacing: 0.3px;
      transition: opacity 0.3s;
      pointer-events: none;
    `;
    bar.textContent = '';
    bar.style.opacity = '0';
    document.body.appendChild(bar);
  });
}

async function showSubtitle(page, text) {
  await page.evaluate((t) => {
    const bar = document.getElementById('demo-subtitle');
    if (!bar) return;
    if (t) {
      bar.textContent = t;
      bar.style.opacity = '1';
    } else {
      bar.style.opacity = '0';
    }
  }, text);
  if (text) await page.waitForTimeout(800);
}
```

매 네비게이션 후 `injectCursor(page)`와 함께 `injectSubtitleBar(page)` 호출.

사용 패턴:

```javascript
await showSubtitle(page, 'Step 1 - Logging in');
await showSubtitle(page, 'Step 2 - Dashboard overview');
await showSubtitle(page, '');
```

가이드라인:

- 자막 텍스트 짧게, 이상적으로 60자 미만.
- 일관성 위해 `Step N - Action` 형식 사용.
- UI가 스스로 말할 수 있는 긴 일시정지에는 자막 클리어.

## 스크립트 템플릿

```javascript
'use strict';
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE_URL = process.env.QA_BASE_URL || 'http://localhost:3000';
const VIDEO_DIR = path.join(__dirname, 'screenshots');
const OUTPUT_NAME = 'demo-FEATURE.webm';
const REHEARSAL = process.argv.includes('--rehearse');

// 여기에 injectCursor, injectSubtitleBar, showSubtitle, moveAndClick,
// typeSlowly, ensureVisible, panElements 붙여넣기.

(async () => {
  const browser = await chromium.launch({ headless: true });

  if (REHEARSAL) {
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    const page = await context.newPage();
    // 흐름을 따라 이동하며 각 selector에 ensureVisible 실행.
    await browser.close();
    return;
  }

  const context = await browser.newContext({
    recordVideo: { dir: VIDEO_DIR, size: { width: 1280, height: 720 } },
    viewport: { width: 1280, height: 720 }
  });
  const page = await context.newPage();

  try {
    await injectCursor(page);
    await injectSubtitleBar(page);

    await showSubtitle(page, 'Step 1 - Logging in');
    // 로그인 액션

    await page.goto(`${BASE_URL}/dashboard`);
    await injectCursor(page);
    await injectSubtitleBar(page);
    await showSubtitle(page, 'Step 2 - Dashboard overview');
    // 대시보드 pan

    await showSubtitle(page, 'Step 3 - Main workflow');
    // 액션 시퀀스

    await showSubtitle(page, 'Step 4 - Result');
    // 최종 reveal
    await showSubtitle(page, '');
  } catch (err) {
    console.error('DEMO ERROR:', err.message);
  } finally {
    await context.close();
    const video = page.video();
    if (video) {
      const src = await video.path();
      const dest = path.join(VIDEO_DIR, OUTPUT_NAME);
      try {
        fs.copyFileSync(src, dest);
        console.log('Video saved:', dest);
      } catch (e) {
        console.error('ERROR: Failed to copy video:', e.message);
        console.error('  Source:', src);
        console.error('  Destination:', dest);
      }
    }
    await browser.close();
  }
})();
```

사용:

```bash
# Phase 2: 리허설
node demo-script.cjs --rehearse

# Phase 3: 녹화
node demo-script.cjs
```

## 녹화 전 체크리스트

- [ ] Discovery phase 완료
- [ ] 모든 selector OK로 리허설 통과
- [ ] Headless 모드 활성
- [ ] 해상도 `1280x720` 설정
- [ ] 매 네비게이션 후 커서·자막 오버레이 재 inject
- [ ] 주요 전환에 `showSubtitle(page, 'Step N - ...')` 사용
- [ ] 모든 클릭에 서술적 라벨로 `moveAndClick` 사용
- [ ] 보이는 입력에 `typeSlowly` 사용
- [ ] 조용한 catch 없음. 헬퍼가 경고 로깅
- [ ] 컨텐츠 reveal에 매끄러운 스크롤 사용
- [ ] 핵심 일시정지가 사람 시청자에게 보임
- [ ] 흐름이 요청한 스토리 순서와 일치
- [ ] 스크립트가 phase 1에서 발견한 실제 UI 반영

## 일반적 함정

1. 네비게이션 후 커서 사라짐 - 재 inject.
2. 비디오 너무 빠름 - 일시정지 추가.
3. 화살표 대신 점 커서 - SVG 오버레이 사용.
4. 커서 텔레포트 - 클릭 전 이동.
5. Select 드롭다운이 잘못 보임 - 이동 표시 후 옵션 선택.
6. 모달이 갑작스러움 - 확인 전 읽는 일시정지 추가.
7. 비디오 파일 경로 무작위 - 안정 출력명으로 복사.
8. Selector 실패 삼킴 - 조용한 catch 블록 절대 사용 금지.
9. 필드 타입 가정 - 먼저 발견.
10. 기능 가정 - 스크립트 전 실제 UI 검사.
11. 플레이스홀더 select 값이 진짜처럼 보임 - `"0"`과 `"Select..."` 주의.
12. 팝업이 별도 비디오 생성 - 팝업 페이지를 명시적으로 캡처하고 필요 시 나중에 병합.
