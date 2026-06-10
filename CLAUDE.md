# CLAUDE.md — 프로젝트 진입점

이 파일은 프로젝트의 **진입점(entry point)**이자 **하네스(harness) 루트 인스트럭션**입니다.
모든 작업 전에 이 파일을 읽고, `docs/rules/`의 모든 규칙을 반드시 준수하세요.

> ⚠️ LLM은 약 150-200개 instruction까지만 안정적으로 따릅니다.
> 이 파일은 의도적으로 짧게 유지하며, 상세 규칙은 `docs/rules/`로 위임합니다 (Progressive Disclosure).

---

## 🔒 절대 규칙 (Always-on)

### 1. `docs/rules/` 작업 시작 전 반드시 읽고 준수

| 파일 | 내용 |
|---|---|
| `01-project-structure.md` | 프로젝트 구조 및 아키텍처 |
| `02-development-workflow.md` | SDD + Speckit + TDD + Verification Loop |
| `03-ai-agent-guidelines.md` | AI 에이전트/스킬 사용 가이드라인 |
| `04-change-log.md` | 변경 이력 관리 가이드 |
| `05-context-management.md` | 컨텍스트/메모리 관리 (하네스 엔지니어링) |
| `06-branch-strategy.md` | 브랜치 전략 및 PR 규칙 |
| `07-error-recovery.md` | 에러 복구 및 롤백 절차 |

### 2. Karpathy 4원칙 (LLM 실수 감소)

| 원칙 | 핵심 한 줄 (원문 요지) | 실천 |
|---|---|---|
| **Think Before Coding** | *가정하지 말고, 혼란을 숨기지 말고, tradeoff를 드러내라* | 가정 명시, 모호하면 옵션 제시, 이해 안 되면 질문 |
| **Simplicity First** | *문제를 해결하는 최소 코드, 추측은 없다* | 요청된 기능만, 추상화·과잉 옵션·불가능 상황 처리 금지 |
| **Surgical Changes** | *필요한 것만 건드리고, 너의 흔적만 치워라* | 인접 코드 "개선" 금지, 작동 코드 건드리지 않기, 기존 스타일 유지 |
| **Goal-Driven Execution** | *성공 기준을 정의하고, 검증될 때까지 반복하라* | 검증 가능한 성공 기준 정의, 테스트 먼저, 단계별 검증 |

> Tradeoff: **속도보다 신중 우선** (caution over speed). 원전: Andrej Karpathy, X (2026-01-26).

### 3. 작업 전 반드시 사용자 확인 (Human-in-the-loop)

**다음 작업은 예외 없이 `question` 툴로 확인:**
코드 생성/수정/삭제, 문서 변경, 스킬 실행, Speckit 단계 이동, 브랜치/커밋/PR.

**옵션 작성 원칙**: "진행/보류" 같은 메타 옵션 금지 → 작업 맥락에 맞는 실제 의사결정 분기로 제시.
변경 작업은 **diff/요약을 먼저 보여주고** 확인 요청.

```
options:  // 예시: 기술 선택
  - "NextAuth.js v5 (검증된 표준, 빠른 구축)"
  - "직접 JWT 구현 (학습 목적, 자유도 높음)"
  - "Clerk (외부 서비스, 가장 빠름)"
```

### 4. SDD (Spec-Driven Development) 엄격 준수

`specify → plan → tasks → implement` 순서를 엄격히 지킵니다.

**speckit 스킬 필수 사용** — 각 단계는 반드시 해당 speckit 스킬로 수행 (수동 대체 ❌):

| 단계 | 필수 스킬 |
|------|-----------|
| specify | `/speckit-specify` |
| plan | `/speckit-plan` |
| tasks | `/speckit-tasks` |
| implement | `/speckit-implement` |

**BLOCKING**: 스펙 없이 코드 작성 ❌ | 단계 건너뛰기 ❌ | plan 없이 tasks 생성 ❌ | speckit 스킬 우회(수동 작성) ❌
**필수**: 단계 이동 전 사용자 확인 ✅ | `tasks.md` 체크박스 추적 (`[ ]`→`[x]`) ✅
**예외**: 1-3줄 버그 수정, 타이포, 설정 변경만 SDD 생략 가능.

상세: `docs/rules/02-development-workflow.md`

### 5. 병렬 처리 및 서브 에이전트 위임

2개 이상의 독립 작업은 서브 에이전트에 병렬 위임. 위임 시 4가지 필수 포함:
**GOAL** (성공 기준) / **파일 경로 및 제약사항** / **기존 패턴 참조** / **IN-OUT scope**.

### 6. 하네스 엔지니어링 원칙 (2026)

**3단계 실행 루프**: `Gather Context → Take Action → Verify Results` — 매 작업마다 verify 단계 명시.

