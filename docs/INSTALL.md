# 하네스 이식 가이드

이 하네스를 **다른 프로젝트**에 적용하는 방법, 그리고 **opencode 환경**으로 변환하는 방법.

> 두 setup 스크립트(`setup.ps1`, `setup.sh`) 모두 **Claude Code 기본 복사** + **opencode 자동 변환** 두 모드를 지원한다. 옵션·매핑·frontmatter 변환·KTDS 모델 ID 등은 스크립트 헤더 주석이 단일 출처이며, 본 문서는 그 동작을 요약한다.

---

## 1. Claude Code 환경 (setup.ps1 / setup.sh)

### 사전 준비

- 대상 프로젝트 디렉토리 (존재하지 않으면 자동 생성됨)
- Git 초기화는 필수 아님
- 대상에 이미 `CLAUDE.md`가 있으면 **덮어쓰지 않고 스킵** — 수동 병합 필요
- 대상에 이미 `.specify/memory/constitution.md` 가 있으면 스킵

### 명령

**Windows (PowerShell):**

```powershell
# 일반 실행 (Claude Code 기본)
.\setup.ps1 -TargetDir "C:\path\to\new-project"

# DryRun (실제 복사 없이 시뮬레이션, 어떤 파일이 복사될지만 출력)
.\setup.ps1 -TargetDir "C:\path\to\new-project" -DryRun

# opencode 자동 변환 모드 (디렉토리·frontmatter·본문 참조 동시 변환)
.\setup.ps1 -TargetDir "C:\path\to\new-project" -Opencode

# 조합 가능
.\setup.ps1 -TargetDir "..\my-project" -Opencode -DryRun
```

> PowerShell 실행 정책 차단 시: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

**Mac / Linux (bash):**

```bash
# 실행 권한 부여 (최초 1회)
chmod +x setup.sh

# 일반 실행 (Claude Code 기본)
./setup.sh /path/to/new-project

# DryRun
./setup.sh /path/to/new-project --dry-run

# opencode 자동 변환 모드
./setup.sh /path/to/new-project --opencode

# 조합 가능
./setup.sh ../my-project --opencode --dry-run
```

### 옵션 요약

| 옵션 (PowerShell / bash) | 동작 |
|---|---|
| `-TargetDir` / `<target-dir>` | 대상 디렉토리 (필수, 없으면 생성) |
| `-DryRun` / `--dry-run` | 실제 복사 없이 매핑만 출력 |
| `-Opencode` / `--opencode` | `.claude/*` → `.opencode/*` 자동 변환 (아래 §2 참조) |

### 복사되는 항목 (Claude Code 기본 모드)

| 항목 | 경로 | 비고 |
|------|------|------|
| 에이전트 정의 | `.claude/agents/` | **15개** — L1 4 (planner/implementer/reviewer/qa) + L2 11 (architect, code-architect, code-reviewer, python-reviewer, fastapi-reviewer, typescript-reviewer, java-reviewer, security-reviewer, tdd-guide, doc-updater, loop-operator) |
| 스킬 (운영) | `.claude/skills/` | speckit-* (5: constitution/specify/plan/tasks/implement) · caveman · harness-orchestrator · harness-adapt |
| 스킬 (ECC 도메인 패턴) | `.claude/skills/ecc/` | **21개** — python·fastapi·java·springboot·jpa·frontend·nextjs·motion·api·tdd 등 |
| 스킬 (superpowers 메타) | `.claude/skills/superpowers/` | **8개** — brainstorming, dispatching-parallel-agents, requesting/receiving-code-review, test-driven-development, systematic-debugging, verification-before-completion, using-git-worktrees |
| 슬래시 커맨드 | `.claude/commands/` | **10개** — gan-design, loop-start, multi-{plan,workflow,backend,frontend}, python-review, test-coverage, update-codemaps, update-docs |
| ECC 부속 규칙 | `.claude/rules/ecc/` | common·java·python·typescript·web 패턴·테스트 |
| Claude 설정 | `.claude/settings.json` | 훅 포함 |
| 규칙 | `docs/rules/` | 7개 파일 (01~07) |
| Speckit 자원 | `.specify/templates/`, `.specify/scripts/`, `.specify/integrations/` | 템플릿·스크립트·통합 |
| Speckit 설정 | `.specify/init-options.json`, `.specify/integration.json` | |
| 헌법 템플릿 | `.specify/memory/constitution.md` | 빈 템플릿. 사용 가이드는 `.specify/memory/README.md` |
| 진입 문서 | `CLAUDE.md` | 기존 파일 존재 시 스킵 |

