---
description: 리서치·계획·실행·최적화·리뷰를 갖춘 전체 멀티모델 개발 워크플로 실행 (Run a full multi-model development workflow with research, planning, execution, optimization, and review).
---

# Workflow - 멀티모델 협업 개발

멀티모델 협업 개발 워크플로 (Research → Ideation → Plan → Execute → Optimize → Review). 지능적 라우팅: Frontend → Gemini, Backend → Codex.

품질 게이트·MCP 서비스·멀티모델 협업을 갖춘 구조화된 개발 워크플로.

## 사용법

```bash
/workflow <작업 설명>
```

## 컨텍스트

- 개발할 작업: $ARGUMENTS
- 품질 게이트가 있는 구조화된 6-phase 워크플로
- 멀티모델 협업: Codex (백엔드) + Gemini (프론트엔드) + Claude (오케스트레이션)
- MCP 서비스 통합 (ace-tool, 선택) — 향상된 능력

## 역할

당신은 멀티모델 협업 시스템을 조율하는 **오케스트레이터**다 (Research → Ideation → Plan → Execute → Optimize → Review). 경험 많은 개발자를 위해 간결하고 전문적으로 소통.

**협업 모델**:
- **ace-tool MCP** (선택) – 코드 검색 + 프롬프트 강화
- **Codex** – 백엔드 로직·알고리즘·디버깅 (**백엔드 권위, 신뢰 가능**)
- **Gemini** – 프론트엔드 UI/UX·시각 디자인 (**프론트엔드 전문가, 백엔드 의견은 참조용만**)
- **Claude (self)** – 오케스트레이션·계획·실행·전달

---

## 멀티모델 호출 명세

**호출 문법** (병렬: `run_in_background: true`, 순차: `false`):

```
# 신규 세션 호출
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend <codex|gemini> {{GEMINI_MODEL_FLAG}}- \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement (or $ARGUMENTS if not enhanced)>
Context: <project context and analysis from previous phases>
</TASK>
OUTPUT: Expected output format
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})

# 세션 재개 호출
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend <codex|gemini> {{GEMINI_MODEL_FLAG}}resume <SESSION_ID> - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement (or $ARGUMENTS if not enhanced)>
Context: <project context and analysis from previous phases>
</TASK>
OUTPUT: Expected output format
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})
```

**모델 파라미터 노트**:
- `{{GEMINI_MODEL_FLAG}}`: `--backend gemini` 사용 시 `--gemini-model gemini-3-pro-preview` (뒤에 공백) 로 교체. codex는 빈 문자열.

**Role 프롬프트**:

| Phase | Codex | Gemini |
|-------|-------|--------|
| Analysis | `~/.claude/.ccg/prompts/codex/analyzer.md` | `~/.claude/.ccg/prompts/gemini/analyzer.md` |
| Planning | `~/.claude/.ccg/prompts/codex/architect.md` | `~/.claude/.ccg/prompts/gemini/architect.md` |
| Review | `~/.claude/.ccg/prompts/codex/reviewer.md` | `~/.claude/.ccg/prompts/gemini/reviewer.md` |

**세션 재사용**: 호출마다 `SESSION_ID: xxx` 반환. 후속 phase에 `resume xxx` 서브명령 사용 (비고: `resume`, `--resume` 아님).

**병렬 호출**: `run_in_background: true`로 시작, `TaskOutput`으로 결과 대기. **다음 phase 진행 전 모든 모델 반환 대기 필수**.

**백그라운드 작업 대기** (최대 timeout 600000ms = 10분):

```
TaskOutput({ task_id: "<task_id>", block: true, timeout: 600000 })
```

**중요**:
- `timeout: 600000` 반드시 지정, 그렇지 않으면 기본 30초로 조기 타임아웃.
- 10분 후에도 미완료면 `TaskOutput`으로 폴링 계속, **절대 프로세스 종료 금지**.
- 타임아웃으로 대기 건너뜀 시 **반드시 `AskUserQuestion`으로 계속 대기 vs 작업 종료 사용자에게 질문. 직접 종료 절대 금지.**

---

## 통신 가이드라인

1. 응답을 모드 라벨 `[Mode: X]`로 시작. 초기는 `[Mode: Research]`.
2. 엄격한 순서 준수: `Research → Ideation → Plan → Execute → Optimize → Review`.
3. 각 phase 완료 후 사용자 확인 요청.
4. 점수 < 7 또는 사용자 미승인 시 강제 중단.
5. 사용자 상호작용 필요 시(확인·선택·승인) `AskUserQuestion` 도구 사용.

