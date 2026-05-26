# 2026-05-26 refactor: 하네스 셀프 리뷰 결과 보완

## 변경 내용

### 수정

- `CLAUDE.md`
  - Rule 9에 후속 트리거 키워드 추가 (재실행/업데이트/수정/보완)
  - 하네스 변경 이력 테이블 추가 (Phase 5-4 권장 형식)

- `.claude/skills/harness-orchestrator/SKILL.md` 전체 재작성
  - description에 후속 키워드 확장
  - `Agent` 도구 호출 형식 명시 (subagent_type / prompt 양식)
  - 에러 핸들링 패턴 추가 (1회 재시도 → 누락 명시 + 에스컬레이션)
  - caveman 출력 경계 명시 (사용자 보고는 정상 작성)
  - 테스트 시나리오 확장 (정상 / 에러 / 재개 / 부분 재실행 / 3회 초과)
  - Phase 0 상태 분류에 "부분 재실행" 추가

- `.claude/agents/planner.md` — 재호출 시 행동 매트릭스 추가
- `.claude/agents/implementer.md` — 재호출 시 행동 매트릭스 추가
- `.claude/agents/reviewer.md` — 재호출 시 행동 매트릭스 추가
- `.claude/agents/qa.md` — 재호출 시 행동 매트릭스 추가

- `setup.sh` — `realpath -m` 호환성 fallback 추가 (macOS 기본 환경, python3 백업)

### 신규

- `.specify/memory/README.md` — constitution.md 사용 가이드 (역할, 작성 방법, 예시, 시점)

## 영향 범위

- 하네스 오케스트레이터 동작 (Agent 호출 형식 표준화)
- 에이전트 재호출 안정성 (4개 agents 전체)
- macOS 호환성 (setup.sh)
- spec-kit constitution 활용 가능성 (가이드 신규)

## 리뷰 미반영 항목 (의도적 보류)

| 항목 | 사유 |
|------|------|
| 1. 에이전트 frontmatter `model` 추가 | 사용자 결정: 사내 로컬 LLM 자동 적용 (frontmatter 비워둠) |
| 11. 트리거 충돌 검증 | 실제 새 세션에서 사용자 테스트 필요. 별도 검증 세션에서 처리 |

## 관련 변경 이력

- 2026-05-26-feat-harness-engineering-completion.md (초기 구성)
