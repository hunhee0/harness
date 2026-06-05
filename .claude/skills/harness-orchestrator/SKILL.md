---
name: harness-orchestrator
description: 이 프로젝트의 기능 개발 파이프라인 진입점. "기능 만들어줘", "구현해줘", "개발 시작", "새 기능 추가", "스펙 작성해줘", "태스크 분해", "이어서 진행", "다시 구현", "개발 재개", "재실행", "업데이트", "수정", "보완", "결과 개선", "feature 보완" 등 기능 개발·수정·보완 요청 시 반드시 이 스킬을 사용할 것. planner → implementer → reviewer → qa 에이전트 파이프라인을 통해 SDD 워크플로우를 강제한다.
---

> **opencode/devai 환경**: `setup -Opencode` 변환이 `Agent(...)` → `task(...)`,
> 디렉터리 경로 `.claude/*` → `.opencode/*`, `AskUserQuestion` → STOP 텍스트로 자동 치환.
> 원본은 Claude Code 형식으로 유지.
>
> **자연어 트리거** ("기능 만들어줘", "구현해줘", "이어서 진행", "수정", "보완" 등) 수신 시
> 이 스킬이 Phase 0 → 5 파이프라인을 직접 운영한다: **planner → implementer → reviewer → qa**.
> 각 Phase 에서 해당 agent 를 `task()` (변환 전 `Agent()`) 로 호출한다.
>
> **🚦 게이트 원칙 (절대 규칙)**: 모든 Phase 전환은 사용자 승인 게이트를 통과해야 한다.
> `spec(GATE 1) → plan(GATE 2) → tasks(GATE 3) → implement(GATE 4) → review(GATE 5) → qa(GATE 6) → 완료·PR(GATE 7)`.
> **어느 게이트도 건너뛰지 말 것. 승인 없이 다음 Phase 진입 절대 금지.**
> 게이트는 오케스트레이터 메인 컨텍스트가 `AskUserQuestion`(변환 후 STOP 텍스트)으로 제시한다 (subagent 안에 두지 말 것).
> 각 게이트 옵션은 "다음 진행 / 현재 단계 수정 / 중단" 형태로 맥락에 맞게 제시.

---

## Phase 0: 컨텍스트 확인

실행 시작 전 현재 상태 파악:

1. `docs/specs/` 존재 여부 확인
2. 진행 중인 feature가 있으면 해당 `tasks.md` 읽기
3. 상태 분류 후 진입점 결정:

| 상태 | 조건 | 진입점 |
|------|------|--------|
| **신규** | `docs/specs/` 없거나 해당 feature 폴더 없음 | Phase 1 |
| **재개** | `tasks.md`에 미완료 `[ ]` 존재 | Phase 2 (구현 미완료 지점부터) |
| **부분 재실행** | 모든 `[x]` 이나 사용자가 특정 부분 수정 요청 | 영향 Phase만 (예: planner 우회, implementer만) |
| **완료** | 모든 태스크 `[x]` + 사용자 후속 요청 없음 | 완료 보고 후 종료 |

---

## Phase 0.5: 스택 감지 (모든 Phase에 전파)

각 Phase 호출 전에 프로젝트 스택을 1회 식별하여 `[STACK]` 컨텍스트 변수로 모든 agent에 전달.

**감지 우선순위 (있는 파일 기준)**:

| 파일 | 스택 키 | 매핑 |
|------|---------|------|
| `pyproject.toml` / `requirements.txt` + `app/main.py`·`*.py` FastAPI 임포트 | `python-fastapi` | ecc/fastapi-patterns, fastapi-reviewer |
| `pyproject.toml` / `requirements.txt` (일반) | `python` | ecc/python-patterns, python-reviewer |
| `pom.xml` / `build.gradle` + Spring 의존성 | `java-spring` | ecc/springboot-patterns, java-reviewer |
| `pom.xml` / `build.gradle` (일반) | `java` | ecc/java-coding-standards, java-reviewer |
| `package.json` + `next.config.*` | `ts-next` | ecc/nextjs-turbopack, typescript-reviewer |
| `package.json` + `*.tsx`·`*.ts` | `typescript` | ecc/frontend-patterns, typescript-reviewer |
| `package.json` (js만) | `javascript` | typescript-reviewer |

