---
name: harness-orchestrator
description: 이 프로젝트의 기능 개발 파이프라인 진입점. "기능 만들어줘", "구현해줘", "개발 시작", "새 기능 추가", "스펙 작성해줘", "태스크 분해", "이어서 진행", "다시 구현", "개발 재개", "재실행", "업데이트", "수정", "보완", "결과 개선", "feature 보완" 등 기능 개발·수정·보완 요청 시 반드시 이 스킬을 사용할 것. planner → implementer → reviewer → qa 에이전트 파이프라인을 통해 SDD 워크플로우를 강제한다.
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

## Agent 도구 호출 형식 (필수)

모든 에이전트 호출은 `Agent` 도구로 수행하며 다음 양식 준수:

```
Agent(
  subagent_type="general-purpose",   # qa는 반드시 general-purpose, 그 외도 동일 권장
  description="<3~5단어 작업 요약>",
  prompt="""
  [역할] .claude/agents/{agent-name}.md 를 먼저 읽고 그 정의대로 행동할 것.

  [GOAL] <성공 기준>
  [INPUT] <파일 경로 + 컨텍스트>
  [OUTPUT] <기대 산출물 경로>
  [CONSTRAINT] <제약>
  [IN-SCOPE] / [OUT-SCOPE]
  """
)
```

- `model` 파라미터 미지정 — 사내 로컬 LLM이 기본값으로 적용됨
- `subagent_type`은 사용 환경에 정의된 일반 타입 사용. 에이전트 역할은 prompt 내 `.claude/agents/{name}.md` 참조로 위임

---

## Phase 1: 기능 명세 (SDD — 게이트는 오케스트레이터 메인 컨텍스트가 소유)

**원칙**: speckit 순서 `specify → plan → tasks → implement` 절대 준수.
spec/plan/tasks 3개 사용자 확인 게이트는 **오케스트레이터 메인 컨텍스트**에서 수행한다.

- 서브에이전트(Agent 도구)는 대화형 사용자 확인 불가 → 게이트를 에이전트 안에 두지 말 것
- `/speckit-specify`는 내부 [NEEDS CLARIFICATION] 사용자 질의 때문에 **반드시 메인 컨텍스트에서 직접 실행**
- 각 게이트는 `AskUserQuestion`으로 제시 (예: "승인 — 다음 단계" / "수정 요청 — 어디를" / "중단"). **승인 없이 다음 단계 진입 금지.**

### Phase 1a — 명세 (specify)

1. `.specify/memory/constitution.md` 읽기 (있을 경우)
2. 메인 컨텍스트에서 `/speckit-specify` 실행 → `docs/specs/{feature}/spec.md`
3. (요구사항 모호 시) planner 위임 매트릭스의 `superpowers/brainstorming` 참조
4. 🚦 **GATE 1**: spec.md 요약 제시 → 사용자 확인 → 승인 시 Phase 1b

### Phase 1b — 계획 (plan)

1. 메인 컨텍스트에서 `/speckit-plan` 실행 → `docs/specs/{feature}/plan.md`
2. (팬아웃 트리거 충족 시) planner가 같은 메시지에서 architect ×2 + code-architect 병렬 호출 후 trade-off 표로 통합. 상세는 `agents/planner.md`.
3. 🚦 **GATE 2**: plan.md 요약 제시 → 사용자 확인 → 승인 시 Phase 1c

### Phase 1c — 태스크 (tasks)

1. 메인 컨텍스트에서 `/speckit-tasks` 실행 → `docs/specs/{feature}/tasks.md`
2. 🚦 **GATE 3 (BLOCKING · 필수)**: tasks.md 요약 제시 → 사용자 확인.
   **이 승인 없이는 Phase 2 구현 절대 진입 금지.** → 승인 시에만 Phase 2.

---

## Phase 2: 구현 (Implementer — /speckit-implement)

