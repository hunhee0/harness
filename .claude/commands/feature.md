---
description: SDD 기능 개발 단일 진입점. specify→plan→tasks→implement 10-step deterministic 흐름 강제. 자율 분기 제거, 모델이 약해도 작동. "기능 만들어줘", "구현해줘", "새 기능", "스펙 작성", "이어서 진행", "재실행" 등의 요청 시 반드시 이 커맨드를 사용한다.
argument-hint: <기능 설명> | resume | continue
---

# /feature — Deterministic 기능 개발 진입점

> **목적**: `harness-orchestrator` 스킬의 자율 분기를 제거하고, 모델이 따라야 할 STEP을 명령형으로 고정.
> 모델이 약할수록(Qwen 등) "자율 판단"을 줄여야 신뢰도가 올라간다.
> 이 커맨드는 다음 STEP을 순서대로만 실행한다. 분기·건너뛰기·재해석 금지.

---

## 사용법

```
/feature 사용자 로그인 기능 만들어줘     # 신규
/feature resume                            # docs/specs/* 미완료 이어서
/feature continue                          # resume 동의어
```

---

## STEP 0 — 현재 상태 분류 (반드시 첫 실행)

다음 명령으로 상태 확인:

1. `Glob`으로 `docs/specs/*/tasks.md` 검색
2. 매칭 결과 있으면 각 `tasks.md` 읽기 → `[ ]` 미완료 개수 카운트
3. 사용자 인자 (`<설명>` vs `resume`/`continue`) 확인
4. 분류표에 따라 진입 STEP 결정:

| 결과 | 진입 STEP |
|------|-----------|
| `docs/specs/` 비어있음 OR 신규 기능 설명 인자 | **STEP 1** (specify) |
| `tasks.md`에 `[ ]` 존재 + 사용자 `resume`/`continue`/"이어서" | **STEP 7** (implement) — Phase 1 건너뜀 |
| 모든 `[x]` + 새 기능 인자 아님 | "이미 완료됨" 보고 후 **종료** |
| reviewer/qa 지적 후 부분 재실행 요청 | **STEP 7**부터 (수정 범위만) |

STEP 0 결과를 사용자에게 1-2줄 보고 후 결정된 STEP 진입.

---

## STEP 0.5 — 스택 감지 (1회, `[STACK]` 변수에 저장)

다음 파일을 `Glob`으로 확인:

| 발견 파일 | `[STACK]` 값 |
|-----------|--------------|
| `pyproject.toml`/`requirements.txt` + FastAPI 임포트 | `python-fastapi` |
| `pyproject.toml`/`requirements.txt` | `python` |
| `pom.xml`/`build.gradle` + Spring 의존성 | `java-spring` |
| `pom.xml`/`build.gradle` | `java` |
| `package.json` + `next.config.*` | `ts-next` |
| `package.json` + `*.tsx`/`*.ts` | `typescript` |
| `package.json` (js만) | `javascript` |

다중 스택 (모노레포) 가능: `[STACK]=[python-fastapi, ts-next]` 형식.

이후 모든 subagent 호출 시 `[STACK]` 컨텍스트에 포함.

---

## STEP 1 — `/speckit-specify` 실행 (메인 컨텍스트)

**명령형**: 메인 컨텍스트에서 직접 `/speckit-specify <기능 설명>` 호출.

- 절대 subagent에 위임 금지 — `[NEEDS CLARIFICATION]` 대화형 질의가 메인에서만 가능
- `.specify/memory/constitution.md` 존재 시 먼저 읽음
- 산출물: `docs/specs/{feature}/spec.md`

완료 → **STEP 2**.

---

## STEP 2 — STOP · GATE 1 (사용자 승인 필수)

다음 텍스트 출력 후 **반드시 멈춤**. 응답 수신 전 STEP 3 진입 금지.

```
🚦 GATE 1 — spec.md 작성 완료

요약:
  - 기능: <한 줄>
  - 핵심 요구사항: <3-5 bullet>
  - 성공 기준: <2-3 bullet>

다음 중 입력하세요:
  1) 승인 (다음 단계: plan)
  2) 수정 — 어디를?
  3) 중단
```

사용자 응답 처리:
- `1` / `승인` / `approve` → **STEP 3**
- `2` / `수정 ...` → spec.md 해당 부분만 surgical 수정 → STEP 2 재출력
- `3` / `중단` → **종료**

---

## STEP 3 — `/speckit-plan` 실행 (메인 컨텍스트)

