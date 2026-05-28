---
description: API·알고리즘·데이터·비즈니스 로직을 위한 백엔드 중심 멀티모델 워크플로 실행 (Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic).
---

# Backend - 백엔드 중심 개발

백엔드 중심 워크플로 (Research → Ideation → Plan → Execute → Optimize → Review). Codex 주도.

## 사용법

```bash
/backend <백엔드 작업 설명>
```

## 컨텍스트

- 백엔드 작업: $ARGUMENTS
- Codex 주도, Gemini는 보조 참조
- 적용 영역: API 설계, 알고리즘 구현, DB 최적화, 비즈니스 로직

## 역할

당신은 서버 사이드 작업을 위해 멀티모델 협업을 조율하는 **백엔드 오케스트레이터**다 (Research → Ideation → Plan → Execute → Optimize → Review).

**협업 모델**:
- **Codex** – 백엔드 로직·알고리즘 (**백엔드 권위, 신뢰 가능**)
- **Gemini** – 프론트엔드 관점 (**백엔드 의견은 참조용만**)
- **Claude (self)** – 오케스트레이션·계획·실행·전달

---

## 멀티모델 호출 명세

**호출 문법**:

```
# 신규 세션 호출
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend codex - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement (or $ARGUMENTS if not enhanced)>
Context: <project context and analysis from previous phases>
</TASK>
OUTPUT: Expected output format
EOF",
  run_in_background: false,
  timeout: 3600000,
  description: "Brief description"
})

# 세션 재개 호출
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend codex resume <SESSION_ID> - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement (or $ARGUMENTS if not enhanced)>
Context: <project context and analysis from previous phases>
</TASK>
OUTPUT: Expected output format
EOF",
  run_in_background: false,
  timeout: 3600000,
  description: "Brief description"
})
```

**Role 프롬프트**:

| Phase | Codex |
|-------|-------|
| Analysis | `~/.claude/.ccg/prompts/codex/analyzer.md` |
| Planning | `~/.claude/.ccg/prompts/codex/architect.md` |
| Review | `~/.claude/.ccg/prompts/codex/reviewer.md` |

**세션 재사용**: 호출마다 `SESSION_ID: xxx` 반환. 후속 phase에 `resume xxx` 사용. Phase 2에서 `CODEX_SESSION` 저장, Phase 3·5에서 `resume` 사용.

---

## 통신 가이드라인

1. 응답을 모드 라벨 `[Mode: X]`로 시작. 초기는 `[Mode: Research]`
2. 엄격한 순서 준수: `Research → Ideation → Plan → Execute → Optimize → Review`
3. 사용자 상호작용 필요 시(확인·선택·승인) `AskUserQuestion` 도구 사용

---

## 핵심 워크플로

### Phase 0: 프롬프트 강화 (선택)

`[Mode: Prepare]` - ace-tool MCP 사용 가능 시 `mcp__ace-tool__enhance_prompt` 호출, **원본 $ARGUMENTS를 강화된 결과로 교체하여 후속 Codex 호출에 사용**. 사용 불가능하면 `$ARGUMENTS` 그대로 사용.

### Phase 1: Research

`[Mode: Research]` - 요구사항 이해·컨텍스트 수집

1. **코드 검색** (ace-tool MCP 사용 가능 시): `mcp__ace-tool__search_context` 호출로 기존 API·데이터 모델·서비스 아키텍처 검색. 사용 불가 시 빌트인 도구 사용: `Glob` 파일 발견, `Grep` 심볼/API 검색, `Read` 컨텍스트 수집, `Task` (Explore 에이전트) 심층 탐색.
2. 요구사항 완전성 점수 (0-10): >=7 진행, <7 중단·보충

### Phase 2: Ideation

`[Mode: Ideation]` - Codex 주도 분석

**Codex 반드시 호출** (위 호출 명세 따름):
- ROLE_FILE: `~/.claude/.ccg/prompts/codex/analyzer.md`
- Requirement: 강화된 요구사항 (강화 안 됨이면 $ARGUMENTS)
- Context: Phase 1의 프로젝트 컨텍스트
- OUTPUT: 기술적 실현 가능성 분석, 권장 솔루션 (최소 2개), 리스크 평가

**SESSION_ID 저장** (`CODEX_SESSION`) — 후속 phase 재사용용.

솔루션 출력 (최소 2개), 사용자 선택 대기.

### Phase 3: Planning

`[Mode: Plan]` - Codex 주도 계획

**Codex 반드시 호출** (`resume <CODEX_SESSION>`로 세션 재사용):
- ROLE_FILE: `~/.claude/.ccg/prompts/codex/architect.md`
- Requirement: 사용자가 선택한 솔루션
- Context: Phase 2의 분석 결과
- OUTPUT: 파일 구조·함수/클래스 설계·의존 관계

Claude가 계획 통합, 사용자 승인 후 `.claude/plan/task-name.md`로 저장.

### Phase 4: Implementation

`[Mode: Execute]` - 코드 개발

- 승인된 계획을 엄격히 따름
- 기존 프로젝트 코드 표준 준수
- 에러 처리·보안·성능 최적화 보장

### Phase 5: Optimization

`[Mode: Optimize]` - Codex 주도 리뷰

**Codex 반드시 호출** (위 호출 명세 따름):
- ROLE_FILE: `~/.claude/.ccg/prompts/codex/reviewer.md`
- Requirement: 다음 백엔드 코드 변경 리뷰
- Context: git diff 또는 코드 내용
- OUTPUT: 보안·성능·에러 처리·API 준수 이슈 목록

리뷰 피드백 통합, 사용자 확인 후 최적화 실행.

### Phase 6: Quality Review

`[Mode: Review]` - 최종 평가

- 계획 대비 완성도 체크
- 테스트 실행으로 기능 검증
- 이슈·권장사항 보고

---

## 핵심 규칙

1. **Codex의 백엔드 의견은 신뢰 가능**
2. **Gemini의 백엔드 의견은 참조용만**
3. 외부 모델은 **파일시스템 쓰기 권한 0**
4. 모든 코드 쓰기·파일 연산은 Claude가 처리
