---
description: 프로덕션 코드 수정 없이 멀티모델 구현 계획 작성 (Create a multi-model implementation plan without modifying production code).
---

# Plan - 멀티모델 협업 계획

멀티모델 협업 계획 — 컨텍스트 검색 + 듀얼 모델 분석 → 단계별 구현 계획 생성.

$ARGUMENTS

---

## 핵심 프로토콜

- **언어 프로토콜**: 도구·모델과 상호작용 시 **English** 사용, 사용자와는 그들의 언어로 소통
- **필수 병렬**: Codex/Gemini 호출은 반드시 `run_in_background: true` 사용 (단일 모델 호출 포함, 메인 스레드 차단 회피)
- **코드 주권**: 외부 모델은 **파일시스템 쓰기 권한 0**, 모든 수정은 Claude
- **손절 메커니즘**: 현재 phase 출력 검증되기 전 다음 phase로 진행 금지
- **계획 전용**: 이 명령은 컨텍스트 읽기와 `.claude/plan/*` 계획 파일 쓰기를 허용. **프로덕션 코드는 절대 수정 금지**

---

## 멀티모델 호출 명세

**호출 문법** (병렬: `run_in_background: true` 사용):

```
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend <codex|gemini> {{GEMINI_MODEL_FLAG}}- \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement>
Context: <retrieved project context>
</TASK>
OUTPUT: Step-by-step implementation plan with pseudo-code. DO NOT modify any files.
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})
```

**모델 파라미터 노트**:
- `{{GEMINI_MODEL_FLAG}}`: `--backend gemini` 사용 시 `--gemini-model gemini-3-pro-preview` (뒤에 공백)로 교체. codex는 빈 문자열.

**Role 프롬프트**:

| Phase | Codex | Gemini |
|-------|-------|--------|
| Analysis | `~/.claude/.ccg/prompts/codex/analyzer.md` | `~/.claude/.ccg/prompts/gemini/analyzer.md` |
| Planning | `~/.claude/.ccg/prompts/codex/architect.md` | `~/.claude/.ccg/prompts/gemini/architect.md` |

**세션 재사용**: 호출마다 `SESSION_ID: xxx` 반환 (보통 wrapper가 출력). **반드시 저장** — 후속 `/ccg:execute`용.

**백그라운드 작업 대기** (최대 timeout 600000ms = 10분):

```
TaskOutput({ task_id: "<task_id>", block: true, timeout: 600000 })
```

**중요**:
- `timeout: 600000` 반드시 지정, 그렇지 않으면 기본 30초로 조기 타임아웃
- 10분 후에도 미완료면 `TaskOutput`으로 폴링 계속, **절대 프로세스 종료 금지**
- 타임아웃으로 대기 건너뜀 시 **반드시 `AskUserQuestion`으로 계속 대기 vs 작업 종료 사용자에게 질문**

---

## 실행 워크플로

**계획 작업**: $ARGUMENTS

### Phase 1: 전체 컨텍스트 검색

`[Mode: Research]`

#### 1.1 프롬프트 강화 (반드시 먼저 실행)

**ace-tool MCP 사용 가능 시**, `mcp__ace-tool__enhance_prompt` 도구 호출:

```
mcp__ace-tool__enhance_prompt({
  prompt: "$ARGUMENTS",
  conversation_history: "<last 5-10 conversation turns>",
  project_root_path: "$PWD"
})
```

강화된 프롬프트 대기, **원본 $ARGUMENTS를 강화된 결과로 교체**하여 모든 후속 phase에서 사용.

**ace-tool MCP 사용 불가능**: 이 단계 건너뜀, 모든 후속 phase에서 원본 `$ARGUMENTS` 그대로 사용.

#### 1.2 컨텍스트 검색

**ace-tool MCP 사용 가능 시**, `mcp__ace-tool__search_context` 도구 호출:

```
mcp__ace-tool__search_context({
  query: "<semantic query based on enhanced requirement>",
  project_root_path: "$PWD"
})
```

- 자연어(Where/What/How)로 시맨틱 쿼리 구축
- **절대 가정 기반으로 답하지 말 것**

**ace-tool MCP 사용 불가능 시**, Claude Code 빌트인 도구를 fallback으로 사용:
1. **Glob**: 패턴으로 관련 파일 찾기 (예: `Glob("**/*.ts")`, `Glob("src/**/*.py")`)
2. **Grep**: 핵심 심볼·함수명·클래스 정의 검색 (예: `Grep("className|functionName")`)
3. **Read**: 발견된 파일 읽어 완전한 컨텍스트 수집
4. **Task (Explore 에이전트)**: 심층 탐색에는 `Task` + `subagent_type: "Explore"`로 코드베이스 검색

#### 1.3 완전성 체크

- 관련 클래스·함수·변수의 **완전한 정의와 시그니처** 확보 필수
- 컨텍스트 부족 시 **재귀 검색** 트리거
- 우선 출력: 진입 파일 + 라인 번호 + 핵심 심볼 이름. 모호함 해소에 필요할 때만 최소 코드 스니펫 추가

#### 1.4 요구사항 정렬

- 요구사항에 여전히 모호함이 있으면 **반드시** 안내 질문 출력
- 요구사항 경계가 명확해질 때까지 (누락 없음, 중복 없음)

### Phase 2: 멀티모델 협업 분석

`[Mode: Analysis]`

#### 2.1 입력 분배

**Codex와 Gemini 병렬 호출** (`run_in_background: true`):

**원본 요구사항**(사전 의견 없이) 양쪽 모델에 분배:

1. **Codex 백엔드 분석**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/analyzer.md`
   - 초점: 기술 실현 가능성·아키텍처 영향·성능 고려사항·잠재 리스크
   - OUTPUT: 다관점 솔루션 + 장단점 분석

2. **Gemini 프론트엔드 분석**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/gemini/analyzer.md`
   - 초점: UI/UX 영향·사용자 경험·시각 디자인
   - OUTPUT: 다관점 솔루션 + 장단점 분석

`TaskOutput`으로 양쪽 모델의 완전한 결과 대기. **SESSION_ID 저장** (`CODEX_SESSION`과 `GEMINI_SESSION`).

#### 2.2 교차 검증

관점 통합·최적화 반복:

1. **합의 식별** (강한 신호)
2. **분기 식별** (가중 필요)
3. **상호 보완 강점**: 백엔드 로직은 Codex, 프론트엔드 디자인은 Gemini
4. **논리 추론**: 솔루션의 논리적 공백 제거

#### 2.3 (선택, 권장) 듀얼 모델 계획 초안

Claude의 통합 계획에서 누락 리스크를 줄이기 위해 양쪽 모델이 "계획 초안"을 병렬로 출력하게 할 수 있음 (여전히 **파일 수정 불가**):

1. **Codex 계획 초안** (백엔드 권위):
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/architect.md`
   - OUTPUT: 단계별 계획 + 의사코드 (초점: 데이터 흐름·엣지 케이스·에러 처리·테스트 전략)

2. **Gemini 계획 초안** (프론트엔드 권위):
   - ROLE_FILE: `~/.claude/.ccg/prompts/gemini/architect.md`
   - OUTPUT: 단계별 계획 + 의사코드 (초점: 정보 아키텍처·상호작용·접근성·시각 일관성)

`TaskOutput`으로 양쪽 모델의 완전한 결과 대기. 제안의 핵심 차이 기록.

#### 2.4 구현 계획 생성 (Claude 최종 버전)

양쪽 분석 통합, **단계별 구현 계획** 생성:

```markdown
## Implementation Plan: <Task Name>

### Task Type
- [ ] Frontend (→ Gemini)
- [ ] Backend (→ Codex)
- [ ] Fullstack (→ Parallel)

### Technical Solution
<Codex + Gemini 분석에서 통합한 최적 솔루션>

### Implementation Steps
1. <Step 1> - 기대 산출물
2. <Step 2> - 기대 산출물
...

### Key Files
| File | Operation | Description |
|------|-----------|-------------|
| path/to/file.ts:L10-L50 | Modify | 설명 |

### Risks and Mitigation
| Risk | Mitigation |
|------|------------|

### SESSION_ID (for /ccg:execute use)
- CODEX_SESSION: <session_id>
- GEMINI_SESSION: <session_id>
```

### Phase 2 종료: 계획 전달 (실행 아님)

**`/ccg:plan`의 책임은 여기서 종료, 다음 동작 반드시 실행**:

1. 사용자에게 완전한 구현 계획 제시 (의사코드 포함)
2. 계획을 `.claude/plan/<feature-name>.md`로 저장 (요구사항에서 feature 이름 추출, 예: `user-auth`, `payment-module`)
3. **굵은 텍스트**로 프롬프트 출력 (반드시 실제 저장된 파일 경로 사용):

---
**Plan generated and saved to `.claude/plan/actual-feature-name.md`**

**Please review the plan above. You can:**
- **Modify plan**: 조정이 필요하면 알려달라, 계획 업데이트
- **Execute plan**: 다음 명령을 새 세션에 복사

```
/ccg:execute .claude/plan/actual-feature-name.md
```
---

**비고**: 위 `actual-feature-name.md`는 반드시 실제 저장된 파일명으로 교체!

4. **현재 응답 즉시 종료** (Stop here. No more tool calls.)

**절대 금지**:
- 사용자에게 "Y/N" 묻고 자동 실행 (실행은 `/ccg:execute`의 책임)
- 프로덕션 코드에 대한 어떤 쓰기 연산
- `/ccg:execute` 자동 호출 또는 어떤 구현 동작
- 사용자가 수정 명시 요청하지 않았는데 모델 호출 트리거 계속

---

## 계획 저장

계획 완료 후 다음에 저장:

- **첫 계획**: `.claude/plan/<feature-name>.md`
- **반복 버전**: `.claude/plan/<feature-name>-v2.md`, `.claude/plan/<feature-name>-v3.md`...

사용자에게 계획 제시 전에 계획 파일 쓰기 완료해야 함.

---

## 계획 수정 흐름

사용자가 계획 수정 요청 시:

1. 사용자 피드백 기반으로 계획 내용 조정
2. `.claude/plan/<feature-name>.md` 파일 업데이트
3. 수정된 계획 재제시
4. 사용자에게 다시 리뷰 또는 실행 프롬프트

---

## 다음 단계

사용자 승인 후 **수동**으로 실행:

```bash
/ccg:execute .claude/plan/<feature-name>.md
```

---

## 핵심 규칙

1. **계획만, 구현 없음** – 이 명령은 어떤 코드 변경도 실행하지 않음
2. **Y/N 프롬프트 없음** – 계획만 제시, 다음 단계는 사용자가 결정
3. **신뢰 규칙** – 백엔드는 Codex, 프론트엔드는 Gemini 따름
4. 외부 모델은 **파일시스템 쓰기 권한 0**
5. **SESSION_ID 핸드오프** – 계획 끝에 `CODEX_SESSION` / `GEMINI_SESSION` 포함 필수 (`/ccg:execute resume <SESSION_ID>`용)