### 복사되지 않는 항목 (의도)

- `docs/specs/` — 프로젝트별 기능 스펙. 신규 프로젝트는 비어있음
- `docs/changelog/` — 프로젝트별 변경 이력
- `src/`, `tests/` — 실 코드
- `.git/` — 별도 git 초기화

### 사후 작업

이식 직후 두 가지 경로 중 선택:

#### 경로 A. 자동 적응 (권장)

대상 프로젝트에서 새 Claude Code 세션 시작 후:

> 이 프로젝트에 하네스 적용해줘

→ **`harness-adapt`** 스킬이 자동 수행:
- 코드 스택 분석 (매니페스트·디렉토리·도구 감지) → `[STACK]` 키 정규화 (`python-fastapi`/`java-spring`/`ts-next` 등)
- 도메인 분류 (백엔드 / 프론트 / 풀스택 / CLI / 라이브러리 / ML / IaC / 모바일 / 보안중점)
- 사용자 확인 후 다음 파일 자동 수정:
  - `CLAUDE.md` — 프로젝트명·구조·변경 이력 초기화 (Rule 9에 `[STACK]` 값과 활성 L2 기록)
  - `docs/rules/01-project-structure.md` — 잠정 라벨 제거, 실제 스택 반영 (`.claude/` 트리 — agents L1+L2, skills/ecc, skills/superpowers, commands, rules/ecc 보존)
  - `docs/rules/03-ai-agent-guidelines.md` — 인벤토리 표 **수정 금지** (Net-zero), 다음만 추가:
    - **3-2-A 표준 L2 활성화** — 이미 포함된 L2 중 도메인에 맞는 reviewer 팬아웃 신호 (예: `[STACK]=python-fastapi` → fastapi-reviewer/python-reviewer/security-reviewer 활성)
    - **3-2-B 도메인 특화 신규 생성** — 표준 L2로 커버 안 되는 도메인만 (ML: data-validator/model-evaluator, IaC: iac-validator, 모바일: platform-reviewer)
  - (3-2-B 적용 시) `.claude/agents/{신규}.md` 생성 + orchestrator Phase 0.5/3-2 매핑 표 보강
- changelog 자동 기록 (`[STACK]` 키·활성 L2·신규 agent·매핑 보강 여부 포함)

**보존 (수정 안 함)**: ECC 21·superpowers 8·commands 10·L1 4 agent·기존 L2 11 agent 본문. 03 의 인벤토리 표.

상세: `.claude/skills/harness-adapt/SKILL.md`

#### 경로 B. 수동 수정

다음 3개 파일을 직접 편집:

1. **`CLAUDE.md`** — 프로젝트명·도메인·변경 이력 (Rule 9 하단) 초기화
2. **`docs/rules/01-project-structure.md`** — 🟡 잠정 라벨 제거, 실제 스택·구조 반영
3. **`.specify/memory/constitution.md`** (선택) — 헌법 작성. 가이드: `.specify/memory/README.md`

### 첫 기능 개발 (공통)

위 경로 완료 후:

```
1. (선택) /speckit-constitution 으로 헌법 작성
2. "기능 만들어줘" 입력 → harness-orchestrator 자동 트리거
3. SDD 4단계: specify → plan → tasks → implement
```

### 트러블슈팅

| 증상 | 원인 / 해결 |
|------|------------|
| "이미 존재 — 스킵" 메시지 | 기존 파일 보호. 백업 후 수동 병합 |
| Windows: 스크립트 실행 차단 | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| Mac: `realpath` 미작동 | `setup.sh`가 자동 fallback (`greadlink` → `python3` → 입력 그대로) |
| `.claude` 권한 오류 | 대상 디렉토리 쓰기 권한 확인 |
| 복사 후 트리거 안 됨 | 새 Claude Code 세션 시작 (스킬 목록 재로딩) |

---

## 2. opencode 환경으로 변환

이 하네스는 기본적으로 **Claude Code** 구조를 따른다 (`.claude/agents/`, `.claude/skills/`, Skill tool).
**opencode**(`sst/opencode`) 또는 그 **사내 fork** CLI에 적용하려면 디렉토리·frontmatter·본문 참조 변환이 필요하다.

