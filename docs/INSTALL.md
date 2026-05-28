# 하네스 이식 가이드

이 하네스를 **다른 프로젝트**에 적용하는 방법, 그리고 **opencode 환경**으로 변환하는 방법.

---

## 1. Claude Code 환경 (setup.ps1 / setup.sh)

### 사전 준비

- 대상 프로젝트 디렉토리 (존재하지 않으면 자동 생성됨)
- Git 초기화는 필수 아님
- 대상에 이미 `CLAUDE.md`가 있으면 **덮어쓰지 않고 스킵** — 수동 병합 필요

### 명령

**Windows (PowerShell):**

```powershell
# 일반 실행
.\setup.ps1 -TargetDir "C:\path\to\new-project"

# DryRun (실제 복사 없이 시뮬레이션, 어떤 파일이 복사될지만 출력)
.\setup.ps1 -TargetDir "C:\path\to\new-project" -DryRun

# 상대 경로도 가능
.\setup.ps1 -TargetDir "..\my-project"
```

> PowerShell 실행 정책 차단 시: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

**Mac / Linux (bash):**

```bash
# 실행 권한 부여 (최초 1회)
chmod +x setup.sh

# 일반 실행
./setup.sh /path/to/new-project

# DryRun
./setup.sh /path/to/new-project --dry-run
```

### 복사되는 항목

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
| Speckit 자원 | `.specify/templates/`, `.specify/scripts/`, `.specify/integrations/` | 템플릿·스크립트 |
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
**opencode**(`sst/opencode`) 또는 그 **사내 fork** CLI에 적용하려면 아래 매핑·변환이 필요하다.

> ⚠️ 아래는 opencode 공식 구조 기준. **사내 fork는 차이가 있을 수 있음** — 사내 문서·예시 우선 확인.

### 핵심 구조 차이

| 항목 | Claude Code | opencode |
|------|-------------|----------|
| 에이전트 위치 | `.claude/agents/*.md` | `.opencode/agent/*.md` |
| 스킬 개념 | 1급 시민 (`SKILL.md` + Skill tool) | **직접 대응 없음** — command 또는 primary agent로 변환 |
| 명령 위치 | (없음, 스킬이 대신) | `.opencode/command/*.md` |
| 전역 설정 | `~/.claude/settings.json` | `~/.config/opencode/opencode.json` |
| 프로젝트 설정 | `.claude/settings.json` | 프로젝트 루트 `opencode.json` |
| 모델 지정 | frontmatter `model` (선택) | frontmatter `model` (권장, 예: `anthropic/claude-sonnet-4-5`) |
| 도구 권한 | (정책 기반) | frontmatter `tools: { write: true, edit: true }` 명시 |
| 호출 방식 | `Skill` tool, `Agent` tool | `@agent-name` / `/command-name` |
| 훅 | `settings.json`의 `hooks` (PreToolUse 등) | `opencode.json`의 `hooks` (이벤트명 다름) |

### 변환 단계

#### Step 1. 디렉토리 이동

```bash
# 디렉토리 단순 이동 (이름 변경)
mv .claude/agents      .opencode/agent
mv .claude/skills      .opencode/command   # 의미 변환 필요 (아래 Step 3 참조)
mv .claude/commands    .opencode/command/  # 슬래시 커맨드는 그대로 command 매핑 가능 (병합 주의)
# .claude/rules/ecc/ 는 opencode 측 rules 디렉토리로 이동하거나 docs/rules/ 로 흡수 (사내 fork 정책 확인)
```

> 단순 이동만으로는 부족. 스킬은 의미적으로 command(또는 primary agent)로 재정의 필요.
>
> **자원 규모 의식**: 이식 대상은 agents 15 + skills ~37 (speckit 5 + harness 3 + ecc 21 + superpowers 8) + commands 10. 변환 시 우선순위는 L1 4 + harness-orchestrator/adapt 부터.

#### Step 2. 에이전트 frontmatter 변환

**기존 (Claude Code):**

```yaml
---
name: planner
description: 새 기능의 스펙·계획·태스크 단계 전담 에이전트.
---
```

**변환 후 (opencode):**

```yaml
---
description: 새 기능의 스펙·계획·태스크 단계 전담 에이전트.
mode: subagent           # subagent(서브) 또는 primary(메인)
model: <사내 LLM 모델 ID>   # 비워두면 기본 모델 사용 (사내 정책 확인)
tools:
  write: true            # 파일 생성 권한
  edit: true             # 파일 수정 권한
  bash: true             # 명령 실행 권한
---
```

