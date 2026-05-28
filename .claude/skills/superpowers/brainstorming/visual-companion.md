# 시각 동반자 가이드

mockup·다이어그램·옵션 표시용 브라우저 기반 시각 브레인스토밍 동반자.

## 사용 시점

세션별이 아닌 질문별로 결정. 테스트: **사용자가 읽기보다 보면 더 잘 이해할까?**

**브라우저 사용** 컨텐츠 자체가 시각인 경우:

- **UI mockup** — 와이어프레임·레이아웃·네비게이션 구조·컴포넌트 디자인
- **아키텍처 다이어그램** — 시스템 컴포넌트·데이터 흐름·관계 맵
- **Side-by-side 시각 비교** — 두 레이아웃·두 색 배합·두 디자인 방향 비교
- **디자인 폴리시** — 외관·간격·시각 계층 관련 질문 시
- **공간 관계** — 다이어그램으로 렌더된 상태 머신·플로차트·엔티티 관계

**터미널 사용** 컨텐츠가 텍스트·테이블인 경우:

- **요구사항·스코프 질문** — "X가 뭐지?"·"어느 기능이 스코프?"
- **개념 A/B/C 선택** — 단어로 기술된 접근 선택
- **트레이드오프 리스트** — 장단점·비교 테이블
- **기술 결정** — API 디자인·데이터 모델링·아키텍처 접근 선택
- **명확화 질문** — 답이 단어·시각 선호 아닌 모든 것

UI 주제 *관한* 질문이 자동으로 시각 질문 X. "어떤 종류의 wizard를 원해?"는 개념 — 터미널. "이 wizard 레이아웃 중 어느 것이 맞아 보여?"는 시각 — 브라우저.

## 동작 원리

서버가 HTML 파일 디렉터리 watch하고 가장 새것을 브라우저에 서빙. HTML 컨텐츠를 `screen_dir`에 작성, 사용자가 브라우저에서 보고 옵션 선택 클릭. 선택은 `state_dir/events`에 기록·다음 턴에 읽음.

**컨텐츠 fragment vs 전체 문서:** HTML 파일이 `<!DOCTYPE`·`<html`로 시작하면 서버가 그대로 서빙 (헬퍼 스크립트만 주입). 그 외 서버가 자동으로 컨텐츠를 프레임 템플릿에 wrap — 헤더·CSS 테마·선택 indicator·모든 인터랙티브 인프라 추가. **기본은 컨텐츠 fragment 작성.** 페이지 완전 제어 필요 시에만 전체 문서 작성.

## 세션 시작

```bash
# 영속성 있는 서버 시작 (mockup이 프로젝트에 저장)
scripts/start-server.sh --project-dir /path/to/project

# 반환: {"type":"server-started","port":52341,"url":"http://localhost:52341",
#        "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
#        "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
```

응답에서 `screen_dir`·`state_dir` 저장. 사용자에게 URL 오픈 알림.

**연결 정보 찾기:** 서버가 startup JSON을 `$STATE_DIR/server-info`에 작성. 백그라운드 시작·stdout 캡처 안 했으면 그 파일 읽어 URL·포트 획득. `--project-dir` 사용 시 `<project>/.superpowers/brainstorm/`에서 세션 디렉터리 체크.

**노트:** mockup이 `.superpowers/brainstorm/`에 영속·서버 재시작 후 생존하도록 프로젝트 루트를 `--project-dir`로 전달. 없으면 파일이 `/tmp` 가서 정리됨. 사용자에게 `.superpowers/`가 `.gitignore`에 없으면 추가 리마인드.

**플랫폼별 서버 실행:**

**Claude Code (macOS / Linux):**
```bash
# 기본 모드 동작 — 스크립트가 서버 자체 백그라운드
scripts/start-server.sh --project-dir /path/to/project
```

**Claude Code (Windows):**
```bash
# Windows 자동 감지·foreground 모드 사용. 이는 도구 호출 차단.
# 대화 턴 간 서버 생존을 위해 Bash 도구 호출에 run_in_background: true 사용.
scripts/start-server.sh --project-dir /path/to/project
```
Bash 도구로 호출 시 `run_in_background: true` 설정. 다음 턴에 `$STATE_DIR/server-info` 읽어 URL·포트 획득.