**전제 (BLOCKING)**: Phase 1c GATE 3 (tasks.md 사용자 승인) 통과 필수. 미승인 시 진입 금지.
**메커니즘**: 구현은 `/speckit-implement`로 수행 (tasks.md `[ ]` 단계별 실행·`[X]` 갱신). implementer가 이 명령을 실행하고 TDD·Verification Loop를 적용.

`implementer` 에이전트 호출:

```
[GOAL] tasks.md의 모든 [ ] 태스크를 TDD로 구현
[INPUT] docs/specs/{feature}/tasks.md + spec.md + [STACK]
[OUTPUT] src/ 코드, tests/ 테스트, 업데이트된 tasks.md
[CONSTRAINT]
  - 태스크 단위 구현, 완료마다 [x] 업데이트
  - 테스트 먼저 작성 (RED → GREEN → REFACTOR)
  - 요청 범위 외 코드 수정 금지
  - 이미 [x]인 태스크 재구현 금지 (사용자 명시 요청 시 예외)
  - implementer.md 의 스택별 skill 표 + 메타 skill 호출 조건 준수
  - /speckit-implement 로 tasks.md 실행 (단계별·TDD 순서)
```

**스킬 참조 (자동)**: [STACK] 기반으로 implementer가 `ecc/{stack}-patterns`, `ecc/{stack}-testing` 또는 `superpowers/test-driven-development` 참조. 구현 막힘 시 `superpowers/systematic-debugging`. 완료 직전 `superpowers/verification-before-completion` 체크리스트 적용. 상세는 `agents/implementer.md`.

---

## Phase 3: 리뷰 (Reviewer 1차 + 팬아웃 2차)

**구조**: reviewer가 1차로 스펙 준수만 검증 → 통과 시 2차 팬아웃으로 stack-specific + 보안 + 일반 품질 병렬 리뷰 → reviewer가 통합.

### 3-1) 1차 (단독, 스펙 준수만)

`reviewer` 에이전트 호출:

```
[GOAL] spec.md 요구사항 전체 커버 + 누락 항목 식별
[INPUT] 구현 파일 목록 + docs/specs/{feature}/spec.md + [STACK]
[OUTPUT] 스펙 준수 판정 + 팬아웃 라우팅 결정 (어떤 stack-reviewer 호출할지)
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
   - CRITICAL ≥ 1 또는 HIGH ≥ 1 → 블로킹, implementer 재호출
   - 모두 MEDIUM/LOW → 통과, Phase 4 진입
4. **`superpowers/receiving-code-review` 적용**: implementer 재호출 시 이슈 우선순위·재현 경로·기대 수정 명시

---

## Phase 4: QA

`qa` 에이전트 호출:

```
[GOAL] 통합 정합성 + 엣지 케이스 검증
[INPUT] 구현 모듈 + spec.md 성공 기준 + [STACK]
[OUTPUT] 통과/실패 보고서 + 재현 경로
[CONSTRAINT]
  - superpowers/verification-before-completion 체크리스트 적용
  - [STACK]=java-spring 일 경우 ecc/springboot-verification 참조
  - 실패 재현 안됨 → superpowers/systematic-debugging 적용
  - qa.md 위임/팬아웃 매트릭스 준수