> ✅ **대부분의 변환은 `-Opencode` / `--opencode` 스위치로 자동 수행된다**.
> 본 절은 (a) 자동 변환이 실제로 무엇을 하는지, (b) 자동으로 처리 안 되는 수동 검토 항목을 정리한다.
> 사내 fork 사용 시 디렉토리명·이벤트명·model id 형식 등은 사내 문서 우선 확인.

### 2-1. 자동 변환 (`-Opencode` / `--opencode`) 이 수행하는 작업

#### A. 디렉토리·파일 매핑

| 원본 (Claude Code) | 변환 후 (opencode) | 비고 |
|---|---|---|
| `.claude/agents/` | `.opencode/agent/` | 단수형 |
| `.claude/skills/` | `.opencode/skills/` | **그대로 유지** (SKILL.md 보존; command 로 병합하지 않음) |
| `.claude/commands/` | `.opencode/command/` | 단수형 |
| `.claude/rules/` | `.opencode/rule/` | 단수형 |
| `.claude/settings.json` | `.opencode/settings.json` | 프로젝트 설정 |
| 기타 `.claude/*` 참조 | `.opencode/*` | fallback 매핑 |

#### B. Agent frontmatter 자동 변환

`.opencode/agent/*.md` 의 frontmatter에 다음 변환을 적용:

| 항목 | 동작 |
|---|---|
| `name:` 라인 | **제거** (opencode는 파일명을 사용) |
| `color:` 라인 | **제거** (opencode 무관 필드) |
| `mode: subagent` | description 다음에 **삽입** (없을 때) |
| `model:` | **KTDS Qwen 모델로 매핑/삽입** (아래 표 참조) |
| `tools: [..]` 배열 라인 | **제거** (opencode는 record 형식 기대 — 미지정 시 기본 도구 상속) |

**KTDS 모델 매핑** (Claude 모델 미지원 fork 가정):

| 모델 | 용도 | 적용 agent |
|---|---|---|
| `[KTDS] Qwen3.6-27B-FP8` | dense 27B, 깊은 추론·생성 | architect, code-architect, security-reviewer, tdd-guide, planner, implementer, reviewer, qa (L1 워크플로 + 설계·전략) |
| `[KTDS] Qwen3.6-35B-A3B-FP8` | MoE active 3B, 경량·빠름 | code-reviewer, python-reviewer, java-reviewer, typescript-reviewer, fastapi-reviewer, loop-operator, doc-updater (패턴 리뷰·루프·문서) |

> 매핑 표가 없는 agent 는 기본값(`27B`)로 처리.

#### C. 본문 내 경로 참조 치환

`.md` / `.json` / `.ps1` / `.sh` / `.toml` / `.yaml` / `.yml` / `.txt` 파일 내부의 `.claude/...` 문자열을 위 디렉토리 매핑 규칙(우선순위 동일)으로 자동 치환.

### 2-2. 자동 변환 후 **수동 검토** 필요 항목

스크립트 종료 시 안내되는 항목 (요약):

| 항목 | 검토 내용 |
|---|---|
| (a) Skill/Agent 호출 표기 | `.opencode/skills/` 및 `.opencode/command/` 본문의 `Agent(...)` / `Skill(...)` 호출 — 사내 fork 의 `@agent-name` / `/command-name` 양식으로 **수동 교체** (자동 변환 안 됨) |
| (b) 훅 이벤트명 | `.opencode/settings.json` 의 `UserPromptSubmit` 등 Claude Code 이벤트명 → opencode 이벤트명 (`user_prompt_submit` 등) 마이그레이션 |
| (c) primary agent 지정 | 자동 변환은 모든 agent 를 `mode: subagent` 로 둠. 사용자가 직접 대화할 메인 agent 하나의 frontmatter 를 `mode: primary` 로 변경 |
| (d) skills nested 구조 | `.opencode/skills/<skill>/SKILL.md` + 보조 파일(`scripts/`, `references/`) 구조가 사내 fork 에서 지원되는지 확인 |
| (e) rules 디렉토리명 | `.opencode/rule/` 가 사내 fork 의 rules 디렉토리 규약과 일치하는지 확인 |
| (f) model id 형식 | `[KTDS] Qwen3.6-27B-FP8` 형식이 사내 opencode provider 가 기대하는 id 형식과 일치하는지 확인 |

### 2-3. opencode 공식 구조 참고 (사내 fork 차이 검토용)

opencode 공식과 본 하네스 자동 변환의 의미 차이:

