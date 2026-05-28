# 2026-05-28 — docs: rules·CLAUDE.md·README.md 동기화 (ECC/superpowers + 3축 통합 반영)

## 변경 요약

2026-05-28 자 ECC·superpowers 통합 및 3축 통합 디자인 적용 결과를 문서에 반영. 가짜 자원 항목 제거, 실제 인벤토리로 갱신.

## 영향 파일

| 파일 | 변경 |
|------|------|
| `docs/rules/03-ai-agent-guidelines.md` | **전면 재작성** — 가짜 항목(gstack 슬래시명령·ktds·writing-plans 등) 제거. ECC 6→21, superpowers 10→8 실제. agents 4→15 (L1+L2). commands 10개 추가. 3축 통합 디자인 + 팬아웃 트리거 표 + 호출 형식 표준 |
| `docs/rules/01-project-structure.md` | rules 5→7개. 디렉토리 구조에 `.claude/commands/`, `.claude/rules/ecc/`, `.claude/skills/ecc/`, `.claude/skills/superpowers/` 반영. 잠정 라벨 문구 조정 |
| `CLAUDE.md` | §9에 2계층 팀·3축 통합·스킬 자원 요약 추가. 변경 이력 표에 2026-05-28 두 행 추가. 프로젝트 구조 개요에 commands/rules/ecc·superpowers 표시 |
| `README.md` | 한 줄 요약에 L1+L2·통합 스킬 팩·3축 통합 추가. 핵심 포함물 7개 항목으로 확장. 권장 스킬 섹션을 "통합 스킬 팩 (이미 포함)" + "옵션 (전역 설치)"로 분리. 에이전트 파이프라인 다이어그램에 Phase 0.5·3·5 + 3축 표 추가. 디렉토리 구조 갱신 |
| `.claude/skills/harness-adapt/SKILL.md` | Phase 1-6 `[STACK]` 키 매핑 표 추가 (orchestrator 호환). Phase 3-2 분리: 3-2-A 표준 L2 활성화 (이미 포함) + 3-2-B 도메인 특화 신규 생성. ECC/superpowers/commands 인벤토리는 Net-zero 원칙으로 수정 금지 명시. Phase 4-4 changelog 기록 항목 확장. 테스트 시나리오에 ML·금융 도메인 추가 |
| `docs/INSTALL.md` | 복사 항목 표 갱신 (agents 4→15, skills/ecc 21, skills/superpowers 8, commands 10, rules/ecc). 경로 A 자동 적응 설명에 `[STACK]` 정규화·3-2-A/B 분리·보존 항목 명시. opencode 변환 Step 1 에 commands·rules/ecc 처리 + 자원 규모 의식 추가. 변환 후 체크리스트 보강 (15 agents·팬아웃 동시 spawn·commands·`[STACK]` 전파) |
| `setup.ps1`, `setup.sh` | (1) 복사 항목에 `.claude/commands/`·`.claude/rules/` 추가. (2) **`-Opencode` 전체 자동 변환** — 경로 매핑 (agents→agent 단수·skills/commands→command 병합·rules→rule 단수·settings.json→루트 opencode.json), agent frontmatter 정리 (name 제거·mode: subagent 추가), SKILL.md→<skill>.md rename (nested ecc/superpowers 포함), opencode.json에 `_note` 키 자동 삽입. 본문 내 `.claude/agents` 등 경로 참조도 동일 매핑으로 치환. `Agent(...)/Skill(...)` 호출 표기는 자동 변환 불가 — 안내 메시지로 수동 검토 항목 명시 |

## 사유

- `03`에 실제 존재하지 않는 자원 (gstack 슬래시 명령, ECC 가상 스킬명, ktds 등) 기재되어 있어 LLM이 호출 시도 시 실패.
- 새 자원(ECC 21·superpowers 8·agents 11·commands 10) + 3축 통합 디자인이 문서에 미반영.
- `harness-orchestrator`·각 agent.md 의 위임/팬아웃 매트릭스가 03/CLAUDE.md/README와 단절.

## 검증

- 각 파일 read-back으로 일관성 확인
- 실제 `.claude/agents/`·`.claude/skills/` 디렉토리와 인벤토리 표 대조
- 다음 기능 개발 1회 돌릴 때 `[STACK]` 자동 감지·Phase 3 팬아웃·doc-updater 호출 회귀 검증

## 후속 작업

- ✅ `harness-adapt` SKILL.md 가 ECC·superpowers 인벤토리·L2 활성화·신규 생성 분리 반영
- ✅ `docs/INSTALL.md` 갱신 (복사 항목·자동 적응·opencode 변환 체크리스트)
- ✅ `setup.ps1`/`setup.sh` — `.claude/commands/`·`.claude/rules/` 복사 추가
- ✅ `setup.ps1`/`setup.sh` `-Opencode` 옵션 전체 자동 변환 구현 + 실제 실행 검증 (bash):
  - JSON 유효성 (opencode.json) PASS
  - frontmatter `name:` 제거·`mode: subagent` 추가 PASS (15개 agent)
  - SKILL.md→<skill>.md rename PASS (nested ecc/superpowers 포함)
  - 본문 내 `.claude/agents` → `.opencode/agent` 등 매핑 PASS
  - `.claude` 잔존 참조 0건
- spec.md 헤더에 `[STACK]` 자동 기록 컨벤션 → `.specify/templates/spec-template.md` 보강 (다음 기능 개발 시)
