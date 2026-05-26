# `.specify/memory/` — spec-kit 메모리 디렉토리

## 파일

### `constitution.md` — 프로젝트 헌법

**역할**: spec 단위보다 상위에서 *모든* spec/plan/구현 결정이 따라야 하는 핵심 원칙·제약·정책 정의. `/speckit-specify`, `/speckit-plan` 단계에서 LLM이 자동 참조하여 모든 결정의 기준으로 활용.

**상태**: 현재 비어있는 템플릿. **프로젝트 시작 시 작성 필요**.

---

## 작성 방법

### 1. 인터랙티브 (권장)

```
/speckit-constitution
```

스킬이 프로젝트 컨텍스트 기반으로 헌법 원칙을 질문하며 작성.

### 2. 수동 편집

`.specify/memory/constitution.md` 직접 편집.

---

## 작성 예시

### 일반 백엔드 프로젝트

```markdown
## Core Principles

### I. Test-First (NON-NEGOTIABLE)
TDD 강제: 테스트 작성 → 사용자 승인 → 테스트 실패 → 구현 → Red-Green-Refactor 사이클

### II. Library-First
모든 기능은 독립 라이브러리로 시작. 라이브러리는 자체적으로 테스트 가능해야 함

### III. Spec Over Code
spec 없이 코드 작성 금지. 1-3줄 버그 수정만 예외

### IV. Observability
구조화된 로깅 필수. 모든 외부 호출은 traceable
```

### 이 하네스 프로젝트 자체에 적용한다면

```markdown
## Core Principles

### I. 에이전트와 스킬 분리 (NON-NEGOTIABLE)
에이전트 정의는 "누가", 스킬은 "어떻게". 절대 섞지 않음

### II. CLAUDE.md 200줄 제한
LLM instruction overload 방지. 상세는 docs/rules/로 위임

### III. SDD 우회 금지
1-3줄 버그 외 모든 변경은 spec → plan → tasks → implement

### IV. 진화 가능성
하네스는 고정물이 아닌 진화 시스템. 매 실행 후 피드백 반영
```

---

## 작성 시점

- **프로젝트 시작 직후** — 1회 작성
- **큰 방향 변경 시** — 개정 (예: 마이크로서비스 → 모놀리식, 도메인 추가)

## 작성 시점 가이드

| 작성 안 함 (현재 상태) | 작성 권장 |
|---|---|
| 헌법 부재 시 LLM이 일반적 베스트 프랙티스로 자체 판단 | 도메인 특수 규칙·제약 강제 필요 |
| spec마다 컨텍스트가 분명한 경우 | spec 간 일관성 강제 필요 |
| 1인 프로젝트, 짧은 수명 | 다인 협업, 장기 유지보수 |

---

## 활용 흐름

```
사용자 요청 → /speckit-specify → planner가 constitution.md 읽음
                                ↓
                  헌법 위반 시 명세 단계에서 차단 또는 명확화
                                ↓
              헌법 부합하는 spec → plan → tasks → implement
```
