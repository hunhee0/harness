# CLAUDE.md — 프로젝트 진입점

이 파일은 프로젝트의 **진입점(entry point)**이자 **하네스(harness) 루트 인스트럭션**입니다.
모든 작업 전에 이 파일을 읽고, `docs/rules/`의 모든 규칙을 반드시 준수하세요.

> ⚠️ LLM은 약 150-200개 instruction까지만 안정적으로 따릅니다.
> 이 파일은 의도적으로 짧게 유지하며, 상세 규칙은 `docs/rules/`로 위임합니다 (Progressive Disclosure).

---

## 🔒 절대 규칙 (Always-on)

### 1. `docs/rules/` 반드시 읽고 준수

| 파일 | 내용 |
|---|---|
| `01-project-structure.md` | 프로젝트 구조 및 아키텍처 |
| `02-development-workflow.md` | SDD + Speckit + TDD + Verification Loop |
| `03-ai-agent-guidelines.md` | AI 에이전트/스킬 사용 가이드라인 |
| `04-change-log.md` | 변경 이력 관리 가이드 |
| `05-context-management.md` | 컨텍스트/메모리 관리 (하네스 엔지니어링) |

### 2. Karpathy 4원칙 (LLM 실수 감소)

| 원칙 | 핵심 |
|---|---|
| **Think Before Coding** | 가정 명시, 모호하면 옵션 제시, 이해 안 되면 질문 |
| **Simplicity First** | 요청된 기능만, 추상화·과잉 옵션·불가능 상황 처리 금지 |
| **Surgical Changes** | 인접 코드 "개선" 금지, 작동 코드 건드리지 않기, 기존 스타일 유지 |
| **Goal-Driven Execution** | 검증 가능한 성공 기준 정의, 테스트 먼저, 단계별 검증 |

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

**BLOCKING**: 스펙 없이 코드 작성 ❌ | 단계 건너뛰기 ❌ | plan 없이 tasks 생성 ❌
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
| **Permission Gating** | 위험 작업(rm -rf, force push, DB drop)은 사용자 명시 동의 필요 |
| **Memory Tiering** | `CLAUDE.md`(짧게) → `docs/rules/`(상세) → `docs/spec/`(작업별) |

### 7. 변경 이력 관리

모든 변경사항은 `docs/changelog/YYYY-MM-DD-{type}-{short-id}.md`로 기록.
상세: `docs/rules/04-change-log.md`

---

## 🧭 빠른 안내

| 작업 | 참고 문서 |
|---|---|
| 프로젝트 구조 이해 | `docs/rules/01-project-structure.md` |
| 기능 개발 시작 | `docs/rules/02-development-workflow.md` |
| 스킬/에이전트 사용 | `docs/rules/03-ai-agent-guidelines.md` |
| 변경 이력 기록 | `docs/rules/04-change-log.md` |
| 컨텍스트 관리 | `docs/rules/05-context-management.md` |

## 📂 프로젝트 구조 개요

```
haness/
├── CLAUDE.md                  # ← 여기 (하네스 루트)
├── docs/
│   ├── rules/                 # 절대 규칙 (5개 파일)
│   ├── spec/                  # Speckit 스펙 (기능별 디렉토리)
│   └── changelog/             # 변경 이력 로그
├── src/                       # 소스 코드
└── tests/                     # 테스트
```