| 구성요소 | 책임 |
|---|---|
| **Context Engineering** | 컨텍스트 압축, Progressive Disclosure (`05-context-management.md`) |
| **Verification Loop** | 변경 후 테스트/타입체크/실제 실행으로 결과 검증 |
| **Permission Gating** | 위험 명령(rm -rf·force push·reset --hard·clean -fd·branch -D)은 실행 전 강제 확인 — Claude Code: `settings.json` `permissions.ask` / opencode: plugin 가드. DB drop 등 기타 파괴 작업도 사용자 명시 동의 필요 |
| **Memory Tiering** | `CLAUDE.md`(짧게) → `docs/rules/`(상세) → `docs/specs/`(작업별) → `.specify/memory/constitution.md`(프로젝트 원칙) |

### 7. 변경 이력 관리

모든 변경사항은 `docs/changelog/YYYY-MM-DD-{type}-{short-id}.md`로 기록.
상세: `docs/rules/04-change-log.md`

### 8. 출력 스타일 (Caveman — Always-on, Hook 강제)

응답 토큰 절감을 위해 **caveman full** 모드 항시 적용. Claude Code 는 `settings.json`의 UserPromptSubmit hook, opencode 는 plugin(`harness-rules.js`)이 매 턴 리마인더를 context에 주입합니다. 상세 규칙은 **`.claude/skills/caveman/SKILL.md`** 참조 (Persistence / Rules / Intensity / Auto-Clarity / Boundaries).

**기본 intensity**: `full` (SKILL.md 기본값과 동일). `lite`/`ultra`는 `/caveman lite|ultra` 전환 시 세션 대화 수준에서 적용 — 단 UserPromptSubmit 훅의 리마인더 텍스트는 정적 `[CAVEMAN FULL]`로 고정(전환해도 훅 메시지는 불변).

**한국어/프로젝트 보강** (SKILL.md 위에 덮어쓰기):
- **한국어 가독성 손상 위험 시 자동 일반 스타일** — 조사/어미가 의미를 결정하는 복잡 문장은 과도한 압축 금지
- **자동 해제 조건**: `question` 툴 옵션·설명 / 변경 diff·요약 제시
- **적용 제외**: 코드 / 커밋 메시지 / 문서(CLAUDE.md, docs/, changelog) — 정상 작성

### 9. 하네스 진입점 (orchestrator + adapt) + 2계층 에이전트 팀

- **기능 개발**: `harness-orchestrator` 스킬 자동 사용.
  트리거: "기능 만들어줘", "구현해줘", "개발 시작", "새 기능", "이어서 진행", "스펙 작성", "재실행", "업데이트", "수정", "보완"
  파이프라인: `planner → implementer → reviewer → qa` (Phase 0.5 스택 감지 + Phase 5 doc-updater 포함)
  **3축 통합**: 수직 위임 (L1→L2 전문 agent) + 수평 팬아웃 (Phase 3 기본·나머지 조건부) + 통합 머지 (dedupe·severity boost·충돌 사용자 결정). 상세 `docs/rules/03-ai-agent-guidelines.md` §3축.

- **에이전트 팀 구성**: L1 4개 (워크플로) + L2 11개 (전문 reviewer·architect·tdd-guide·doc-updater·loop-operator). 상세 `docs/rules/03`.

- **스킬 자원**: speckit 5 · harness 3 · ECC 21 (스택 패턴·테스트) · superpowers 8 (메타 워크플로) · commands 10. `[STACK]` 기반 자동 분기.

- **하네스 onboarding (1회)**: `harness-adapt` 스킬 자동 사용.
  트리거: "하네스 적용해줘", "프로젝트 분석해서 하네스 갱신", "하네스 onboarding", "기존 코드에 맞춰 하네스 수정", "하네스 init"
  setup으로 파일 복사 직후 새 세션에서 호출. 코드 분석 → CLAUDE.md / 01-project-structure.md / 03-ai-agent-guidelines.md 자동 수정.
  
---

## 🧭 빠른 안내

| 작업 | 참고 문서 |
|---|---|
| 프로젝트 구조 이해 | `docs/rules/01-project-structure.md` |
| 기능 개발 시작 | `harness-orchestrator` 스킬 (→ `docs/rules/02-development-workflow.md`) |
| 스킬/에이전트 사용 | `docs/rules/03-ai-agent-guidelines.md` |
| 변경 이력 기록 | `docs/rules/04-change-log.md` |
| 컨텍스트 관리 | `docs/rules/05-context-management.md` |
| 브랜치/PR | `docs/rules/06-branch-strategy.md` |
| 에러 복구 | `docs/rules/07-error-recovery.md` |

## 📂 프로젝트 구조
전체 디렉토리 트리는 `README.md` · `docs/rules/01-project-structure.md` 참조 (루트 always-on 부담을 줄이려 여기선 생략 — Progressive Disclosure).