**다중 스택 (모노레포·풀스택)**: 모두 기록하여 `[STACK]=[python-fastapi, ts-next]` 형식으로 전파. reviewer Phase는 파일 변경 기준으로 스택별 분기.

**저장 위치**: 오케스트레이터 메모리. 같은 세션 내 재호출 시 재감지 불필요. `docs/specs/{feature}/spec.md` 헤더에도 기록 권장.

---

## 팬아웃 트리거 표 (축 B+C 활성 조건)

기본은 단일 라인 (각 Phase 1개 agent). 다음 조건일 때만 같은 Phase 내 병렬 팬아웃 활성:

| Phase | 팬아웃 트리거 | 호출 패턴 |
|-------|----------------|-----------|
| Phase 1 (planner) | spec 페이지 ≥ 5 OR 시스템 아키텍처 결정 OR 사용자 `정밀 설계` 명시 | architect ×2 (다른 제약) + code-architect 병렬 → planner 통합 |
| Phase 2 (implementer) | UI/시각 디자인 작업 + 사용자 `디자인 정밀` 명시 | gan-design generator/evaluator 루프 |
| Phase 3 (reviewer) | **항상** 1차 스펙 검증 후 2차 팬아웃 (기본 동작) | stack-reviewer + (조건부 security-reviewer) + code-reviewer 병렬 |
| Phase 4 (qa) | 독립 모듈 ≥ 3개 검증 필요 | dispatching-parallel-agents 패턴 |

**팬아웃 호출 형식 (오케스트레이터가 동일 메시지에서 다중 Agent 호출)**:

```
# 같은 응답 안에서 N개 Agent 도구를 병렬 호출
Agent(subagent_type="general-purpose", description="...", prompt="...")
Agent(subagent_type="general-purpose", description="...", prompt="...")
Agent(subagent_type="general-purpose", description="...", prompt="...")
```

**비용 인식**: 팬아웃 1회 = 토큰 N배. 트리거 조건 외에서는 호출 금지.

---

## subagent 호출 형식 (필수)

원본은 Claude Code `Agent(...)` 양식으로 작성한다. `setup -Opencode` 변환이
opencode/devai 의 `task(...)` 호출로 자동 변환한다:

```
Agent(
  subagent_type="general-purpose",
  description="<3~5단어 작업 요약>",
  prompt="""
  [역할] .claude/agents/<agent-name>.md 를 먼저 읽고 그 정의대로 행동할 것.

  [GOAL] <성공 기준>
  [INPUT] <파일 경로 + 컨텍스트>
  [OUTPUT] <기대 산출물 경로>
  [CONSTRAINT] <제약>
  [IN-SCOPE] / [OUT-SCOPE]
  """
)
```

**변환 결과 (opencode/devai 실행 형식)**:

```
task(
  subagent_type="<agent-name>",
  load_skills=[<agent 기본 skill>],
  description="<3~5단어>",
  prompt="[역할] .opencode/agents/<agent-name>.md ..."
)
```

- **subagent_type 결정**: 변환기가 prompt 첫 줄의 `.../agents/<name>.md` 에서 실제 agent 이름을 추출하여 `subagent_type` 에 넣는다. devai 는 `general-purpose` 가 아니라 **실제 등록된 agent 이름**(planner·implementer·reviewer·qa 등)을 요구하므로, **prompt 첫 줄에 `agents/<정확한 이름>.md` 를 반드시 명시**한다.
- **load_skills 자동 주입**: 변환기가 agent 별 기본 skill 을 채운다 — `planner → speckit-specify/plan/tasks`, `implementer → speckit-implement`. 그 외 agent 는 빈 배열이며, 추가 skill 이 필요하면 호출 시 `load_skills` 에 직접 명시(예: implementer 가 `ecc/python-patterns` 필요 시).
- **opencode/devai 에서 직접 호출 시**: 위 `task(...)` 형식을 그대로 도구 호출로 실행한다. 텍스트로만 적지 말 것.
- `model` 파라미터 미지정 — agent frontmatter 의 `model: ABCLab/[KTDS] Qwen...` 이 적용됨

