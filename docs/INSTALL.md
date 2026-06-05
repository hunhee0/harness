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

#### A. 디렉토리·파일 매핑 (모두 복수형 유지)

opencode 공식 표준 + devai fork 모두 복수형 디렉터리를 사용한다. 변환은 디렉터리명을 그대로 두고 prefix 만 `.opencode/` 로 바꾼다.

| 원본 (Claude Code) | 변환 후 (opencode) | 비고 |
|---|---|---|
| `.claude/agents/` | `.opencode/agents/` | 복수형 유지 |
| `.claude/skills/` | `.opencode/skills/` | 복수형 유지 (SKILL.md 보존) |
| `.claude/commands/` | `.opencode/commands/` | 복수형 유지 |
| `.claude/rules/` | `.opencode/rules/` | 복수형 유지 |
| `.claude/settings.json` | **(미복사)** | opencode 는 hook 을 plugin 으로 대체 → settings.json 불필요 |
| (신규 생성) | `.opencode/plugins/harness-rules.js` | caveman + Karpathy 4원칙 + SDD 규칙을 system 에 주입하는 plugin |
| 기타 `.claude/*` 참조 | `.opencode/*` | prefix 만 치환 (디렉터리명 보존) |

#### B. Agent frontmatter 자동 변환

`.opencode/agents/*.md` 의 frontmatter:

| 항목 | 동작 |
|---|---|
| `name:` | **보존** (devai 필수 필드. 원본에 없으면 파일명으로 삽입) |
| `color:` | 제거 |
| `mode: subagent` | description 다음에 삽입 (없을 때) |
| `model:` | `ABCLab/[KTDS] Qwen3.6-*` 로 매핑/삽입 (아래 표) |
| `tools: [..]` 배열 라인 | 제거 (미지정 시 기본 도구 상속) |

**KTDS 모델 매핑**:

| 모델 | 용도 | 적용 agent |
|---|---|---|
| `ABCLab/[KTDS] Qwen3.6-27B-FP8` | dense 27B, 깊은 추론·생성 | architect, code-architect, security-reviewer, tdd-guide, planner, implementer, reviewer, qa |
| `ABCLab/[KTDS] Qwen3.6-35B-A3B-FP8` | MoE active 3B, 경량·빠름 | code-reviewer, python-reviewer, java-reviewer, typescript-reviewer, fastapi-reviewer, loop-operator, doc-updater |

> 매핑 없는 agent 는 기본값(27B). `ABCLab/` provider prefix 가 사내 provider 형식과 다르면 setup 의 `$AgentModelMap`(ps1) / `ktds_model_for`(sh) 를 수정.

#### C. 본문 내 호출·경로 자동 변환

| 원본 (Claude Code) | 변환 후 (opencode/devai) |
|---|---|
| `Agent(subagent_type="general-purpose", description=X, prompt="[역할] .../agents/<name>.md ...")` | `task(subagent_type="<name>", load_skills=[...], description=X, prompt=...)` — prompt 의 `agents/<name>.md` 에서 실제 agent 이름을 추출해 `subagent_type` 에 넣고, planner/implementer 는 `load_skills`(speckit-*) 자동 주입 |
| `AskUserQuestion` | `STOP(텍스트로 사용자에게 옵션 제시 후 응답 대기)` |
| `.claude/...` 경로 | `.opencode/...` (prefix 치환) |

대상 확장자: `.md` / `.json` / `.ps1` / `.sh` / `.toml` / `.yaml` / `.yml` / `.txt`.

### 2-2. 자동 변환 후 수동 검토 항목

| 항목 | 검토 내용 |
|---|---|
| (a) primary agent | 자동 변환은 모든 agent 를 `mode: subagent` 로 둔다. 사용자가 직접 `@` 로 대화할 메인 agent 가 필요하면 하나를 `mode: primary` 로 변경 (orchestrator 파이프라인만 쓰면 불필요) |
| (b) skills nested 구조 | `.opencode/skills/<skill>/SKILL.md` + 보조 파일(`scripts/`) 구조가 사내 fork 에서 지원되는지 확인 |
| (c) model id 형식 | `ABCLab/[KTDS] Qwen3.6-*` 가 사내 provider 가 기대하는 형식과 일치하는지 확인 |
| (d) spec-kit | `.specify/` 가 opencode 에서 동작하는지 확인 (planner 가 `load_skills` 로 speckit-* 절차 수행) |
| (e) plugin 동작 | `.opencode/plugins/harness-rules.js` 로드 확인 (재시작 후 응답에 규칙 반영). devai 외 fork 는 `experimental.chat.system.transform` hook 지원 여부 확인. 해제: 환경변수 `HARNESS_RULES_OFF=1` |

### 2-3. opencode 공식 구조 참고 (사내 fork 차이 검토용)

