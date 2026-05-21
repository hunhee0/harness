# 2026-05-21 docs: 하네스 엔지니어링 관점으로 규칙 문서 정비

## 변경 내용

### `CLAUDE.md` (197줄 → ~95줄, 약 50% 압축)
- 중복된 "절대 규칙 (MUST READ)" 섹션 제거 (2회 반복 → 1회)
- 규칙 순서 정리: 1번부터 7번까지 연속 배치 (기존: 1→2→3 다음 4→5→6 분산)
- Windows 경로(`C:\Users\82304416\...`) 포함 "전역 규칙" 섹션 제거 (사용자 요청)
- `question` 툴 예시 압축 (3개 → 1개)
- **신규**: "하네스 엔지니어링 원칙 (2026)" 섹션
  - 3단계 실행 루프 (Gather → Action → Verify)
  - Context Engineering, Verification Loop, Permission Gating, Memory Tiering 표

### `docs/rules/02-development-workflow.md`
- **신규**: "Verification Loop (3단계 실행 루프)" 섹션 (Anthropic 권장 패턴)
- "검증 없는 완료 보고 금지", "2회 교정 실패 시 /clear" 규칙 추가

### `docs/rules/03-ai-agent-guidelines.md`
- `question` 툴 예시 부분 압축 (CLAUDE.md와 중복 제거)
- "Net-zero 원칙" 추가 (스킬 추가 시 안 쓰는 스킬 제거)

### `docs/rules/04-change-log.md`
- 오타 수정: `breaking —破壊적 변경` → `breaking — 파괴적 변경` (일본어 한자 → 한글)

### `docs/rules/05-context-management.md` (신규)
- Progressive Disclosure, Context Compaction, Memory Tiering, Instruction Overload 방지
- 작업 전/중/후 실전 체크리스트
- 2026년 업계 컨센서스 참고문헌

## 영향 범위

| 파일 | 변경 유형 |
|---|---|
| `CLAUDE.md` | 대폭 압축 + 신규 섹션 |
| `docs/rules/02-development-workflow.md` | 섹션 추가 |
| `docs/rules/03-ai-agent-guidelines.md` | 압축 |
| `docs/rules/04-change-log.md` | 오타 수정 |
| `docs/rules/05-context-management.md` | 신규 |
| `docs/changelog/` (디렉토리) | 신규 |

## 근거 (Why)

2026년 업계 컨센서스 (Anthropic Claude Code 베스트 프랙티스, HumanLayer, Augment Code, Red Hat Developer, Epsilla) 반영:

1. **Instruction Overload**: LLM은 약 150-200개 instruction까지만 안정적으로 따름. Claude Code 시스템 프롬프트가 ~50개를 소비하므로 CLAUDE.md는 100-150개 한계. 기존 197줄은 과다.
2. **권장 분량**: 루트 CLAUDE.md는 40-80줄 이상적, 80-120줄 실용적 한계.
3. **Verification Loop**: `gather context → take action → verify results`가 production-grade harness의 핵심 패턴.
4. **Progressive Disclosure**: 루트는 인덱스로, 상세는 별도 파일로 위임하면 토큰 효율과 instruction-following 품질이 향상됨.
5. **Memory Tiering**: Always-on / Domain Rules / Task Context / History 4계층 분리가 표준.

## 관련 스펙

- (해당 없음 — 메타 규칙/하네스 정비 작업)