---

## Phase 1: 명세·계획·태스크 (planner)

**원칙**: speckit 순서 `specify → plan → tasks` 절대 준수. 각 단계 산출물에 사용자 게이트.
**게이트 소유권**: 사용자 승인 게이트는 **오케스트레이터 메인 컨텍스트**가 수행 (subagent 는 대화형 확인 불가).
각 게이트는 `AskUserQuestion`(변환 후 STOP 텍스트)으로 "승인 / 수정 / 중단" 제시. **승인 없이 다음 단계 진입 금지.**

### Phase 1a — 명세 (specify)

planner 에이전트 호출:

```
Agent(
  subagent_type="general-purpose",
  description="spec 작성",
  prompt="""
  [역할] .claude/agents/planner.md 정의대로 행동.
  [GOAL] 요청 기능의 spec.md 작성 — speckit-specify 절차 준수
  [INPUT] 기능 설명 + .specify/memory/constitution.md (있으면)
  [OUTPUT] docs/specs/{feature}/spec.md
  [CONSTRAINT] 요구사항 모호 시 가정 명시 + 옵션 제시 (사용자 질의는 메인이 전달)
  """
)
```
→ 🚦 **GATE 1**: spec.md 요약 제시 → 사용자 승인 → 승인 시 Phase 1b

### Phase 1b — 계획 (plan)

planner 에이전트 호출:

```
Agent(
  subagent_type="general-purpose",
  description="plan 작성",
  prompt="""
  [역할] .claude/agents/planner.md 정의대로 행동.
  [GOAL] plan.md 작성 — speckit-plan 절차. 팬아웃 트리거 충족 시 architect ×2 + code-architect 병렬 후 trade-off 통합
  [INPUT] docs/specs/{feature}/spec.md + [STACK]
  [OUTPUT] docs/specs/{feature}/plan.md
  """
)
```
→ 🚦 **GATE 2**: plan.md 요약 제시 → 사용자 승인 → 승인 시 Phase 1c

### Phase 1c — 태스크 (tasks)

planner 에이전트 호출:

```
Agent(
  subagent_type="general-purpose",
  description="tasks 분해",
  prompt="""
  [역할] .claude/agents/planner.md 정의대로 행동.
  [GOAL] tasks.md 작성 — speckit-tasks 절차. RED→GREEN→REFACTOR 단계 명시, 첫 태스크는 테스트 작성
  [INPUT] docs/specs/{feature}/plan.md + spec.md
  [OUTPUT] docs/specs/{feature}/tasks.md
  """
)
```
→ 🚦 **GATE 3 (BLOCKING · 필수)**: tasks.md 요약 제시 → 사용자 승인.
  승인 시 메인 컨텍스트가 tasks.md 끝줄에 `<!-- APPROVED -->` 마커 삽입 → Phase 2.
  **이 승인 없이는 Phase 2 구현 절대 진입 금지.**

---

## Phase 2: 구현 (implementer)

**전제 (BLOCKING)**: tasks.md 끝줄 `<!-- APPROVED -->` 마커 확인. 없으면 Phase 1c 게이트 재실행.

implementer 에이전트 호출:

```
Agent(
  subagent_type="general-purpose",
  description="implement tasks",
  prompt="""
  [역할] .claude/agents/implementer.md 정의대로 행동.
  [GOAL] tasks.md 의 모든 [ ] 태스크를 TDD 로 구현
  [INPUT] docs/specs/{feature}/tasks.md + spec.md + [STACK]
  [OUTPUT] src/ 코드, tests/ 테스트, 업데이트된 tasks.md
  [CONSTRAINT]
    - 태스크 단위 구현, 완료마다 [x] 갱신
    - 테스트 먼저 작성 (RED → GREEN → REFACTOR)
    - 요청 범위 외 코드 수정 금지
    - 이미 [x]인 태스크 재구현 금지 (사용자 명시 요청 시 예외)
    - speckit-implement 절차로 tasks.md 단계별 실행
    - implementer.md 의 스택별 skill 표 + 메타 skill 호출 조건 준수
  """
)
```

