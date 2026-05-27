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

## Phase 1: 기능 명세 (Planner)

`planner` 에이전트 호출:

```
[GOAL] 기능 설명을 spec.md → plan.md → tasks.md 로 변환
[INPUT] 사용자가 요청한 기능 설명 + .specify/memory/constitution.md
[OUTPUT] docs/specs/{feature}/tasks.md 완성
[CONSTRAINT]
  - constitution.md 먼저 읽을 것 (있을 경우)
  - 각 단계 완료 후 사용자 확인 필수
  - 스펙 없이 tasks 생성 금지
[IN-SCOPE] specify, plan, tasks 생성
[OUT-SCOPE] 코드 작성, 파일 수정
```

planner가 tasks.md 완성 → 사용자 확인 → Phase 2.

---

## Phase 2: 구현 (Implementer)

`implementer` 에이전트 호출:

```
[GOAL] tasks.md의 모든 [ ] 태스크를 TDD로 구현
[INPUT] docs/specs/{feature}/tasks.md + spec.md
[OUTPUT] src/ 코드, tests/ 테스트, 업데이트된 tasks.md
[CONSTRAINT]
  - 태스크 단위 구현, 완료마다 [x] 업데이트
  - 테스트 먼저 작성 (RED → GREEN → REFACTOR)
  - 요청 범위 외 코드 수정 금지
  - 이미 [x]인 태스크 재구현 금지 (사용자 명시 요청 시 예외)
```

---

## Phase 3: 리뷰 (Reviewer)

`reviewer` 에이전트 호출:

```
[GOAL] 스펙 준수 + 코드 품질 검증
[INPUT] 구현 파일 목록 + docs/specs/{feature}/spec.md
[OUTPUT] 심각도별 이슈 목록 + 통과/블로킹 판정
```

- CRITICAL/HIGH 발견 → implementer 재호출 (Phase 2)
- 통과 → Phase 4

---

## Phase 4: QA

`qa` 에이전트 호출:

```
[GOAL] 통합 정합성 + 엣지 케이스 검증
[INPUT] 구현 모듈 + spec.md 성공 기준
[OUTPUT] 통과/실패 보고서 + 재현 경로
```

- 실패 → implementer 재호출 (Phase 2)
- 통과 → Phase 5

---

## Phase 5: 완료

1. `docs/changelog/YYYY-MM-DD-feat-{feature}.md` 변경 이력 기록
2. `docs/rules/06-branch-strategy.md` 따라 PR 준비
3. 사용자에게 완료 보고 (정상 작성 — caveman 제외)

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

**정상 흐름 (신규)**:
"사용자 로그인 기능 만들어줘"
→ Phase 0: `docs/specs/` 없음 → 신규
→ Phase 1: planner(spec/plan/tasks 생성) → 사용자 확인
→ Phase 2: implementer(코드 + 테스트)
→ Phase 3: reviewer(통과)
→ Phase 4: qa(통과)
→ Phase 5: changelog + PR 준비 → 완료

**에러 흐름 (리뷰 블로킹)**:
reviewer에서 HIGH 발견 → implementer 재작업 (1회 재시도) → reviewer 재검토 → 통과 → qa 진행

**재개 흐름**:
"이어서 진행"
→ Phase 0: `tasks.md`에 `[ ]` 5개 발견 → 재개
→ Phase 2 진입 (planner 우회) → 이하 동일

**부분 재실행 흐름**:
"reviewer가 지적한 보안 이슈만 수정해줘"
→ Phase 0: 모든 `[x]` 이나 사용자 명시 수정 요청 → 부분 재실행
→ implementer만 호출 (해당 파일 수정) → reviewer → qa

**3회 초과 에스컬레이션**:
Phase 2-4 루프 3회 후에도 통과 못함 → 사용자에게 현상 + 옵션 (스코프 축소 / 태스크 분해 / 임시 중단) 제시
