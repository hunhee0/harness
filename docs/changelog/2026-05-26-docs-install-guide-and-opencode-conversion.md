# 2026-05-26 docs: 이식 가이드 + opencode 변환 가이드

## 변경 내용

### 신규

- `docs/INSTALL.md`
  - **섹션 1**: Claude Code 환경 이식 (`setup.ps1` / `setup.sh` 사용법, DryRun, 복사 항목·제외 항목 표, 사후 작업 3종, 트러블슈팅)
  - **섹션 2**: opencode 환경 변환
    - Claude Code ↔ opencode 구조 차이 매핑표
    - 6단계 변환 절차 (디렉토리 / agent frontmatter / 스킬→command / Agent 호출 / 훅 / spec-kit 호환성)
    - 변환 후 검증 체크리스트
    - 사내 fork 차이 검토 가이드 (6가지 확인 포인트)

### 수정

- `README.md`
  - "두 가지 사용 시나리오" 섹션 뒤에 **"🔌 이식 / 변환 가이드"** 신규 섹션 추가
  - setup 스크립트 한 줄 사용법 + INSTALL.md 링크

## 영향 범위

- 다른 프로젝트로 하네스 이식 워크플로우 명문화
- opencode 기반 사내 CLI 호환 가이드 제공
- README 정보 보강 (기존 콘텐츠는 유지)

## 비고

- opencode 변환 가이드는 공식 구조 기준. 사내 fork 차이는 사용자가 사내 문서로 검증
- spec-kit (.specify/)의 opencode 호환성 미확인 — 사용자 환경에서 검증 필요
