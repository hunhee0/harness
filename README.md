# haness — Claude Code 하네스 엔지니어링 명세서

> **신규 프로젝트**와 **기존 운영(ITO) 코드**에 **동일하게** 적용 가능한,
> AI 코딩 에이전트(Claude Code)를 위한 **하네스 엔지니어링 규칙 모음**입니다.
>
> 이 레포지토리는 **실행 코드를 담지 않습니다** — 오직 명세(spec)·규칙·워크플로우만 담깁니다.

---

## 📌 한 줄 요약

| 항목 | 값 |
|---|---|
| 정체 | Claude Code 하네스(harness) 명세서 |
| 사용 대상 | ① 새 프로젝트 시작 ② 기존 운영(ITO) 코드 ③ AM(유지보수) 과제 |
| 핵심 도구 | Claude Code + Speckit + 에이전트 팀 + 오케스트레이터 + rtk-ai |
| 핵심 스킬 | `harness-orchestrator` (개발 파이프라인) · `harness-adapt` (자동 onboarding) · `caveman` (토큰 절감) |
| 에이전트 팀 | `planner` → `implementer` → `reviewer` → `qa` |
| 개발 방식 | SDD + Speckit + TDD + Verification Loop |
| 철학 | Karpathy 4원칙 · Progressive Disclosure · Net-zero |

---

## 🎯 이 프로젝트는 무엇인가

LLM 기반 코딩 에이전트는 **모델 능력만큼이나 "하네스(harness)"의 품질**에 의해 결과가 좌우됩니다.
하네스란 에이전트가 작동하는 환경 — 즉 **규칙·메모리·검증 루프·권한 게이팅·에이전트 팀**의 총합입니다.

이 레포지토리는 그 하네스의 **재사용 가능한 기본형(template)**을 제공하며, 다음을 포함합니다:

- 📋 **규칙·메모리** — `CLAUDE.md` + `docs/rules/` (7개 파일)
- 🤖 **에이전트 팀** — planner → implementer → reviewer → qa (`.claude/agents/`)
- 🎯 **오케스트레이터** — `harness-orchestrator` (기능 개발 파이프라인 자동 조율)
- 🚀 **자동 onboarding** — `harness-adapt` (기존 프로젝트 분석·적응)
- 🔌 **이식 스크립트** — `setup.ps1` / `setup.sh`

적용 시나리오:
- 새 프로젝트는 이 레포를 **기반 템플릿**으로 복제해 출발
- 기존 운영 코드(ITO)는 이 레포의 규칙을 **점진 도입**
- AM(유지보수) 과제는 Surgical Changes + reviewer/qa 강제로 **회귀 리스크 최소화**

---

## 🚀 두 가지 사용 시나리오

### A. 새 프로젝트 시작 시

1. 이 레포지토리를 새 프로젝트 디렉토리로 복제 (또는 fork)
2. **`docs/rules/01-project-structure.md`를 실제 프로젝트 구조에 맞게 재작성**
   - 현재 상태는 🟡 *잠정(Tentative)* — FastAPI 예시일 뿐
   - 도메인·언어·프레임워크 확정 후 갱신
3. `CLAUDE.md` 의 절대 규칙 확인 → `/speckit-specify` 로 첫 기능 명세 시작
4. SDD 4단계(`specify → plan → tasks → implement`) 엄격 준수

### B. 기존 운영 코드 (ITO) 에 적용 시

1. 기존 레포 루트에 `CLAUDE.md`, `docs/rules/`, `.claude/skills/` 를 **병합 도입**
2. **현재 소스코드를 분석해 `docs/rules/01-project-structure.md`를 최신화**
   - 실제 디렉토리 구조, 사용 중인 언어/프레임워크/테스트 도구 등 반영
   - 잠정(Tentative) 라벨 제거, 실제 운영 스택 명시
3. **SDD는 신규 기능·리팩토링에만 적용** — 1-3줄 핫픽스/타이포는 SDD 생략 가능
4. `Surgical Changes` 원칙(인접 코드 "개선" 금지)을 가장 강하게 강조
5. 변경 이력은 도입 시점부터 `docs/changelog/` 에 기록 시작

