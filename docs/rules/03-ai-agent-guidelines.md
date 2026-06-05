# 03-AI 에이전트 사용 가이드라인

**작성일**: 2026-05-14
**최종 수정**: 2026-05-28

---

## 🤖 자원 인벤토리

이 프로젝트에 로컬로 설치된 (또는 통합된) 스킬·에이전트·커맨드 목록입니다.
**가짜 항목은 제거** — 실제 `.claude/` 디렉토리에 존재하는 자원만 기재합니다.

### Speckit (SDD 4단계 + 헌법)

`.claude/skills/speckit-*` — 5개

| 스킬 | 사용 시점 |
|---|---|
| `/speckit-constitution` | 프로젝트 원칙 작성 (.specify/memory/constitution.md) |
| `/speckit-specify` | 새 기능 스펙 작성 |
| `/speckit-plan` | 스펙 기반 구현 계획 |
| `/speckit-tasks` | 태스크 분해 |
| `/speckit-implement` | 태스크 기반 구현 |

### Harness 운영 스킬

`.claude/skills/` — 3개

| 스킬 | 사용 시점 |
|---|---|
| `harness-orchestrator` | 기능 개발·수정·보완 진입점 (planner→implementer→reviewer→qa 자동 조율) |
| `harness-adapt` | 기존 프로젝트 첫 적용·재적응 (코드 분석 후 CLAUDE.md/rules 자동 수정) |
| `caveman` | 응답 토큰 압축 (always-on, hook 강제) |

### ECC — 도메인 패턴·테스트 스킬

`.claude/skills/ecc/` — 21개. `[STACK]` 기반으로 `implementer`/`reviewer` agent가 자동 참조.

| 카테고리 | 스킬 |
|---|---|
| Python | `python-patterns`, `python-testing`, `fastapi-patterns` |
| Java/Spring | `java-coding-standards`, `springboot-patterns`, `springboot-security`, `springboot-tdd`, `springboot-verification`, `jpa-patterns` |
| Frontend | `frontend-patterns`, `frontend-design-direction`, `nextjs-turbopack`, `motion-ui`, `liquid-glass-design`, `ui-demo`, `ui-to-vue`, `frontend-slides` |
| API/대시보드 | `api-design`, `api-connector-builder`, `dashboard-builder` |
| TDD | `tdd-workflow` |

### Superpowers — 메타 워크플로 스킬

`.claude/skills/superpowers/` — 8개. 스택 무관, 트리거 조건 충족 시 적용.

| 스킬 | 사용 시점 |
|---|---|
| `brainstorming` | 요구사항 모호·여러 옵션 도출 |
| `dispatching-parallel-agents` | 독립 도메인 ≥ 2개 병렬 처리 |
| `requesting-code-review` | code review 호출 형식 (자체 포함 컨텍스트·명확 출력) |
| `receiving-code-review` | 받은 리뷰 우선순위·수정 적용 워크플로 |
| `test-driven-development` | TDD 강제 (안티패턴 회피 포함) |
| `systematic-debugging` | 재현 실패·flaky·근본 원인 추적 |
| `verification-before-completion` | 완료 선언 직전 체크리스트 |
| `using-git-worktrees` | 격리된 병렬 분기 작업 |

### Commands — 슬래시 커맨드

`.claude/commands/` — 10개

| 커맨드 | 용도 | 비고 |
|---|---|---|
| `/gan-design` | Generator/Evaluator 디자인 루프 (FE 시각 작업) | implementer가 FE 시안 비교 시 사용 |
| `/loop-start` | 매니지드 자율 루프 시작 | 안전 기본값·종료 조건 |
| `/multi-backend`, `/multi-frontend`, `/multi-plan`, `/multi-workflow` | 외부 멀티모델 (Codex/Gemini wrapper) | **현 in-process 파이프라인 미사용** (참조용) |
| `/python-review` | python-reviewer agent 직접 호출 | reviewer 외 단독 사용 |
| `/test-coverage` | 커버리지 분석·갭 식별·누락 테스트 생성 | qa·tdd-guide가 호출 |
| `/update-codemaps`, `/update-docs` | 코드맵·문서 동기화 | Phase 5에서 doc-updater가 실행 |

---

## 🔧 프로젝트 에이전트 팀 (2계층 구조)

