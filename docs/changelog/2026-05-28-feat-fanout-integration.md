# 2026-05-28 — ECC·superpowers 통합 (수직 위임 + 수평 팬아웃 + 통합)

## 변경 요약

기존 4-agent 파이프라인 (`planner → implementer → reviewer → qa`) 에 **3축 통합 디자인** 적용:

- **축 A (수직 위임)**: 각 L1 agent가 stack/조건별로 새 agent·skill 위임
- **축 B (수평 팬아웃)**: 같은 Phase 내 다중 agent 병렬 호출 (특히 Phase 3 reviewer)
- **축 C (통합 머지)**: 팬아웃 결과 dedupe·severity boost·충돌 사용자 결정

## 영향 파일

| 파일 | 변경 요지 |
|------|-----------|
| `.claude/skills/harness-orchestrator/SKILL.md` | Phase 0.5 스택 감지 추가, Phase 3 본문 1차+2차+통합 3단계로 교체, Phase 5에 doc-updater 호출 추가, 팬아웃 트리거 표 신규 |
| `.claude/agents/planner.md` | 위임 매트릭스 (수직), 팬아웃 매트릭스 (수평, 큰 기능 한정), 참조 skill 표 추가 |
| `.claude/agents/implementer.md` | `[STACK]` 기반 스택별 skill 표, 메타 skill 호출 게이트 (tdd-guide/systematic-debugging/verification-before-completion/git-worktrees), FE 한정 gan-design 팬아웃 |
| `.claude/agents/reviewer.md` | 3단계 실행 프로토콜 (1차 스펙 단독 → 2차 stack-reviewer 팬아웃 → 3차 통합), 라우팅 표, dedupe·severity boost·충돌 처리 규칙 |
| `.claude/agents/qa.md` | 위임 매트릭스 (verification-before-completion·systematic-debugging·springboot-verification·tdd-guide), 독립 모듈 ≥ 3개 팬아웃 패턴 |

## 사용 신규 자원

### 추가 에이전트 (`.claude/agents/`)
- `architect`, `code-architect` — Phase 1 위임/팬아웃
- `code-reviewer`, `python-reviewer`, `typescript-reviewer`, `java-reviewer`, `fastapi-reviewer`, `security-reviewer` — Phase 3 팬아웃
- `tdd-guide` — Phase 2/4 TDD·커버리지 게이트
- `doc-updater` — Phase 5 문서 동기화

### ECC skills (`.claude/skills/ecc/`)
- 스택 패턴: `python-patterns`, `fastapi-patterns`, `java-coding-standards`, `springboot-patterns`, `jpa-patterns`, `springboot-security`, `frontend-patterns`, `nextjs-turbopack`
- 테스트: `python-testing`, `springboot-tdd`, `springboot-verification`, `tdd-workflow`
- API/UI: `api-design`, `api-connector-builder`, `dashboard-builder`, `frontend-design-direction`, `motion-ui`, `liquid-glass-design`, `ui-demo`, `ui-to-vue`, `frontend-slides`

### Superpowers skills (`.claude/skills/superpowers/`)
- `brainstorming` — Phase 1 모호한 요구사항
- `dispatching-parallel-agents` — Phase 4 모듈 팬아웃 패턴
- `requesting-code-review` / `receiving-code-review` — Phase 3 팬아웃 호출 형식·이슈 수용
- `test-driven-development` (+ `testing-anti-patterns.md`) — Phase 2 메타
- `systematic-debugging` — Phase 2 막힘·Phase 4 재현 실패
- `verification-before-completion` — Phase 4 완료 직전 게이트
- `using-git-worktrees` — Phase 2 병렬 분기

### Commands (`.claude/commands/`)
- `gan-design` — Phase 2 FE 디자인 GAN 루프
- `multi-*` — 외부 모델 (Codex/Gemini) 트랙. 현 in-process 파이프라인에선 미사용. 참고용.
- `update-codemaps`, `update-docs` — Phase 5 doc-updater agent 가 호출

## 호출 비용 정책

- 기본은 **단일 라인** (각 Phase 1개 agent) — 토큰 비용 동일
- **팬아웃은 명시 트리거에만**:
  - Phase 1: spec ≥ 5p OR 시스템 통합 ≥ 3개 OR 사용자 "정밀 설계"
  - Phase 3: **항상 (기본 동작)** — 2차 팬아웃이 기본. 단 부분 재실행 시 변경 파일이 단일 스택이면 reviewer 2개만 호출
  - Phase 4: 독립 모듈 ≥ 3개
- 1차 스펙 미달 시 2차 진입 금지 (전체 팬아웃 절약)

## 트레이드오프

| 비용 | 완화 |
|------|------|
| 토큰·시간 ~3-4배 (Phase 3) | 변경 범위 작을 때 reviewer 호출 수 줄임 |
| 통합 복잡도 ↑ | dedupe·severity boost·충돌 처리 규칙 명문화 |
| 결정론 ↓ (통합 결과 변동) | reviewer 머지 규칙 표준화 |

## 검증

- 각 agent.md / SKILL.md 문서 read-back으로 일관성 확인
- 실제 기능 개발 1회 돌려야 회귀 검증 가능 (다음 기능 시 첫 검증)

## 후속 작업

- spec.md 헤더에 `[STACK]` 기록 컨벤션 → planner agent가 자동 작성하도록 speckit-specify 템플릿 보강 (별도 작업)
- 팬아웃 결과 통합 시 사용자 결정 횟수 모니터링 → 너무 잦으면 트리거 조건 조정