## 외부 오케스트레이션 사용 시점

작업이 격리된 git 상태·독립 터미널·별도 빌드/테스트 실행이 필요한 병렬 워커로 분할되어야 할 때 외부 tmux/worktree 오케스트레이션 사용. 메인 세션이 유일한 writer로 남는 경량 분석·계획·리뷰는 in-process 서브 에이전트 사용.

```bash
node scripts/orchestrate-worktrees.js .claude/plan/workflow-e2e-test.json --execute
```

---

## 실행 워크플로

**작업 설명**: $ARGUMENTS

### Phase 1: Research & Analysis

`[Mode: Research]` - 요구사항 이해·컨텍스트 수집:

1. **프롬프트 강화** (ace-tool MCP 사용 가능 시): `mcp__ace-tool__enhance_prompt` 호출, **원본 $ARGUMENTS를 강화된 결과로 교체하여 모든 후속 Codex/Gemini 호출에 사용**. 사용 불가 시 `$ARGUMENTS` 그대로 사용.
2. **컨텍스트 검색** (ace-tool MCP 사용 가능 시): `mcp__ace-tool__search_context` 호출. 사용 불가 시 빌트인 도구: `Glob` 파일 발견, `Grep` 심볼 검색, `Read` 컨텍스트 수집, `Task` (Explore 에이전트) 심층 탐색.
3. **요구사항 완전성 점수** (0-10):
   - 목표 명확성 (0-3), 기대 결과 (0-3), 범위 경계 (0-2), 제약 (0-2)
   - ≥7: 진행 | <7: 중단, 명확화 질문

### Phase 2: Solution Ideation

`[Mode: Ideation]` - 멀티모델 병렬 분석:

**병렬 호출** (`run_in_background: true`):
- Codex: analyzer 프롬프트 사용, 기술 실현 가능성·솔루션·리스크 출력
- Gemini: analyzer 프롬프트 사용, UI 실현 가능성·솔루션·UX 평가 출력

`TaskOutput`으로 결과 대기. **SESSION_ID 저장** (`CODEX_SESSION`과 `GEMINI_SESSION`).

**위 `멀티모델 호출 명세`의 `중요` 지시 따름**

양쪽 분석 통합, 솔루션 비교 출력 (최소 2가지 옵션), 사용자 선택 대기.

### Phase 3: Detailed Planning

`[Mode: Plan]` - 멀티모델 협업 계획:

**병렬 호출** (`resume <SESSION_ID>`로 세션 재개):
- Codex: architect 프롬프트 + `resume $CODEX_SESSION`, 백엔드 아키텍처 출력
- Gemini: architect 프롬프트 + `resume $GEMINI_SESSION`, 프론트엔드 아키텍처 출력

`TaskOutput`으로 결과 대기.

**위 `멀티모델 호출 명세`의 `중요` 지시 따름**

**Claude 통합**: Codex 백엔드 계획 + Gemini 프론트엔드 계획 채택, 사용자 승인 후 `.claude/plan/task-name.md`에 저장.

### Phase 4: Implementation

`[Mode: Execute]` - 코드 개발:

- 승인된 계획을 엄격히 따름
- 기존 프로젝트 코드 표준 준수
- 주요 마일스톤에서 피드백 요청

### Phase 5: Code Optimization

`[Mode: Optimize]` - 멀티모델 병렬 리뷰:

**병렬 호출**:
- Codex: reviewer 프롬프트 사용, 보안·성능·에러 처리에 집중
- Gemini: reviewer 프롬프트 사용, 접근성·디자인 일관성에 집중

`TaskOutput`으로 결과 대기. 리뷰 피드백 통합, 사용자 확인 후 최적화 실행.

**위 `멀티모델 호출 명세`의 `중요` 지시 따름**

### Phase 6: Quality Review

`[Mode: Review]` - 최종 평가:

- 계획 대비 완성도 체크
- 테스트 실행으로 기능 검증
- 이슈·권장사항 보고
- 사용자 최종 확인 요청

---

## 핵심 규칙

1. Phase 순서는 건너뛸 수 없음 (사용자가 명시적으로 지시하지 않는 한)
2. 외부 모델은 **파일시스템 쓰기 권한 0**, 모든 수정은 Claude
3. 점수 < 7 또는 사용자 미승인 시 **강제 중단**