`.claude/agents/` — 15개. `harness-orchestrator`가 L1을 파이프라인 순서로 호출, L1이 조건부로 L2를 위임/팬아웃.

### L1 — 워크플로 에이전트 (파이프라인 골격)

| 에이전트 | 역할 | 입력 | 출력 | Phase |
|---|---|---|---|---|
| `planner` | 스펙·계획·태스크 작성 | 기능 설명 + `[STACK]` | spec/plan/tasks.md | 1 |
| `implementer` | TDD 기반 구현 | tasks.md + `[STACK]` | src/, tests/, 갱신 tasks.md | 2 |
| `reviewer` | 1차 스펙 + 2차 팬아웃 통합 | 구현 파일 + spec.md | 통합 이슈 목록 + 판정 | 3 |
| `qa` | 통합·엣지·E2E | 구현 모듈 + spec.md | QA 보고서 | 4 |

**파이프라인**: `planner → implementer → reviewer → qa` (Phase 0.5 스택 감지 + Phase 5 doc-updater 포함)

### L2 — 전문 에이전트 (조건부 위임)

| 에이전트 | 역할 | 호출 주체 | 호출 조건 |
|---|---|---|---|
| `architect` | 시스템 설계·기술 의사결정 | planner | 시스템 결정 필요 / 큰 기능 팬아웃 |
| `code-architect` | 구현 청사진 (파일·인터페이스·빌드 순서) | planner | plan.md 부록 작성 시 |
| `tdd-guide` | TDD 강제·커버리지 게이트 | planner / implementer / qa | tasks.md 단계 검증·커버리지 미달 |
| `python-reviewer` | PEP8·Pythonic·타입·보안 | reviewer | `[STACK]=python` (FastAPI 외) 변경 파일 |
| `fastapi-reviewer` | async·DI·Pydantic·OpenAPI | reviewer | `[STACK]=python-fastapi` 변경 파일 |
| `typescript-reviewer` | 타입안전·async·Node/web 보안 | reviewer | `[STACK]∈{typescript, ts-next, javascript}` |
| `java-reviewer` | 레이어·JPA·동시성 | reviewer | `[STACK]∈{java, java-spring}` |
| `security-reviewer` | OWASP·시크릿·SSRF·인젝션 | reviewer | auth·token·secret·SQL·외부호출·crypto 키워드 변경 |
| `code-reviewer` | 품질·유지보수·단순화 | reviewer | 항상 (스택 무관 보강) |
| `doc-updater` | README·CODEMAP·docs 동기화 | orchestrator | Phase 5 완료 시 |
| `loop-operator` | 자율 루프 운영·정체 시 개입 | 사용자 명시 호출 | `/loop` 워크플로 |

---

## 🎯 3축 통합 디자인 (2026-05-28~)

기존 단일 라인 파이프라인에 다음 3축을 적용. 상세는 각 agent.md와 `harness-orchestrator/SKILL.md`.

| 축 | 의미 | 적용 위치 |
|---|---|---|
| **A. 수직 위임** | L1이 트리거 조건 시 L2·skill 호출 (depth ↑) | 모든 Phase, 항상 활성 |
| **B. 수평 팬아웃** | 같은 Phase 내 N개 agent 병렬 호출 (breadth ↑) | Phase 3 기본, Phase 1/2/4 조건부 |
| **C. 통합 머지** | 팬아웃 결과 dedupe·severity boost·충돌 사용자 결정 | Phase 3 (reviewer), Phase 4 (qa) |

### 팬아웃 트리거 표 (축 B+C 활성 조건)

| Phase | 트리거 | 패턴 |
|---|---|---|
| 1 (planner) | spec ≥ 5p OR 시스템 통합 ≥ 3개 OR 사용자 "정밀 설계" | architect ×2 (다른 제약) + code-architect 병렬 → trade-off 표 통합 |
| 2 (implementer) | FE 시각 작업 + 사용자 "디자인 정밀" | `/gan-design` generator/evaluator 루프 |
| 3 (reviewer) | **항상 (기본 동작)** | stack-reviewer + (security-reviewer 조건부) + code-reviewer 병렬 → dedupe |
| 4 (qa) | 독립 모듈 ≥ 3개 + 공유 상태 없음 | `superpowers/dispatching-parallel-agents` 패턴 |

### 호출 비용 정책

