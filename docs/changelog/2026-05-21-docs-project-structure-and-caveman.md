# 2026-05-21 docs: 프로젝트 구조 잠정 표시 + Karpathy 원문 보강 + Caveman Lite 적용

## 변경 내용

### `docs/rules/01-project-structure.md` (재작성)
- 루트 디렉토리명 정정: `haness_test/` → `haness/`
- 상태 라벨 추가: `🟡 잠정 (Tentative)` — 프로젝트 종류 미확정 명시
- FastAPI / Poetry / pytest 등을 **잠정 후보**로 표시, 각 항목별 대안 명시
- 존재하지 않는 `src/`, `tests/`를 **예시 레이아웃** 섹션으로 분리 (현재 디렉토리와 구분)
- 아키텍처 원칙은 기술 스택 무관 항목으로 재배치

### `CLAUDE.md` §2 Karpathy 4원칙 보강
- 원문(Andrej Karpathy, 2026-01-26 X 게시) 한 줄 핵심 문구를 표에 추가
- Tradeoff 명시: "속도보다 신중 우선 (caution over speed)"
- 100K+ stars `multica-ai/andrej-karpathy-skills` 리포 검증 표현 반영

### `CLAUDE.md` §8 출력 스타일 (Caveman Lite — Always-on) 신규
- 토큰 절감 목적의 caveman lite 모드 항시 적용
- 필러 제거, 단답 우선, 한 줄 요약 권장
- **자동 해제 조건**: 보안 경고 / 비가역 작업 / `question` 툴 / diff·요약 / 사용자 학습 설명
- **적용 제외**: 코드 / 커밋 메시지 / 문서 / changelog — 정상 작성

## 영향 범위

| 파일 | 변경 유형 |
|---|---|
| `docs/rules/01-project-structure.md` | 재작성 |
| `CLAUDE.md` | §2 표 보강 + §8 신규 |

## 근거 (Why)

**사용자 의사결정**:
- 01: 잠정 상태 명시로 재작성 (프로젝트 종류 미정)
- Karpathy: 원문 핵심 보강
- Caveman: always-on, lite 강도, 중요 작업 자동 해제, 코드/문서 제외

**참고한 인기 리포 (2026)**:
- `multica-ai/andrej-karpathy-skills` (110K+ stars, 28일 연속 GitHub Trending #1)
- `JuliusBrussee/caveman` — 토큰 65~75% 절감 케이브맨 스타일 스킬
- `mattpocock/skills` (48K+ stars) — Engineering 10개 + Productivity 4개 검토 결과, 기존 `superpowers` / `speckit` 스킬 또는 `02-development-workflow.md`(Verification Loop) / `05-context-management.md`(Context Compaction)와 중복되어 추가 도입 불필요로 판단

## 관련 스펙

- (해당 없음 — 메타 규칙/하네스 정비 작업)
