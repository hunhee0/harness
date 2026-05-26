# 2026-05-26 docs: README 전체 outdated 동기화

## 변경 내용

### 수정 (`README.md` 6개 위치)

| # | 섹션 | 변경 |
|---|------|------|
| 1 | 한 줄 요약 표 | "사용 대상"에 ③ AM 추가 / "핵심 도구"에 에이전트 팀·오케스트레이터 명시 / "핵심 스킬" 행 신규 / "에이전트 팀" 행 신규 |
| 2 | 이 프로젝트는 무엇인가 | 5개 구성 요소(규칙·에이전트·오케스트레이터·onboarding·이식) 명문화 / 3개 적용 시나리오 (신규/ITO/AM) |
| 3 | 사전 설치 권장 스킬 표 | `harness-orchestrator`, `harness-adapt` 2행 추가 |
| 4 | 사전 설치 설치 명령 주석 | 프로젝트 로컬 포함 스킬 5개 목록으로 상세화 |
| 5 | 개발 방식 | "에이전트 파이프라인 (harness-orchestrator)" 신규 섹션 (4 에이전트 흐름도 + 도메인 특화 agent 언급) |
| 6 | 디렉토리 구조 | `.claude/agents/` 추가, `.claude/skills/` 하위 분해, `.specify/memory/` 분해, `docs/INSTALL.md` 추가, `setup.ps1` / `setup.sh` 추가, rules 5개 → 7개 보정 |
| 7 | 절대 규칙 요약 | 8개 → 9개 / Rule 9 (하네스 진입점) 추가 / rules 5개 → 7개 보정 |

## 영향 범위

- README 정보가 실제 산출물 (agents/skills/scripts/rules)과 일치
- 신규 사용자 진입 시 정확한 구조·진입점 파악 가능
- AM 시나리오 가시성 확보 (한 줄 요약 표·구성 요소·시나리오 모두 반영)

## 보존 항목

- 시나리오 A (새 프로젝트) / B (ITO) / C (AM) 본문 — 변경 없음
- 🔌 이식 / 변환 가이드 — 변경 없음
- Verification Loop / 핵심 철학 / 참고 자료 — 변경 없음