| 항목 | Claude Code | 자동 변환 결과 | opencode 공식 |
|------|-------------|---------------|---------------|
| 에이전트 위치 | `.claude/agents/*.md` | `.opencode/agent/*.md` | `.opencode/agent/*.md` |
| 스킬 개념 | 1급 시민 (`SKILL.md` + Skill tool) | `.opencode/skills/` 폴더 유지 | **직접 대응 없음** — command/primary agent 로 수동 변환 권장 |
| 명령 위치 | (없음, 스킬이 대신) | `.opencode/command/` | `.opencode/command/*.md` |
| 전역 설정 | `~/.claude/settings.json` | — | `~/.config/opencode/opencode.json` |
| 프로젝트 설정 | `.claude/settings.json` | `.opencode/settings.json` | 프로젝트 루트 `opencode.json` (fork 차이 가능) |
| 모델 지정 | frontmatter `model` (선택) | `[KTDS] Qwen3.6-*` 자동 삽입 | frontmatter `model` (권장) |
| 도구 권한 | (정책 기반) | `tools:` 배열 라인 제거 → 기본 상속 | frontmatter `tools: { write: true, edit: true }` 명시 |
| 호출 방식 | `Skill` tool, `Agent` tool | (본문 미변환) | `@agent-name` / `/command-name` |
| 훅 | `settings.json` 의 `hooks` (PreToolUse 등) | (본문 미변환) | `opencode.json` 의 `hooks` (이벤트명 다름) |

### 2-4. 수동 변환 (자동 모드를 쓰지 않는 경우)

자동 변환을 사용하지 않거나 결과를 직접 검토하며 변환하고 싶다면 다음 절차를 따른다.

#### Step 1. 디렉토리 이동

```bash
# §2-1 A 의 매핑 표와 동일
mv .claude/agents      .opencode/agent
mv .claude/skills      .opencode/skills      # 그대로 유지 권장 (또는 command 로 수동 변환)
mv .claude/commands    .opencode/command
mv .claude/rules       .opencode/rule
mv .claude/settings.json .opencode/settings.json
```

> 자원 규모: agents 15 + skills ~37 (speckit 5 + harness 3 + ecc 21 + superpowers 8) + commands 10.
> 수동 변환 시 우선순위는 L1 4 + harness-orchestrator/adapt 부터.

#### Step 2. 에이전트 frontmatter 변환

**기존 (Claude Code):**

```yaml
---
name: planner
description: 새 기능의 스펙·계획·태스크 단계 전담 에이전트.
color: blue
tools: [Read, Write, Edit, Bash]
---
```

**변환 후 (opencode, 자동 모드와 동일):**

```yaml
---
description: 새 기능의 스펙·계획·태스크 단계 전담 에이전트.
mode: subagent
model: "[KTDS] Qwen3.6-27B-FP8"
---
```

- `name` → 파일명으로 대체 (`planner.md` → `@planner`)
- `color` → 제거
- `mode: subagent` (orchestrator 가 호출) / `mode: primary` (사용자 직접 대화)
- `model` → 사내 LLM 식별자 (KTDS Qwen 매핑 §2-1 B 표 참조, 또는 사내 정책)
- `tools` → 배열 형식 제거. 필요 시 record 형식으로 명시 (`tools: { write: true, edit: true }`)

#### Step 3. 스킬 처리 (선택지 2가지)

**옵션 1: 그대로 유지 (자동 변환과 동일)** — `.opencode/skills/<skill>/SKILL.md` 구조를 사내 fork 가 지원하면 그대로 사용.

**옵션 2: command 로 변환** — SKILL.md 본문을 command 파일로 복사:

```yaml
# .opencode/command/harness-orchestrator.md
---
description: 기능 개발 파이프라인 진입점 (planner → implementer → reviewer → qa)
agent: build              # 사내 fork에 정의된 primary agent 이름
---

## Phase 0: 컨텍스트 확인
...
```

- 호출: `/harness-orchestrator`
- `references/` 하위 파일은 본문 인라인 또는 별도 파일로 분리

#### Step 4. Agent 호출 코드 변환 (수동 — 자동 변환 안 됨)

오케스트레이터·스킬 내부의 에이전트 호출 표기:

**기존 (Claude Code):**

```
Agent(
  subagent_type="general-purpose",
  description="...",
  prompt="""
  [역할] .claude/agents/planner.md 정의 따를 것
  [GOAL] ...
  """
)
```

**변환 (opencode 양식, 추정):**

```
@planner

[GOAL] ...
[INPUT] ...
[OUTPUT] ...
```