**명령형**: 메인 컨텍스트에서 `/speckit-plan` 호출.

**팬아웃 트리거** (모두 OR — 충족 시에만):
- spec 페이지 ≥ 5
- 사용자 명시 `"정밀 설계"` / `"여러 안 비교"`
- 시스템 통합 포인트 ≥ 3

팬아웃 충족 시: 같은 응답에서 architect ×2 (제약 다르게) + code-architect 병렬 호출 → trade-off 표 → 사용자 선택 → 선택안만 `plan.md`.
미충족 시: 단일 plan.

산출물: `docs/specs/{feature}/plan.md`

완료 → **STEP 4**.

---

## STEP 4 — STOP · GATE 2 (사용자 승인 필수)

```
🚦 GATE 2 — plan.md 작성 완료

요약:
  - 아키텍처: <한 줄>
  - 핵심 결정: <2-3 bullet>
  - 데이터 흐름: <한 줄>

다음 중 입력:
  1) 승인 (다음 단계: tasks)
  2) 수정 — 어디를?
  3) 중단
```

응답 수신 전 STEP 5 진입 금지.

---

## STEP 5 — `/speckit-tasks` 실행 (메인 컨텍스트)

**명령형**: 메인 컨텍스트에서 `/speckit-tasks` 호출.

- 각 태스크는 독립 검증 가능 단위
- TDD 구조 강제: RED → GREEN → REFACTOR 단계 명시
- 첫 태스크는 반드시 "테스트 작성"
- 산출물: `docs/specs/{feature}/tasks.md`

완료 → **STEP 6**.

---

## STEP 6 — STOP · GATE 3 (BLOCKING · 사용자 승인 필수)

```
🚦 GATE 3 (BLOCKING) — tasks.md 작성 완료

태스크 수: N개
TDD 구조: RED <n1> / GREEN <n2> / REFACTOR <n3>
의존성: <순차 vs 병렬 가능 그룹>

다음 중 입력:
  1) 승인 (구현 진입)
  2) 수정 — 어떤 태스크?
  3) 중단
```

**이 승인 없이 STEP 7 절대 진입 금지.**

승인 응답 후 처리:
1. `tasks.md` 끝줄에 `<!-- APPROVED -->` 마커 삽입 (plugin 게이트 검증용)
2. **STEP 7** 진입

---

## STEP 7 — implementer subagent 호출 (`/speckit-implement` 실행)

**전제 (BLOCKING)**: `tasks.md` 끝줄에 `<!-- APPROVED -->` 마커 확인. 없으면 STEP 6으로 되돌림.

`implementer` 에이전트 호출 (Claude Code 기준 — opencode는 setup.ps1이 자동 변환):

```
Agent(
  subagent_type="general-purpose",
  description="implement tasks",
  prompt="[역할] .claude/agents/implementer.md 정의대로 행동.
  [GOAL] tasks.md의 모든 [ ] 태스크를 TDD로 구현
  [INPUT] docs/specs/{feature}/tasks.md + spec.md + [STACK]={감지값}
  [OUTPUT] src/ 코드, tests/ 테스트, 업데이트된 tasks.md (체크박스)
  [CONSTRAINT]
    - 태스크 단위로 구현, 완료마다 [x] 갱신
    - 테스트 먼저 작성 (RED → GREEN → REFACTOR)
    - 요청 범위 외 코드 수정 금지
    - 이미 [x]인 태스크 재구현 금지 (사용자 명시 요청 시 예외)
    - /speckit-implement 로 tasks.md 단계별 실행
    - implementer.md 의 스택별 skill 표 + 메타 skill 게이트 준수"
)
```

완료 → **STEP 8**.

---

## STEP 8 — reviewer subagent 호출 (1차 + 팬아웃 2차 + 통합 3차)

`reviewer` 에이전트 호출:

```
Agent(
  subagent_type="general-purpose",
  description="spec + quality review",
  prompt="[역할] .claude/agents/reviewer.md 정의대로 행동.
  [GOAL]
    1차: spec.md 요구사항 전체 커버 검증
    2차: stack-specific + (조건부 보안) + 일반 품질 팬아웃
    3차: 결과 dedupe + severity boost + 충돌 처리 → 통합 판정
  [INPUT] 변경 파일 목록 + docs/specs/{feature}/spec.md + [STACK]={감지값}
  [OUTPUT] 통합 이슈 목록 (심각도별) + 통과/블로킹 판정
  [CONSTRAINT]
    - 1차 미달 시 2차 진입 금지 (즉시 STEP 7 재호출)
    - 2차 팬아웃은 같은 응답에서 N개 Agent 도구 병렬 호출
    - 충돌은 reviewer 단독 결정 금지 — 사용자에게 텍스트로 묻기"
)
```