### C. AM (유지보수) 과제에 적용 시

AM(Application Maintenance) — 유지보수·핫픽스·작은 기능 추가가 다수인 운영 과제에도 적용 가능.
**오히려 AM에 더 강한 측면**이 있음. 단, 일부 조정 권장.

#### 적합 (강점)

| 하네스 요소 | AM에서의 가치 |
|------------|---------------|
| Surgical Changes 원칙 | 인접 코드 "개선" 금지 → 회귀 리스크 최소화 (AM 1순위 요건) |
| SDD 워크플로우 | 운영 코드 즉흥 수정 방지, 스펙→계획→구현 강제 |
| Verification Loop | 테스트·타입체크·실제 실행 검증 → 회귀 조기 발견 |
| reviewer + qa agent | 스펙 준수 + 통합 정합성 이중 검증 |
| Human-in-the-loop | 모든 변경 전 사용자 확인 → 결재 라인과 자연스럽게 맞물림 |
| `docs/changelog/` 자동 기록 | 감사 추적 자료 자동 생성 |
| `harness-adapt` 스킬 | 문서 없는 레거시도 자동 분석·빠른 적응 |
| `constitution.md` | 사내 코딩 규약·금지 패턴 명문화 |

#### 주의 / 조정

| 이슈 | 조정 방안 |
|------|----------|
| 1-3줄 핫픽스 다수 → 풀 SDD는 오버헤드 | `CLAUDE.md` Rule 4 예외 기준 사내 맞춤 (예: "1줄 버그 + 회귀 영향 없는 변경"까지 확장) |
| 기존 테스트 부재 → 80% 커버리지 충족 어려움 | `agents/reviewer.md` 보강: "기존 모듈 면제, **신규/수정 라인만** 80%" |
| 사내 티켓(Jira/Redmine) 연동 부재 | changelog 파일명에 티켓 ID 포함 (`YYYY-MM-DD-fix-JIRA-1234.md`) |
| SLA · 시간 압박 | `harness-orchestrator`에 "긴급 핫픽스 모드" 추가 (planner 우회, implementer + reviewer만) |
| 사내 결재 · 머지 정책 | `docs/rules/06-branch-strategy.md`를 사내 정책으로 덮어쓰기 |
| touch 금지 모듈 (운영 안전 영역) | `.specify/memory/constitution.md`에 "수정 금지 모듈" 명시 |

#### 효용 낮은 케이스

- 코드 변경 거의 없음 (설정·데이터 운영만)
- 사내 AM 워크플로우가 이미 강하게 정해져 있고 LLM 개입 여지 없음

> 옵션: **`am-mode` 스킬 신설 가능** — 긴급 핫픽스 모드 (planner 우회, surgical only) + 티켓 ID 자동 매핑. 필요 시 별도 요청.

---

## 🔌 이식 / 변환 가이드

다른 프로젝트에 이 하네스를 빠르게 복사하거나, opencode 환경으로 변환할 때는 다음 스크립트·가이드 사용:

```powershell
# Windows
.\setup.ps1 -TargetDir "C:\path\to\new-project"

# Mac / Linux
./setup.sh /path/to/new-project
```

- **Claude Code 환경**: 자동 복사 (에이전트·스킬·규칙·Speckit 자원·훅)
- **opencode 환경**: 디렉토리 매핑 + frontmatter 변환 + 스킬→command 변환 필요
- **이식 후 수정 필수**: `CLAUDE.md`, `.specify/memory/constitution.md`, `docs/rules/01-project-structure.md`

상세 (DryRun, 트러블슈팅, opencode 매핑표 등): **`docs/INSTALL.md`**

---

## 🛠 사전 설치

### 필수

| 도구 | 용도 |
|---|---|
| **Claude Code** | AI 코딩 에이전트 CLI |
| **Git 2.30+** | 버전 관리 |

### 권장 스킬 (역할별 분리)