또는 사내 fork 의 `spawn(agent, prompt)` / `task(...)` API. **사내 docs 확인 필수.**

#### Step 5. 훅 변환 (수동 — 자동 변환 안 됨)

**기존 (`.claude/settings.json`):**

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "echo [CAVEMAN LITE] ..." }
        ]
      }
    ]
  }
}
```

**변환 (opencode `opencode.json` 또는 `.opencode/settings.json`):**

```json
{
  "hooks": {
    "user_prompt_submit": {
      "command": "echo [CAVEMAN LITE] ..."
    }
  }
}
```

> 정확한 이벤트명·스키마는 opencode 또는 사내 fork 문서 확인. 위는 일반적 추정.

#### Step 6. spec-kit / .specify 호환성 확인

`.specify/` 디렉토리는 spec-kit 종속. opencode 에서 동일하게 동작하는지 확인:

| 상황 | 조치 |
|------|------|
| spec-kit 이 opencode 에서도 동작 | `.specify/` 그대로 유지, `/speckit-*` 명령 그대로 사용 |
| 미동작 | spec-kit 대체 도구 도입 또는 수동 워크플로우로 변환 (스펙은 `docs/specs/` 에 직접 작성) |

### 2-5. 변환 후 검증 체크리스트

- [ ] `.opencode/agent/` 15개 파일 (L1 4 + L2 11) 모두 frontmatter 유효 (`description`, `mode`, `model` 필수)
- [ ] L1 4개는 `mode: subagent`, L2 reviewer 류도 `mode: subagent` (Phase 3 팬아웃 호출 대상)
- [ ] 한 agent 는 `mode: primary` 로 명시적 변경 (사용자 직접 대화용)
- [ ] `model` 이 사내 provider 가 기대하는 id 형식 (KTDS Qwen 자동 매핑값 또는 사내 정책)
- [ ] `tools` 가 필요 시 record 형식 (`write: true, edit: true`) 으로 추가됨
- [ ] 오케스트레이터 command/skill 이 트리거 키워드로 정상 호출됨
- [ ] 에이전트 간 호출 표기가 사내 spawn/task API 로 **수동 변환됨** (Phase 3 팬아웃은 **같은 응답에서 N개 spawn 동시 호출** 가능해야 함 — 순차 호출만 지원하면 토큰·시간 비용 N배)
- [ ] commands 10개 (multi-* / gan-design / update-* / test-coverage 등) 변환·등록
- [ ] ECC/superpowers 스킬 → `.opencode/skills/` 유지 또는 command 변환 (호출 횟수 적은 스킬은 docs/ref/ 로 흡수 가능)
- [ ] 훅이 caveman 리마인더 정상 주입 (이벤트명 마이그레이션 완료)
- [ ] `docs/rules/` 가 LLM 컨텍스트로 로딩되는지 확인 (자동 로딩 메커니즘 차이 가능)
- [ ] `CLAUDE.md` → opencode 가 동등한 진입 문서를 인식하는지 확인 (사내 fork 가 `OPENCODE.md` / `AGENTS.md` 등을 쓸 수 있음)
- [ ] `[STACK]` 변수 전파 매커니즘 — opencode 에서 spawn 시 context 변수 전달 방식 확인

### 2-6. 사내 fork 차이 검토 가이드

사내 fork 사용 중이면 다음을 사내 문서로 확인:

1. **에이전트·명령 디렉토리 경로** — `.opencode/agent/` 와 다를 수 있음
2. **frontmatter 필수 필드** — `mode`, `model`, `tools` 외 사내 확장 키
3. **에이전트 spawn API** — 호출 함수명·파라미터 시그니처
4. **훅 시스템** — 지원 이벤트명·페이로드 스키마
5. **진입 문서명** — `CLAUDE.md` / `OPENCODE.md` / `AGENTS.md` 등
6. **spec-kit 호환성** — 별도 구현체 / 대체 도구 / 미지원
7. **model id 형식** — `[KTDS] Qwen3.6-27B-FP8` 형식 수용 여부

---

## 참고

- Claude Code 원본 진입: `CLAUDE.md`, `docs/rules/`
- 오케스트레이터: `.claude/skills/harness-orchestrator/SKILL.md`
- 변경 이력: `docs/changelog/`
- spec-kit constitution 가이드: `.specify/memory/README.md`
- opencode 공식: https://opencode.ai/docs
- setup 스크립트 단일 출처: `setup.ps1` / `setup.sh` 헤더 주석