```

**팬아웃 옵션 (조건부)**: 독립 모듈 ≥ 3개 검증 시 qa가 `superpowers/dispatching-parallel-agents` 패턴으로 모듈별 병렬 호출.

- 실패 → implementer 재호출 (Phase 2)
- 통과 → Phase 5

---

## Phase 5: 완료

1. `docs/changelog/YYYY-MM-DD-feat-{feature}.md` 변경 이력 기록
2. **`doc-updater` agent 호출** — README·docs/CODEMAPS/* 동기화 (`/update-codemaps`, `/update-docs`)
3. `docs/rules/06-branch-strategy.md` 따라 PR 준비
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

**원칙**: 1회 재시도 → 재실패 시 해당 결과 없이 진행 + 사용자에게 누락 명시.

| 상황 | 조치 |
|------|------|
| 에이전트 1회 실패 | 컨텍스트 보강하여 1회 재시도 |
| 에이전트 2회 실패 | 에스컬레이션: 사용자에게 현상 + 옵션 (스코프 축소 / 분해 / 중단) 제시 |
| 한 Phase 전체 실패 | 후속 Phase 진행 중단, 누락 명시하여 보고 |
| 상충 산출물 | 삭제 금지 — 출처 병기하여 보존 |
| Phase 2-4 루프 3회 초과 | 즉시 사용자 에스컬레이션 |

상세: `docs/rules/07-error-recovery.md`

---

## 출력 스타일 (caveman 경계)

사용자 보고 출력 시 caveman lite 적용 **제외**:
- Phase 시작·종료 알림
- 사용자 확인 요청 (옵션 포함)
- 진행 산출물 diff/요약 보고
- 에러 에스컬레이션 메시지

이유: `CLAUDE.md` Rule 8의 "변경 diff/요약 / question 옵션" 예외 조항에 해당.
내부 에이전트 간 통신은 정상 처리.

---

## 테스트 시나리오

**정상 흐름 (FastAPI 로그인 신규)**:
"사용자 로그인 기능 만들어줘"
→ Phase 0: `docs/specs/` 없음 → 신규
→ Phase 0.5: `pyproject.toml` + FastAPI 임포트 → `[STACK]=python-fastapi`
→ Phase 1a: /speckit-specify → spec.md → 🚦 GATE 1 (사용자 확인)
→ Phase 1b: /speckit-plan → plan.md → 🚦 GATE 2 (사용자 확인)
→ Phase 1c: /speckit-tasks → tasks.md → 🚦 GATE 3 BLOCKING (사용자 확인)
→ Phase 2: implementer가 /speckit-implement 실행 (ecc/fastapi-patterns·ecc/python-testing 참조, TDD)
→ Phase 3-1: reviewer (스펙 준수 검증, 통과)
→ Phase 3-2: 팬아웃 3개 병렬 — fastapi-reviewer + security-reviewer (auth 키워드) + code-reviewer
→ Phase 3-3: reviewer 통합 (dedupe → 통과)
→ Phase 4: qa (verification-before-completion 체크, 통과)
→ Phase 5: changelog + doc-updater + PR 준비 → 완료

**에러 흐름 (팬아웃 다관점 보안 지적)**:
Phase 3-2 fastapi-reviewer는 LOW, security-reviewer는 CRITICAL(SQL 인젝션) 보고
→ reviewer 통합: CRITICAL 1개 → 블로킹
→ implementer 재호출 (security-reviewer 리포트만 우선) → 수정 → Phase 3 재진입 → 통과 → qa

**큰 기능 + 팬아웃 (Phase 1)**:
"결제 시스템 만들어줘" (spec 페이지 8개 예상)
→ Phase 0.5: `[STACK]=python-fastapi + ts-next` (풀스택)
→ Phase 1: planner가 팬아웃 트리거 충족 인식 → architect ×2 (모놀리스 vs 분리) + code-architect 병렬 → trade-off 표 → 사용자 선택 → 선택안만 plan.md
→ Phase 2 이하 동일

**재개 흐름**:
"이어서 진행"
→ Phase 0: `tasks.md`에 `[ ]` 5개 발견 → 재개
→ Phase 0.5: 이전 spec.md 헤더의 [STACK] 재사용
→ Phase 2 진입 (planner 우회) → 이하 동일

**부분 재실행 흐름**:
"reviewer가 지적한 보안 이슈만 수정해줘"
→ Phase 0: 모든 `[x]` 이나 사용자 명시 수정 요청 → 부분 재실행
→ implementer만 호출 (security-reviewer 리포트 기반 해당 파일 수정) → Phase 3 (security-reviewer만 재호출 → 통과) → qa

**3회 초과 에스컬레이션**:
Phase 2-4 루프 3회 후에도 통과 못함 → 사용자에게 현상 + 옵션 (스코프 축소 / 태스크 분해 / 임시 중단) 제시
