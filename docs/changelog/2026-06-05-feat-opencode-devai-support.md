# 2026-06-05 feat: opencode/devai 환경 완전 지원 + plugin 규칙 강제

## 배경

사내 opencode 기반 CLI(devai fork, KTDS Qwen 모델)에서 이 하네스를 사용할 때 다수 비호환 발생:

- skill·subagent·게이트가 작동하지 않거나 일관성 없음
- `setup.ps1 -Opencode` 변환 결과가 깨지거나(mojibake) devai 규약과 불일치
- agent 호출이 내장 Worker/Agentic-Planning-Team 으로 fallback
- 약한 모델(Qwen)이 SDD 순서·출력 규칙을 흘림

근본 원인은 ① Claude Code 전용 메커니즘(Agent 도구·settings.json hook·AskUserQuestion)을 devai 가 다르게 처리 ② setup 변환이 표준 opencode 단수형 규약을 가정했으나 devai 는 복수형 사용 ③ 약한 모델은 자율 분기 시 신뢰도 급락.

## 변경

### 1. setup.ps1 / setup.sh — opencode 변환 정확화

- **mojibake 해결**: setup.ps1 을 UTF-8 BOM 으로 저장 + 콘솔 OutputEncoding=UTF8 고정 (PS 5.1 이 CP949 로 오독하던 한글 깨짐 제거)
- **자기참조 치환 제거**: 변환 트리거 리터럴(`.claude/`, `Agent(...)`, `AskUserQuestion`)을 설명문에서 회피
- **복수형 디렉터리 유지**: `.opencode/{agents,skills,commands,rules,plugins}` (단수형 매핑 제거 — devai·opencode 공식 모두 복수형)
- **agent frontmatter**: `name` 보존(devai 필수 필드), `mode: subagent`, `model` 을 `ABCLab/[KTDS] Qwen3.6-*` provider prefix 형식으로 매핑
- **본문 호출 변환**: `Agent(...)` → `task(subagent_type="<실제 이름>", load_skills=[...], ...)` (prompt 의 `agents/<name>.md` 에서 이름 추출, planner/implementer 는 load_skills 자동 주입), `AskUserQuestion` → `STOP(텍스트 응답 대기)`
- **settings.json**: opencode 옵션 시 미복사 (hook 은 plugin 으로 대체). 일반 모드만 `.claude/settings.json` 생성
- **plugin 배치**: opencode 옵션 시 `.opencode/plugins/harness-rules.js` 복사 (일반 모드엔 미생성)

### 2. .opencode/plugins/harness-rules.js (신규)

opencode/devai plugin 시스템(`experimental.chat.system.transform`)으로 매 호출 system prompt 에 규칙 주입:

- **caveman** 출력 규칙 (토큰 절감)
- **Karpathy 4원칙** (가정 금지·최소 코드·수술적 변경·검증)
- **SDD/orchestrator 규칙** (spec→plan→tasks→implement→review→qa→완료 순서, 내장 Worker 대신 custom agent 사용)

차단(throw) 없이 주입만 — 평소 작업 자유. `output.system` 마지막 문자열 원소에 append (push 는 호출 깨짐 확인). 해제: 환경변수 `HARNESS_RULES_OFF=1`.

### 3. harness-orchestrator/SKILL.md — 직접 운영 + 전 Phase 게이트

- `/feature` 슬래시 커맨드 폐기(`.claude/commands/feature.md` 삭제) → orchestrator 가 파이프라인 직접 운영
- Phase 1a/1b/1c(planner) → 2(implementer) → 3(reviewer) → 4(qa) → 5(완료) 각각 `task()` 호출 블록 명시
- **GATE 1~7**: spec/plan/tasks(기존) + implement/review/qa/완료·PR(신규) — 모든 Phase 전환에 사용자 승인 강제
- 중복·구식 제거: 에러표 → docs/rules/07 링크, 출력스타일 → plugin 위임, 테스트 시나리오 삭제 (408→349줄)

### 4. agent 정의 (planner/implementer/reviewer/qa)

- 호출 경로 주석을 `harness-orchestrator Phase N` + `task(subagent_type=...)` 로 정정
- planner: GATE 1·2·3 이 Phase 1 소관(전체는 GATE 1~7)임을 명확화
- qa: 팬아웃 예시 완전화 (subagent_type=qa 로 정확 추출되도록 `agents/qa.md` 참조 명시)

### 5. 문서 정합화

- **docs/INSTALL.md §2 전면 정정**: 단수→복수형, settings 미복사, name 보존, Agent()→task() 자동변환, ABCLab model, plugin 배치, 장황한 수동변환 절 축소
- **docs/rules/02**: speckit 게이트 → orchestrator GATE 1~7 전체 흐름 연결
- **docs/rules/03**: §6 호출 형식에 opencode task() 자동변환 보강
- **README.md**: 이식 가이드에 `-Opencode` 옵션 + 실제 변환 내용 (구식 "스킬→command 변환" 제거)

## 근거 (devai 실측)

- devai 디렉터리 규약은 복수형 (사용자 `.opencode/agents` 실측)
- agent frontmatter `name` 필수 (사내 가이드)
- model id 는 `ABCLab/` provider prefix 필요 (providerModelNotFoundError 해결)
- `task(subagent_type="<이름>")` 는 실제 등록된 custom agent 이름 요구 (general-purpose 면 내장 fallback)
- plugin hook `tool.execute.before`(throw 차단) + `experimental.chat.system.transform`(system 주입) 작동 확인
- `output.system` 은 문자열 배열, 마지막 원소 append 만 안전 (push 시 모델 호출 깨짐)

## 검증

- agent 호출: A-1(단독)·B-1(정체)·E-1(팬아웃) 통과 — 내장 Worker fallback 아닌 실제 custom agent 실행
- plugin: caveman 🦴 마커로 주입·반영 확인
- setup: opencode 시 복수형 생성·settings 미생성·plugin 배치·mojibake 0, 일반 모드 시 `.claude/settings.json` 생성·`.opencode` 미생성
- 문서: `/feature` 잔재 0, INSTALL 단수형 잔재 0, plugin GATE 1~7 ↔ SKILL GATE 1~7 일치

## 영향 범위

- **Claude Code 환경**: 영향 없음 — 원본 `.claude/*` 는 Agent()·AskUserQuestion·settings.json 그대로 유지. `/feature` 폐기로 orchestrator 직접 운영(기존 자연어 트리거 동일)
- **opencode/devai 환경**: `setup -Opencode` 로 전 자원 자동 변환 + plugin 규칙 주입

## 남은 과제

- GATE 는 plugin 주입(유도)이며 throw 강제 아님 — Qwen 무시 시 우회 가능 (조건부 차단 plugin 은 부작용 우려로 미적용)
- speckit skill 의 devai end-to-end 실행 미검증 (skill 로드 자체는 확인)
- plugin 주입 토큰(~180/호출) — 서버 prefix caching 의존 (사내 확인 권장)
