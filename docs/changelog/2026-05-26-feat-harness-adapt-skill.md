# 2026-05-26 feat: harness-adapt 스킬 신규 (기존 프로젝트 자동 onboarding)

## 변경 내용

### 신규

- **`.claude/skills/harness-adapt/SKILL.md`**
  - Phase 0: 사전 확인 (하네스 파일 존재 검증)
  - Phase 1: 스택 탐색 (매니페스트·디렉토리·도구·프레임워크 감지, 11개 언어 매트릭스)
  - Phase 2: 도메인 분류 (백엔드/프론트/풀스택/CLI/라이브러리/ML/IaC/모바일/게임 + 사용자 확인)
  - Phase 3: 파일 자동 수정 (CLAUDE.md / 01-project-structure.md / 03-ai-agent-guidelines.md + 도메인 특화 agent 신규)
  - Phase 4: 검증·보고 (변경 요약, constitution 권유, 첫 사용 가이드, changelog 자동 기록)
  - 에러 핸들링 매트릭스 (매니페스트 0개·다수, 도메인 모호, 수정 실패)
  - caveman 경계 (사용자 보고는 정상 작성)
  - 테스트 시나리오 4종 (FastAPI / 모노레포 / ML / 매니페스트 0개)

### 수정

- **`CLAUDE.md`** Rule 9
  - "하네스 진입점 (orchestrator + adapt)"으로 확장
  - harness-adapt 트리거 키워드 명시
  - 변경 이력 테이블에 2건 추가 (이식 가이드, harness-adapt)

- **`docs/rules/03-ai-agent-guidelines.md`**
  - "프로젝트 에이전트 팀" 섹션 위에 "하네스 onboarding 스킬" 신규 섹션 추가

- **`docs/INSTALL.md`** §1 사후 작업
  - "경로 A. 자동 적응 (harness-adapt)" / "경로 B. 수동 수정" 두 갈래로 재구성
  - 자동화 경로 권장 명시

## 영향 범위

- 기존 프로젝트 적용 워크플로우 자동화 (수동 3개 파일 수정 → 자동 분석·일괄 수정)
- 도메인별 추가 agent 가이드 (ML/보안/IaC/SPA/모바일별 권장 agent 레시피)
- INSTALL.md를 사용자 선택형으로 재구성 (자동 vs 수동)

## 후속 검증 필요

- harness-adapt 트리거가 새 세션에서 정상 발동하는지 (트리거 충돌 가능성: `harness:harness`, `harness-audit`)
- 모노레포·다국어 프로젝트에서 Phase 1 감지 정확도
- 도메인 특화 agent 자동 생성 시 orchestrator Phase 보강 품질
