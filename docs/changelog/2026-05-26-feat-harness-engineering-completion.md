# 2026-05-26 feat: 하네스 엔지니어링 세팅 완성

## 변경 내용

### 신규 생성

- `.claude/agents/planner.md` — 스펙·계획·태스크 단계 전담 에이전트
- `.claude/agents/implementer.md` — TDD 기반 코드 구현 에이전트
- `.claude/agents/reviewer.md` — 코드 리뷰·스펙 준수 검증 에이전트
- `.claude/agents/qa.md` — 통합 정합성·엣지 케이스 검증 에이전트
- `.claude/skills/harness-orchestrator/SKILL.md` — 개발 파이프라인 오케스트레이터 스킬
- `docs/rules/06-branch-strategy.md` — 브랜치 전략 및 PR 규칙
- `docs/rules/07-error-recovery.md` — 에러 복구 및 롤백 절차
- `setup.ps1` — Windows용 하네스 이식 스크립트
- `setup.sh` — Mac/Linux용 하네스 이식 스크립트

### 수정

- `docs/rules/03-ai-agent-guidelines.md` — 프로젝트 에이전트 팀 섹션, 실행 모드 선택 기준 추가
- `CLAUDE.md` — 규칙 파일 06/07 추가, 오케스트레이터 진입점(Rule 9), constitution.md 포인터, 프로젝트 구조 업데이트

## 영향 범위

- 하네스 전체 구조
- 기능 개발 진입 방식 (`harness-orchestrator` 스킬 → 에이전트 파이프라인)
- 다른 프로젝트 이식 가능 (`setup.ps1` / `setup.sh`)