| 항목 | Claude Code | 자동 변환 결과 | opencode 공식 |
|------|-------------|---------------|---------------|
| 에이전트 위치 | `.claude/agents/*.md` | `.opencode/agents/*.md` | `.opencode/agents/*.md` (복수형) |
| 스킬 | `SKILL.md` + Skill tool | `.opencode/skills/` 유지 | `.opencode/skills/` (native skill tool) |
| 명령 위치 | (스킬이 대신) | `.opencode/commands/` | `.opencode/commands/*.md` |
| 전역 설정 | `~/.claude/settings.json` | — | `~/.config/opencode/opencode.json` |
| 프로젝트 설정 | `.claude/settings.json` | (미복사) | 프로젝트 `opencode.json` (fork 차이 가능) |
| 모델 지정 | frontmatter `model` (선택) | `ABCLab/[KTDS] Qwen3.6-*` 삽입 | frontmatter `model` (권장) |
| subagent 호출 | `Agent` tool | `task(subagent_type="<이름>", load_skills=[...])` | `task` tool / `@agent-name` |
| 훅 | `settings.json` 의 `hooks` | `.opencode/plugins/*.js` | `.opencode/plugins/*.js` |

### 2-4. 수동 변환 (자동 모드 미사용 시)

자동 모드(`-Opencode` / `--opencode`)가 §2-1 의 모든 변환을 수행하므로 **자동 모드 사용을 권장**한다. 직접 변환하려면 §2-1 표 그대로:

1. 디렉터리 prefix 만 `.opencode/` 로 변경 (복수형 유지 — `agents`/`skills`/`commands`/`rules`)
2. agent frontmatter: `name` 보존, `color`/`tools[]` 제거, `mode: subagent` + `model: "ABCLab/[KTDS] Qwen3.6-*"` 삽입
3. 본문 `Agent(...)` → `task(subagent_type="<이름>", load_skills=[...], ...)`, `AskUserQuestion` → `STOP(...)`, `.claude/` → `.opencode/`
4. `.opencode/plugins/harness-rules.js` 배치 (저장소 `.opencode/plugins/` 원본 복사)
5. `settings.json` 은 복사하지 않음 (hook 은 plugin 이 대체)

> 자원 규모: agents 15 + skills ~37 (speckit 5 + harness 3 + ecc 21 + superpowers 8) + commands 10.

### 2-5. 변환 후 검증 체크리스트

- [ ] `.opencode/agents/` 15개 파일 (L1 4 + L2 11) frontmatter 유효 (`name`, `description`, `mode`, `model`)
- [ ] 모든 agent `mode: subagent` (orchestrator 가 `task()` 로 호출). 직접 대화용이 필요하면 하나만 `mode: primary`
- [ ] `model` 이 `ABCLab/[KTDS] Qwen3.6-*` (또는 사내 provider 형식)
- [ ] `.opencode/` 디렉터리 전부 복수형 (`agents`/`skills`/`commands`/`rules`/`plugins`)
- [ ] `.claude/settings.json` 미생성 (opencode 는 plugin 사용)
- [ ] `.opencode/plugins/harness-rules.js` 존재 + 재시작 후 응답에 규칙(caveman 등) 반영
- [ ] orchestrator skill 트리거 시 planner/implementer/reviewer/qa 가 `task()` 로 호출됨 (내장 Worker fallback 아님)
- [ ] 본문 `Agent(...)` → `task(subagent_type="<실제 이름>", load_skills=[...])` 변환 확인 (`subagent_type="general-purpose"` 가 아닌 실제 agent 이름)
- [ ] Phase 3 팬아웃이 같은 응답에서 N개 `task()` 동시 호출 가능
- [ ] commands 10개 (multi-* / gan-design / update-* / test-coverage 등) `.opencode/commands/` 등록
- [ ] `docs/rules/` 가 LLM 컨텍스트로 로딩되는지 확인
- [ ] 진입 문서 인식 확인 (사내 fork 가 `CLAUDE.md` / `AGENTS.md` 중 무엇을 읽는지)

### 2-6. 사내 fork 차이 검토 가이드

사내 fork 사용 중이면 다음을 사내 문서로 확인:

1. **디렉터리 경로** — `.opencode/agents/` 등 복수형 규약 (devai 는 복수형)
2. **frontmatter 필수 필드** — `name`(devai 필수), `mode`, `model` 외 확장 키
3. **subagent 호출** — `task(subagent_type=..., load_skills=[...])` 시그니처. 내장 화이트리스트(`call_devai_agent`) 와 custom agent(`task`) 구분
4. **plugin 시스템** — hook 이벤트명 (`experimental.chat.system.transform`, `tool.execute.before`), plugin 디렉터리(`.opencode/plugins/`)
5. **진입 문서명** — `CLAUDE.md` / `OPENCODE.md` / `AGENTS.md`
6. **spec-kit 호환성** — `.specify/` 동작 / 대체 / 미지원
7. **model id 형식** — `ABCLab/[KTDS] Qwen3.6-*` 수용 여부

---

## 참고

- Claude Code 원본 진입: `CLAUDE.md`, `docs/rules/`
- 오케스트레이터: `.claude/skills/harness-orchestrator/SKILL.md`
- 변경 이력: `docs/changelog/`
- spec-kit constitution 가이드: `.specify/memory/README.md`
- opencode 공식: https://opencode.ai/docs
- setup 스크립트 단일 출처: `setup.ps1` / `setup.sh` 헤더 주석