**스킬 참조**: 변환 시 `load_skills=["speckit-implement"]` 주입. [STACK] 기반 `ecc/{stack}-patterns`·`ecc/{stack}-testing` 추가 skill 은 prompt 지시로 implementer 가 로드. 상세는 `agents/implementer.md`.

→ 🚦 **GATE 4 (implement 완료)**: 구현 결과 요약(변경 파일 목록·테스트 통과 여부) 제시 → 사용자 승인 후에만 Phase 3 진입.
   옵션: "리뷰 진행(Phase 3) / 구현 수정 요청 / 중단". **승인 없이 Phase 3 진입 금지.**

---

## Phase 3: 리뷰 (Reviewer 1차 + 팬아웃 2차)

**구조**: reviewer가 1차로 스펙 준수만 검증 → 통과 시 2차 팬아웃으로 stack-specific + 보안 + 일반 품질 병렬 리뷰 → reviewer가 통합.

### 3-1) 1차 (단독, 스펙 준수만)

`reviewer` 에이전트 호출:

```
Agent(
  subagent_type="general-purpose",
  description="spec review",
  prompt="""
  [역할] .claude/agents/reviewer.md 정의대로 행동.
  [GOAL] 1차 spec.md 요구사항 전체 커버 검증 + 누락 항목 식별 → 통과 시 2차 팬아웃 라우팅 결정
  [INPUT] 구현 파일 목록 + docs/specs/{feature}/spec.md + [STACK]
  [OUTPUT] 스펙 준수 판정 + 팬아웃 라우팅 결정 (어떤 stack-reviewer 호출할지)
  """
)
```

- 스펙 미달 → implementer 재호출 (Phase 2)
- 스펙 통과 → 3-2 진입

### 3-2) 2차 팬아웃 (병렬, 코드 품질)

**같은 메시지에서 다중 Agent 호출** ([STACK] + 변경 파일 패턴 기준 라우팅):

| 조건 | 호출 agent | 역할 |
|------|------------|------|
| `[STACK]=python-fastapi` 변경 파일 | `fastapi-reviewer` | async·DI·Pydantic·OpenAPI |
| `[STACK]=python` 변경 파일 | `python-reviewer` | PEP8·타입힌트·Pythonic·보안 |
| `[STACK]∈{java, java-spring}` 변경 파일 | `java-reviewer` | 레이어·JPA·트랜잭션 |
| `[STACK]∈{typescript, ts-next, javascript}` 변경 파일 | `typescript-reviewer` | 타입안전·async·Node/web 보안 |
| auth·token·secret·SQL·외부호출·crypto·SSRF 키워드 변경 | `security-reviewer` | OWASP·시크릿·인젝션 |
| 항상 (스택 무관 일반 품질) | `code-reviewer` | 품질·유지보수성·재사용 |

호출 형식 (예: Python + 인증 코드 변경):
```
Agent(subagent_type="general-purpose", description="python review", prompt="[역할] .claude/agents/python-reviewer.md ...")
Agent(subagent_type="general-purpose", description="security review", prompt="[역할] .claude/agents/security-reviewer.md ...")
Agent(subagent_type="general-purpose", description="general review", prompt="[역할] .claude/agents/code-reviewer.md ...")
```

각 호출에 `superpowers/requesting-code-review` 형식 적용 (자체 포함 컨텍스트·명확 출력 명세).

### 3-3) 통합 (reviewer가 머지)

reviewer가 모든 결과 수집 후:

1. **이슈 dedupe**: 같은 파일·라인 다중 보고 → 1개 이슈로 병합, **severity boost** (LOW×2 → MEDIUM, MEDIUM×2 → HIGH)
2. **충돌 처리**: 같은 라인 상충 권고 (예: 한 reviewer는 "유지", 다른 reviewer는 "수정") → 사용자 결정 요청 (`AskUserQuestion`)
3. **최종 판정**:
   - CRITICAL ≥ 1 또는 HIGH ≥ 1 → 블로킹
   - 모두 MEDIUM/LOW → 통과
