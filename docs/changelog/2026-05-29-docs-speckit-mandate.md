# 2026-05-29 docs: CLAUDE.md Rule 4에 speckit 스킬 필수 사용 명시

## 변경

### CLAUDE.md — Rule 4 (SDD 엄격 준수)

- `specify → plan → tasks → implement` 4단계 ↔ speckit 스킬 매핑 표 추가:
  - specify → `/speckit-specify`
  - plan → `/speckit-plan`
  - tasks → `/speckit-tasks`
  - implement → `/speckit-implement`
- "각 단계는 반드시 해당 speckit 스킬로 수행 (수동 대체 ❌)" 명문화
- BLOCKING 항목에 "speckit 스킬 우회(수동 작성) ❌" 추가

## 사유

모델이 speckit 스킬을 건너뛰고 수동으로 spec/plan/tasks를 작성하는 일탈 방지.
SDD 단계와 실제 호출할 스킬명을 1:1로 못박아 모호성 제거.

## 영향 범위

- 진입점(CLAUDE.md)에서 speckit 스킬 사용이 BLOCKING 규칙으로 격상
- harness-orchestrator의 Phase 1a/1b/1c·Phase 2 게이트 구조와 정합