reviewer 결과 처리:
- CRITICAL ≥ 1 OR HIGH ≥ 1 → **STEP 7 재호출** (지적 사항만 수정)
- 모두 MEDIUM/LOW → **STEP 9**

---

## STEP 9 — qa subagent 호출

`qa` 에이전트 호출:

```
Agent(
  subagent_type="general-purpose",
  description="qa verification",
  prompt="[역할] .claude/agents/qa.md 정의대로 행동.
  [GOAL] 통합 정합성 + 엣지 케이스 + spec 성공 기준 충족 검증
  [INPUT] 구현 모듈 + docs/specs/{feature}/spec.md + [STACK]={감지값}
  [OUTPUT] QA 보고서 (통과/실패 + 재현 경로)
  [CONSTRAINT]
    - superpowers/verification-before-completion 체크리스트 적용
    - [STACK]=java-spring 일 경우 ecc/springboot-verification 참조
    - 실패 재현 안됨 → superpowers/systematic-debugging 적용
    - qa.md 위임/팬아웃 매트릭스 준수
    - 독립 모듈 ≥ 3개 시 같은 응답에서 모듈별 병렬 Agent 호출"
)
```

qa 결과 처리:
- 실패 → **STEP 7 재호출** (재현 경로 따라 정확한 위치만 수정 + 회귀 테스트 추가)
- 통과 → **STEP 10**

---

## STEP 10 — 완료 처리

순서대로 실행:

1. `docs/changelog/YYYY-MM-DD-feat-{feature}.md` 생성 (오늘 날짜 기준)
2. `doc-updater` subagent 호출:

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

3. 사용자에게 완료 보고 (caveman 제외, 정상 작성):
   - 추가된 기능 1줄 요약
   - 변경 파일 수
   - 테스트 통과 여부
   - 다음 액션 제안 (예: PR 준비, 추가 기능, 종료)

4. (사용자 요청 시) `docs/rules/06-branch-strategy.md` 따라 PR 준비

---

## 에러 처리 (모든 STEP 공통)

| 상황 | 조치 |
|------|------|
| 어떤 STEP 1회 실패 | 컨텍스트 보강하여 1회 재시도 |
| 2회 실패 | 에스컬레이션: 사용자에게 현상 + 옵션 (스코프 축소 / 분해 / 중단) |
| STEP 7-9 루프 3회 초과 | 즉시 사용자 에스컬레이션 |
| 상충 산출물 발견 | 삭제 금지 — 출처 병기하여 보존 (`spec.prev.md` 등) |
| 사용자 "수정" 응답 | 해당 STEP만 surgical 재실행, 무관 부분 건드리지 않음 |
| 사용자 "중단" 응답 | 즉시 종료, 산출물 보존 |

---

## 자율 분기 금지 사항 (모델에게 강제)

이 커맨드는 다음을 **절대 금지**:

- ❌ STEP 건너뛰기 (예: GATE 2 없이 STEP 5 진입)
- ❌ STOP 게이트 우회 (사용자 응답 없이 다음 STEP)
- ❌ subagent에 GATE 위임 (subagent는 사용자 인터랙션 불가)
- ❌ 자체적으로 "이미 명확하니 GATE 생략" 결정
- ❌ Phase 1 (specify/plan/tasks)을 subagent에 위임 (메인 컨텍스트 전용)

분기 의심 시 사용자에게 묻는다. 답 없이 진행 금지.

---

## 환경별 호출 형식 차이

이 파일은 **Claude Code 기준 `Agent(...)` syntax**로 작성됨.
`setup.ps1 -Opencode` 모드는 빌드 시 다음 변환을 자동 적용:

| Claude Code | opencode 변환 결과 |
|-------------|---------------------|
| `Agent(subagent_type="general-purpose", description="X", prompt="Y")` | `` `task` 도구로 subagent 호출:` `` (description=X, prompt=Y) |
| `AskUserQuestion(...)` | `STOP(텍스트 응답 대기)` |
| `.claude/agents/foo.md` | `.opencode/agent/foo.md` |

따라서 원본은 한 형식으로 유지, 두 환경 모두 지원.
