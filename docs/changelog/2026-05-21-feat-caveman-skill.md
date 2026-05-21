# 2026-05-21 feat: Caveman 스킬 도입 + CLAUDE.md §8 압축

## 변경 내용

### `.claude/skills/caveman/SKILL.md` (신규)
- 원본: `https://github.com/JuliusBrussee/caveman/blob/main/skills/caveman/SKILL.md`
- verbatim 그대로 도입 (74줄)
- 포함 섹션: Persistence / Rules / Intensity (lite, full, ultra, wenyan-lite, wenyan-full, wenyan-ultra) / Auto-Clarity / Boundaries
- 시스템에 `caveman` 스킬로 자동 등록 확인 (system-reminder available-skills 목록 노출)

### `CLAUDE.md` §8 출력 스타일 (압축)
- 기존: 필러 제거 / 단답 우선 / 자동 해제 조건 등 인라인 상세 규칙 (약 15줄)
- 변경: `.claude/skills/caveman/SKILL.md` 참조 위임 + 한국어/프로젝트 보강만 유지 (약 7줄)
- 보강 유지 항목:
  - 기본 intensity = `lite` (한국어 가독성 우선)
  - 한국어 가독성 손상 위험 시 자동 일반 스타일
  - 자동 해제 추가 조건: `question` 툴 / diff·요약 / 학습용 질문
  - 적용 제외: 코드 / 커밋 메시지 / 문서 / changelog

## 영향 범위

| 파일 | 변경 유형 | 줄 수 변화 |
|---|---|---|
| `.claude/skills/caveman/SKILL.md` | 신규 | +74 |
| `CLAUDE.md` | §8 압축 | 119 → 114 (-5) |

## 근거 (Why)

**원칙 부합**:
- **Progressive Disclosure** (`docs/rules/05-context-management.md`): 루트 CLAUDE.md는 짧게, 상세는 외부 파일로 위임
- **Net-zero 원칙**: 새 규칙 추가 시 기존 규칙 1개 압축 — CLAUDE.md §8 인라인 규칙 → 외부 스킬 위임으로 instruction overload 방지
- **Memory Tiering**: Tier 1(CLAUDE.md, 짧은 인덱스) → Tier 2(skills/, 상세 규칙)

**사용자 의사결정**:
- 압축 방식: "스킬 참조 + 한국어 보강" (Recommended) 선택
- 후속 작업: changelog만 기록, commit/push는 보류

## 검증 (Verify)

- [x] `.claude/skills/caveman/SKILL.md` 파일 생성 (74줄)
- [x] `CLAUDE.md` §8 압축 (114줄)
- [x] system-reminder available-skills 목록에 `caveman` 자동 등록 확인

## 관련 스펙

- (해당 없음 — 메타 규칙/하네스 정비 작업)