**Codex:**
```bash
# Codex가 백그라운드 프로세스 reap. 스크립트가 CODEX_CI 자동 감지·foreground 모드 전환.
# 정상 실행 — 추가 플래그 불필요.
scripts/start-server.sh --project-dir /path/to/project
```

**Gemini CLI:**
```bash
# 프로세스가 턴 간 생존하도록 --foreground 사용·shell 도구 호출에 is_background: true 설정
scripts/start-server.sh --project-dir /path/to/project --foreground
```

**기타 환경:** 서버는 대화 턴 간 백그라운드에서 계속 실행 필수. 환경이 detached 프로세스 reap 시 `--foreground` 사용·플랫폼의 백그라운드 실행 메커니즘으로 명령 실행.

URL이 브라우저에서 도달 불가 시 (원격/컨테이너 셋업에서 일반), 비 loopback 호스트 바인드:

```bash
scripts/start-server.sh \
  --project-dir /path/to/project \
  --host 0.0.0.0 \
  --url-host localhost
```

반환된 URL JSON에 출력될 hostname 제어에 `--url-host` 사용.

## 루프

1. **서버 alive 체크**, **`screen_dir`의 새 파일에 HTML 작성**:
   - 각 write 전 `$STATE_DIR/server-info` 존재 체크. 없거나 (`$STATE_DIR/server-stopped` 존재 시) 서버 종료 — 계속 전 `start-server.sh`로 재시작. 서버는 30분 비활성 후 auto-exit.
   - 시맨틱 파일명 사용: `platform.html`·`visual-style.html`·`layout.html`
   - **파일명 절대 재사용 X** — 각 스크린은 새 파일
   - Write 도구 사용 — **cat/heredoc 절대 사용 X** (터미널에 노이즈 덤프)
   - 서버가 가장 새 파일 자동 서빙

2. **사용자에게 무엇 기대할지 알림·턴 종료:**
   - URL 리마인드 (첫째만 아닌 모든 단계)
   - 화면에 무엇 있는지 짧은 텍스트 요약 (예: "홈페이지 3 레이아웃 옵션 표시")
   - 터미널에서 응답 요청: "Take a look and let me know what you think. Click to select an option if you'd like."

3. **다음 턴** — 사용자가 터미널에서 응답 후:
   - 존재 시 `$STATE_DIR/events` 읽기 — 이는 사용자의 브라우저 상호작용 (클릭·선택)을 JSON 라인으로 포함
   - 사용자 터미널 텍스트와 병합·전체 그림 획득
   - 터미널 메시지가 주된 피드백·`state_dir/events`가 구조화 상호작용 데이터 제공

4. **반복 또는 진행** — 피드백이 현재 스크린 변경 시 새 파일 작성 (예: `layout-v2.html`). 현재 단계 검증된 후에만 다음 질문 이동.

5. **터미널 복귀 시 unload** — 다음 단계가 브라우저 불필요 시 (예: 명확화 질문·트레이드오프 논의), stale 컨텐츠 클리어용 대기 스크린 push:

   ```html
   <!-- filename: waiting.html (또는 waiting-2.html 등) -->
   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
     <p class="subtitle">Continuing in terminal...</p>
   </div>
   ```

   이는 대화가 이동했는데 사용자가 해결된 선택 응시하는 것 방지. 다음 시각 질문 시 평소대로 새 컨텐츠 파일 push.

6. 완료까지 반복.

## 컨텐츠 Fragment 작성

페이지 안에 들어갈 컨텐츠만 작성. 서버가 자동으로 프레임 템플릿에 wrap (헤더·테마 CSS·선택 indicator·모든 인터랙티브 인프라).

**최소 예시:**

```html
<h2>Which layout works better?</h2>
<p class="subtitle">Consider readability and visual hierarchy</p>

<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>Single Column</h3>
      <p>Clean, focused reading experience</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content">
      <h3>Two Column</h3>
      <p>Sidebar navigation with main content</p>
    </div>
  </div>
</div>
```

이게 전부. `<html>`·CSS·`<script>` 태그 불필요. 서버가 모두 제공.

## 사용 가능 CSS 클래스

프레임 템플릿이 컨텐츠에 다음 CSS 클래스 제공:

### Options (A/B/C 선택)

```html
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>Title</h3>
      <p>Description</p>
    </div>
  </div>
</div>
```