| 스킬 팩 | 출처 | 주요 역할 |
|---|---|---|
| **superpowers** | `obra/superpowers` | TDD, 디버깅, 코드리뷰, 서브에이전트 위임 |
| **speckit** | `github/spec-kit` | SDD 4단계 워크플로우 |
| **gstack** | `garrytan/gstack` | 가상 개발팀(CEO/Eng Mgr/QA/Ship) 슬래시 명령 |
| **ECC** | `affaan-m/everything-claude-code` | Python/FastAPI 패턴, 테스트, 코딩 표준 |
| **caveman** | `JuliusBrussee/caveman` (본 프로젝트 `.claude/skills/caveman/`) | 응답 압축 모드 (토큰 ~75% 절감) |
| **rtk-ai** | `rtk-ai/rtk` | LLM 토큰 사용량 60-90% 절감 (CLI proxy) |
| **harness-orchestrator** | 본 프로젝트 (`.claude/skills/`) | 기능 개발 파이프라인 자동 조율 (planner → implementer → reviewer → qa) |
| **harness-adapt** | 본 프로젝트 (`.claude/skills/`) | 기존 프로젝트 자동 분석·적응 (onboarding) |

상세 매핑: `docs/rules/03-ai-agent-guidelines.md`

### 설치 명령 (예시)

```bash
# 1) rtk-ai — Rust Token Killer
#    공식 가이드: https://github.com/rtk-ai/rtk
cargo install rtk          # 또는 brew/스크립트, 리포 README 참조
rtk init -g                # Claude Code 전역 통합

# 2) 전역 스킬 설치 (~/.claude/skills/)
mkdir -p ~/.claude/skills && cd ~/.claude/skills

# 별도 공식 가이드 참조
https://github.com/garrytan/gstack.git
https://github.com/affaan-m/everything-claude-code.git
https://github.com/JuliusBrussee/caveman.git
https://github.com/obra/superpowers
https://github.com/github/spec-kit
https://github.com/multica-ai/andrej-karpathy-skills
https://github.com/rtk-ai/rtk

# 3) 본 레포지토리는 다음을 프로젝트 로컬로 이미 포함합니다 — 추가 설치 없이 사용 가능:
#    - .claude/skills/speckit-*             (Speckit 4단계 스킬)
#    - .claude/skills/caveman               (응답 압축)
#    - .claude/skills/harness-orchestrator  (개발 파이프라인 조율)
#    - .claude/skills/harness-adapt         (기존 프로젝트 자동 적응)
#    - .claude/agents/                      (planner / implementer / reviewer / qa)
```

> ⚠️ 정확한 설치 절차는 각 리포지토리의 최신 README 가 우선합니다.

---

## 🧠 개발 방식

### Speckit 4단계 (SDD)

```
/speckit-specify  →  /speckit-plan  →  /speckit-tasks  →  /speckit-implement
   (spec.md)         (plan.md)         (tasks.md)        (src/, tests/)
```

각 단계 이동 전 **사용자 확인 필수**. `tasks.md` 체크박스는 `[ ]→[x]` 로 실시간 갱신.

### 에이전트 파이프라인 (harness-orchestrator)

기능 개발 요청 시 `harness-orchestrator` 스킬이 자동 트리거되어 4개 에이전트를 순서대로 호출:

```
planner  →  implementer  →  reviewer  →  qa
(specs/plan/    (TDD 구현)     (스펙 준수 +     (통합 정합성 +
 tasks 생성)                  코드 품질)       엣지 케이스)
```

각 에이전트 정의는 `.claude/agents/{name}.md`. 오케스트레이터가 단계 간 산출물 전달·에러 핸들링·재시도 관리.
도메인 특화 에이전트(예: ML의 `data-validator`, 보안중점의 `security-reviewer`)는 `harness-adapt`가 분석 후 자동 권장.

### Verification Loop (3단계 실행 루프)

```
1. Gather Context  →  2. Take Action  →  3. Verify Results
   (관련 파일 수집)      (변경 실행)         (테스트/타입체크/실제 실행)
```

**검증 없는 완료 보고 금지**. UI/프론트엔드는 타입체크 통과만으로 완료 판단 금지 — 실제 실행 확인 필수.

상세: `docs/rules/02-development-workflow.md`