4. **`superpowers/receiving-code-review` 적용**: implementer 재호출 시 이슈 우선순위·재현 경로·기대 수정 명시

→ 🚦 **GATE 5 (review 완료)**: 통합 리뷰 결과(이슈 목록·심각도·판정) 제시 → 사용자 승인 후에만 다음 진행.
   - 블로킹(CRITICAL/HIGH): "implementer 재호출(Phase 2) / 이대로 진행 / 중단"
   - 통과(MEDIUM/LOW): "qa 진행(Phase 4) / 추가 리뷰 / 중단"
   **승인 없이 Phase 4 진입 또는 implementer 재호출 금지.**

---

## Phase 4: QA

`qa` 에이전트 호출:

```
Agent(
  subagent_type="general-purpose",
  description="qa verify",
  prompt="""
  [역할] .claude/agents/qa.md 정의대로 행동.
  [GOAL] 통합 정합성 + 엣지 케이스 + spec.md 성공 기준 검증
  [INPUT] 구현 모듈 + docs/specs/{feature}/spec.md 성공 기준 + [STACK]
  [OUTPUT] 통과/실패 보고서 + 재현 경로
  [CONSTRAINT]
    - superpowers/verification-before-completion 체크리스트 적용
    - [STACK]=java-spring 일 경우 ecc/springboot-verification 참조
    - 실패 재현 안됨 → superpowers/systematic-debugging 적용
    - qa.md 위임/팬아웃 매트릭스 준수
  """
)
```

**팬아웃 옵션 (조건부)**: 독립 모듈 ≥ 3개 검증 시 qa가 `superpowers/dispatching-parallel-agents` 패턴으로 모듈별 병렬 호출.

→ 🚦 **GATE 6 (qa 완료)**: QA 결과(통과/실패·재현 경로) 제시 → 사용자 승인 후에만 다음 진행.
   - 실패: "implementer 재호출(Phase 2) / 이대로 진행 / 중단"
   - 통과: "완료 처리(Phase 5) 진행 / 추가 검증 / 중단"
   **승인 없이 Phase 5 진입 또는 implementer 재호출 금지.**

---

## Phase 5: 완료

**전제**: GATE 6 (qa 완료) 사용자 승인 통과 후에만 진입.

1. `docs/changelog/YYYY-MM-DD-feat-{feature}.md` 변경 이력 기록
2. **`doc-updater` agent 호출** — README·docs/CODEMAPS/* 동기화 (`/update-codemaps`, `/update-docs`)
3. → 🚦 **GATE 7 (PR · BLOCKING)**: `docs/rules/06-branch-strategy.md` 따라 PR 준비. 커밋·브랜치 생성·push·PR 생성은 각각 사용자 명시 승인 필수 (CLAUDE.md Rule 3). **승인 없이 commit/push/PR 금지.**
4. 사용자에게 완료 보고 (정상 작성 — caveman 제외)

doc-updater 호출 형식:
```
Agent(
  subagent_type="general-purpose",
  description="docs sync",
  prompt="[역할] .claude/agents/doc-updater.md 정의대로 행동.
  [GOAL] 이번 기능 추가에 따른 README·CODEMAP·docs 동기화
  [INPUT] 변경 파일 목록 + docs/specs/{feature}/spec.md + changelog 항목
  [OUTPUT] 갱신된 README·docs/CODEMAPS/*"
)
```

---

## 에러 핸들링

원칙: 에이전트 1회 실패 → 컨텍스트 보강 후 1회 재시도. 2회 실패 또는 Phase 2-4 루프 3회 초과 → 사용자 에스컬레이션(스코프 축소 / 태스크 분해 / 중단). 한 Phase 전체 실패 → 후속 중단·누락 보고. 상충 산출물은 삭제 금지(출처 병기 보존).
상세: `docs/rules/07-error-recovery.md`

---

## 출력 스타일

caveman 출력 규칙은 `CLAUDE.md` Rule 8 + opencode plugin(`harness-rules.js`)이 담당. 게이트(사용자 확인)·진행 diff/요약·에러 에스컬레이션은 정상 문장으로 작성(caveman 예외). 내부 에이전트 간 통신은 정상 처리.