**다중 선택:** 컨테이너에 `data-multiselect` 추가로 사용자가 다중 옵션 선택 가능. 각 클릭이 항목 토글. indicator 바가 카운트 표시.

```html
<div class="options" data-multiselect>
  <!-- 동일 옵션 markup — 사용자가 다중 선택/해제 가능 -->
</div>
```

### Card (시각 디자인)

```html
<div class="cards">
  <div class="card" data-choice="design1" onclick="toggleSelect(this)">
    <div class="card-image"><!-- mockup 컨텐츠 --></div>
    <div class="card-body">
      <h3>Name</h3>
      <p>Description</p>
    </div>
  </div>
</div>
```

### Mockup 컨테이너

```html
<div class="mockup">
  <div class="mockup-header">Preview: Dashboard Layout</div>
  <div class="mockup-body"><!-- mockup HTML --></div>
</div>
```

### Split view (side-by-side)

```html
<div class="split">
  <div class="mockup"><!-- 왼쪽 --></div>
  <div class="mockup"><!-- 오른쪽 --></div>
</div>
```

### Pros/Cons

```html
<div class="pros-cons">
  <div class="pros"><h4>Pros</h4><ul><li>Benefit</li></ul></div>
  <div class="cons"><h4>Cons</h4><ul><li>Drawback</li></ul></div>
</div>
```

### Mock 요소 (와이어프레임 빌딩 블록)

```html
<div class="mock-nav">Logo | Home | About | Contact</div>
<div style="display: flex;">
  <div class="mock-sidebar">Navigation</div>
  <div class="mock-content">Main content area</div>
</div>
<button class="mock-button">Action Button</button>
<input class="mock-input" placeholder="Input field">
<div class="placeholder">Placeholder area</div>
```

### 타이포그래피·섹션

- `h2` — 페이지 제목
- `h3` — 섹션 헤딩
- `.subtitle` — 제목 아래 보조 텍스트
- `.section` — 아래 마진 있는 컨텐츠 블록
- `.label` — 작은 대문자 라벨 텍스트

## 브라우저 이벤트 형식

사용자가 브라우저에서 옵션 클릭 시 상호작용이 `$STATE_DIR/events`에 기록 (라인당 JSON 객체 하나). 새 스크린 push 시 파일 자동 클리어.

```jsonl
{"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
{"type":"click","choice":"c","text":"Option C - Complex Grid","timestamp":1706000108}
{"type":"click","choice":"b","text":"Option B - Hybrid","timestamp":1706000115}
```

전체 이벤트 스트림이 사용자 탐색 경로 표시 — 정착 전 다중 옵션 클릭 가능. 마지막 `choice` 이벤트가 보통 최종 선택. 그러나 클릭 패턴이 망설임·선호 드러낼 수 있어 질문 가치.

`$STATE_DIR/events` 존재 안 하면 사용자가 브라우저와 상호작용 X — 터미널 텍스트만 사용.

## 디자인 팁

- **질문에 fidelity 스케일** — 레이아웃에 와이어프레임·폴리시 질문에 폴리시
- **각 페이지에서 질문 설명** — 그냥 "Pick one"이 아닌 "Which layout feels more professional?"
- **진행 전 반복** — 피드백이 현재 스크린 변경 시 새 버전 작성
- 스크린당 **최대 2-4 옵션**
- **중요할 때 실제 컨텐츠 사용** — 사진 포트폴리오는 실제 이미지(Unsplash) 사용. 플레이스홀더 컨텐츠가 디자인 이슈 가림.
- **mockup 단순 유지** — 픽셀 완벽 디자인 아닌 레이아웃·구조 집중

## 파일 명명

- 시맨틱 이름 사용: `platform.html`·`visual-style.html`·`layout.html`
- 파일명 절대 재사용 X — 각 스크린은 새 파일
- 반복: `layout-v2.html`·`layout-v3.html` 같은 버전 접미사 추가
- 서버가 수정 시간으로 가장 새 파일 서빙

## 정리

```bash
scripts/stop-server.sh $SESSION_DIR
```

세션이 `--project-dir` 사용 시 mockup 파일은 나중 참조용으로 `.superpowers/brainstorm/`에 영속. `/tmp` 세션만 stop 시 삭제.

## 참조

- 프레임 템플릿 (CSS 참조): `scripts/frame-template.html`
- 헬퍼 스크립트 (클라이언트 사이드): `scripts/helper.js`
