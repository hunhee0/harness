# 2026-05-29 fix: speckit 4단계 게이트 강제 (spec/plan/tasks/implement)

## 문제

`harness-orchestrator` Phase 1이 spec→plan→tasks를 `planner` 서브에이전트 1회 호출에 통째로 위임하고 끝에 게이트 1개만 둠. 결과:

- 서브에이전트(Agent 도구)는 대화형 사용자 확인 불가 → 게이트가 1개로 뭉개짐
- `planner.md` 프로토콜에 tasks 후 게이트 누락 → 구현까지 직행
- Phase 2에 `/speckit-implement` 메커니즘 미명시

실관측: plan 후 1회만 확인하고 이후 구현까지 무확인 진행.

## 변경

### .claude/skills/harness-orchestrator/SKILL.md

- Phase 1을 1a(specify) / 1b(plan) / 1c(tasks) 3개 하위 단계로 분할
- 각 단계 후 GATE 1/2/3 (`AskUserQuestion`) — 게이트는 오케스트레이터 메인 컨텍스트가 소유
- GATE 3 (tasks 후)를 **BLOCKING·필수**로 명시 — 미승인 시 Phase 2 진입 금지
- Phase 2 헤더에 전제(GATE 3 통과) + 메커니즘(`/speckit-implement`) 추가
- 정상 흐름 테스트 시나리오를 3게이트 구조로 갱신

### .claude/agents/planner.md

- 게이트 소유권 주석 추가 (메인 컨텍스트가 확인 수행, `/speckit-specify` 질의 이유)
- 실행 프로토콜에 GATE 3 추가 + GATE 3 승인 후에만 `implementer` 전달
- 작업 원칙: 3게이트 필수 + tasks 후 BLOCKING 명문화

### .claude/agents/implementer.md

- 전제(GATE 3 통과) + 메커니즘(`/speckit-implement`) 주석 추가

## 근거

- 서브에이전트는 사용자와 대화형 확인 불가 → 게이트는 메인 컨텍스트 소유
- `/speckit-specify`는 내부 [NEEDS CLARIFICATION] 사용자 질의 → 메인 컨텍스트 실행 필수
- speckit 순서 `spec → plan → tasks → implement` 절대 준수

## 영향 범위

- 기능 개발 파이프라인의 사용자 확인 게이트가 3개로 명확화
- tasks → implement 전환이 사용자 승인 BLOCKING으로 보호