- `name` 필드 → **파일명으로 자동 대체** (`planner.md` → `@planner`)
- `mode: subagent` → 오케스트레이터가 호출하는 보조 에이전트 (planner, implementer, reviewer, qa)
- `mode: primary` → 사용자가 직접 대화하는 메인 에이전트
- `model` 필드 → 사내 LLM 식별자 또는 미지정 (사내 정책 확인)

#### Step 3. 스킬 → command 변환

**Claude Code 스킬** (`harness-orchestrator/SKILL.md`):

```yaml
---
name: harness-orchestrator
description: 이 프로젝트의 기능 개발 파이프라인 진입점...
---

## Phase 0: 컨텍스트 확인
...
```

**opencode command** (`harness-orchestrator.md`):

```yaml
---
description: 기능 개발 파이프라인 진입점 (planner → implementer → reviewer → qa)
agent: build              # 사내 fork에 정의된 primary agent 이름
---

## Phase 0: 컨텍스트 확인
...
```

- `SKILL.md` 본문을 그대로 command 본문으로 복사
- `agent:` 필드로 어떤 primary agent가 이 command를 실행할지 지정
- 호출은 `/harness-orchestrator` (또는 사내 명령 prefix)

> Skill의 `references/` 하위 파일은 command 본문 또는 별도 파일로 분리하여 참조.

#### Step 4. Agent 호출 코드 변환

오케스트레이터 내부의 에이전트 호출:

**기존 (Claude Code 양식):**

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

또는 사내 fork의 `spawn(agent, prompt)` / `task(...)` API. **사내 docs 확인 필수.**

#### Step 5. 훅 변환

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

**변환 (opencode `opencode.json`):**

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

`.specify/` 디렉토리는 spec-kit 종속. opencode에서 동일하게 동작하는지 확인:

| 상황 | 조치 |
|------|------|
| spec-kit이 opencode에서도 동작 | `.specify/` 그대로 유지, `/speckit-*` 명령 그대로 사용 |
| 미동작 | spec-kit 대체 도구 도입 또는 수동 워크플로우로 변환 (스펙은 `docs/specs/`에 직접 작성) |

### 변환 후 검증 체크리스트

- [ ] `.opencode/agent/` 15개 파일 (L1 4 + L2 11) 모두 frontmatter 유효 (`description`, `mode`, `tools` 필수)
- [ ] L1 4개는 `mode: subagent`, L2 reviewer 류도 `mode: subagent` (Phase 3 팬아웃 호출 대상)
- [ ] `mode` / `model` / `tools` 필드가 사내 정책 준수
- [ ] 오케스트레이터 command가 트리거 키워드로 정상 호출됨
- [ ] 에이전트 간 호출이 사내 spawn/task API 사용 (Phase 3 팬아웃은 **같은 응답에서 N개 spawn 동시 호출** 가능해야 함 — 순차 호출만 지원하면 토큰·시간 비용 N배)
- [ ] commands 10개 (multi-* / gan-design / update-* / test-coverage 등) 변환·등록
- [ ] ECC/superpowers 스킬 → command 변환 또는 docs 참조로 분리 (호출 횟수 적은 스킬은 docs/ref/ 로 흡수)
- [ ] 훅이 caveman 리마인더 정상 주입
- [ ] `docs/rules/`가 LLM 컨텍스트로 로딩되는지 확인 (자동 로딩 메커니즘 차이 가능)
- [ ] `CLAUDE.md` → opencode가 동등한 진입 문서를 인식하는지 확인 (사내 fork가 `OPENCODE.md` 등을 쓸 수 있음)
- [ ] `[STACK]` 변수 전파 매커니즘 — opencode에서 spawn 시 context 변수 전달 방식 확인

### 사내 fork 차이 검토 가이드

사내 fork 사용 중이면 다음을 사내 문서로 확인:

1. **에이전트·명령 디렉토리 경로** — `.opencode/agent/` 와 다를 수 있음
2. **frontmatter 필수 필드** — `mode`, `model`, `tools` 외 사내 확장 키
3. **에이전트 spawn API** — 호출 함수명·파라미터 시그니처
4. **훅 시스템** — 지원 이벤트명·페이로드 스키마
5. **진입 문서명** — `CLAUDE.md` / `OPENCODE.md` / `AGENTS.md` 등
6. **spec-kit 호환성** — 별도 구현체 / 대체 도구 / 미지원

---

## 참고

- Claude Code 원본 진입: `CLAUDE.md`, `docs/rules/`
- 오케스트레이터: `.claude/skills/harness-orchestrator/SKILL.md`
- 변경 이력: `docs/changelog/`
- spec-kit constitution 가이드: `.specify/memory/README.md`
- opencode 공식: https://opencode.ai/docs