- 기본은 **단일 라인** (각 Phase 1개 agent) — 토큰 비용 동일
- 팬아웃 1회 = 토큰 ~3~4배 → **명시 트리거에만**
- 1차 단계 실패 시 후속 팬아웃 진입 금지 (전체 절약)

---

## 🚀 하네스 onboarding 스킬

`harness-adapt` — 기존 프로젝트에 처음 적용하거나 스택이 크게 변경된 후 재적응할 때 사용.

| 트리거 예시 | 동작 |
|-----------|------|
| "하네스 적용해줘" | 코드 스택 분석 → `CLAUDE.md` / `01-project-structure.md` / `03-ai-agent-guidelines.md` 자동 수정 |
| "프로젝트 분석해서 하네스 갱신" | 동일 |
| "하네스 onboarding" | 동일 |

**워크플로우**: Phase 0 사전확인 → Phase 1 스택 탐색 → Phase 2 도메인 분류 → Phase 3 자동 수정 → Phase 4 검증·보고.
**사용 시점**: `setup.ps1`/`setup.sh` 직후 첫 세션에서 1회. 이후 스택 변경 시에만 재실행.

상세: `.claude/skills/harness-adapt/SKILL.md`

---

## 🔀 에이전트 실행 모드 선택

| 상황 | 모드 | 이유 |
|------|------|------|
| 기능 개발 전체 흐름 | **파이프라인 (L1 4개)** | 단계 간 산출물 의존성 있음 |
| Phase 3 reviewer | **수평 팬아웃 (L1 + L2 N개)** | 다관점 통합으로 신호 증폭 |
| 큰 기능 설계 | **Phase 1 팬아웃 (architect ×2)** | trade-off 비교 후 선택 |
| 2개 이상 독립 작업 (모듈·테스트 파일) | **`dispatching-parallel-agents` 패턴** | 격리 컨텍스트로 동시 처리 |
| 탐색/분석만 필요 | **`Explore` 서브 에이전트** | 읽기 전용, 컨텍스트 격리 |

**의사결정 순서**:
1. 기능 개발이면 → `harness-orchestrator` 스킬 (파이프라인·팬아웃 자동 결정)
2. 큰 기능 설계 필요면 → 사용자가 "정밀 설계" 명시 → planner 팬아웃 활성
3. 독립 작업 2개 이상이면 → `Agent` 도구 병렬 호출 (같은 메시지에서 N개 호출)
4. 단순 탐색이면 → `Explore` 서브 에이전트

---

## ⚠️ 스킬 사용 규칙

1. **사용 전 확인**: 스킬 실행 전 `question` 툴로 사용자 확인 (옵션 작성 원칙은 `CLAUDE.md` §3 참조).
   메타 옵션("진행/보류/질문") 대신 **실제 의사결정 분기**(스킬 A vs B, 범위 축소 vs 전체)로 제시.
2. **Domain Matching**: 작업 도메인과 가장 잘 맞는 스킬 선택 (`[STACK]` 기반 자동 분기 우선).
3. **User Skills Priority**: 사용자 설치 스킬이 기본 스킬보다 우선.
4. **유연한 활용**: Speckit에 국한되지 않고 ECC/superpowers 스킬을 상황에 맞게 활용.
5. **Net-zero 원칙**: 새 스킬·에이전트 추가 시 사용하지 않는 항목은 이 목록에서 제거 (Instruction overload 방지).
6. **호출 형식 표준**: 외부 모델 호출(`/multi-*`) 외 모든 in-process 호출은 다음 형식 준수:

   ```
   Agent(
     subagent_type="general-purpose",
     description="<3~5단어>",
     prompt="[역할] .claude/agents/{name}.md 정의대로 행동.
     [GOAL] ...
     [INPUT] ... + [STACK]
     [OUTPUT] ...
     [CONSTRAINT] ..."
   )
   ```

   > opencode/devai 환경: setup `-Opencode` 변환이 위 `Agent(...)` 를 `task(subagent_type="<실제 agent 이름>", load_skills=[...], ...)` 로 자동 변환한다 (prompt 의 `agents/<name>.md` 에서 이름 추출, planner/implementer 는 load_skills 자동 주입). 원본은 Claude Code 형식으로 유지.

7. **팬아웃 비용 의식**: 트리거 조건 외 팬아웃 호출 금지. 부분 재실행 시 변경 스택만 호출하여 절약.