---

## 📐 핵심 철학

### Karpathy 4원칙 (LLM 실수 감소)

| 원칙 | 실천 |
|---|---|
| Think Before Coding | 가정 명시, 모호하면 옵션 제시 |
| Simplicity First | 요청된 기능만, 과잉 추상화 금지 |
| Surgical Changes | 인접 코드 "개선" 금지, 작동 코드 미수정 |
| Goal-Driven Execution | 검증 가능한 성공 기준, 단계별 검증 |

### 하네스 엔지니어링 원칙

- **Progressive Disclosure** — 루트 `CLAUDE.md` 짧게, 상세는 `docs/rules/` 로 위임
- **Net-zero** — 새 규칙 추가 시 기존 1개 압축 (Instruction overload 방지, ~150-200개 한계)
- **Memory Tiering** — Tier 1(CLAUDE.md) → Tier 2(docs/rules) → Tier 3(docs/specs) → Tier 4(changelog)
- **Permission Gating** — 위험 작업(rm -rf, force push, DB drop)은 사용자 명시 동의 필요

상세: `docs/rules/05-context-management.md`

---

## 📂 디렉토리 구조

```
haness/
├── CLAUDE.md                        # 하네스 루트 진입점 (이 파일 먼저 읽기)
├── README.md                        # ← 여기
├── .claude/
│   ├── agents/                      # 에이전트 팀 (planner / implementer / reviewer / qa)
│   ├── skills/                      # 프로젝트 전용 스킬
│   │   ├── caveman/                 # 응답 토큰 절감
│   │   ├── speckit-*/               # SDD 4단계 스킬
│   │   ├── harness-orchestrator/    # 기능 개발 파이프라인 조율
│   │   └── harness-adapt/           # 기존 프로젝트 자동 적응
│   └── settings.json                # 훅 + 플러그인 설정
├── .specify/
│   ├── memory/
│   │   ├── constitution.md          # 프로젝트 헌법 (시작 시 작성)
│   │   └── README.md                # 헌법 작성 가이드
│   ├── templates/, scripts/, integrations/   # Speckit 자원
│   └── *.json                       # Speckit 설정
├── docs/
│   ├── INSTALL.md                   # 이식 + opencode 변환 가이드
│   ├── rules/                       # 절대 규칙 (7개 파일)
│   ├── specs/                        # Speckit 스펙 (기능별, 실 프로젝트 적용 시 생성)
│   └── changelog/                   # 변경 이력 로그
├── setup.ps1                        # 하네스 이식 스크립트 (Windows)
├── setup.sh                         # 하네스 이식 스크립트 (Mac / Linux)
└── (src/, tests/)                   # 실 프로젝트 적용 시 생성
```

---

## 🔒 절대 규칙 요약

`CLAUDE.md` 의 9개 항목을 항상 적용합니다.

1. `docs/rules/` 7개 파일 반드시 읽고 준수
2. Karpathy 4원칙
3. **작업 전 사용자 확인** (Human-in-the-loop)
4. SDD 단계 엄격 (스펙 없는 코드 작성 ❌)
5. 병렬/서브에이전트 위임
6. 3단계 실행 루프 (Gather → Action → Verify)
7. 변경 이력 기록 (`docs/changelog/YYYY-MM-DD-{type}-{id}.md`)
8. Caveman 모드 (응답 토큰 절감, `.claude/skills/caveman/SKILL.md`)
9. **하네스 진입점** — 기능 개발은 `harness-orchestrator`, 기존 프로젝트 적응은 `harness-adapt` 자동 사용

---

## 📚 참고 자료

- [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — 응답 압축 스킬
- [garrytan/gstack](https://github.com/garrytan/gstack) — 가상 개발팀 스킬 팩
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) — Python/패턴 스킬
- [rtk-ai/rtk](https://github.com/rtk-ai/rtk) — Rust Token Killer (CLI proxy)
- Anthropic Claude Code 베스트 프랙티스 (Gather → Action → Verify)
- HumanLayer — *Writing a good CLAUDE.md*
- Augment Code — *Harness Engineering for AI Coding Agents*
