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
| 사용 대상 | ① 새 프로젝트 시작 ② 기존 운영(ITO) 코드 정비 |
| 핵심 도구 | Claude Code + Speckit + 선택 스킬 + rtk-ai |
| 개발 방식 | SDD + Speckit + TDD + Verification Loop |
| 철학 | Karpathy 4원칙 · Progressive Disclosure · Net-zero |

---

## 🎯 이 프로젝트는 무엇인가

LLM 기반 코딩 에이전트는 **모델 능력만큼이나 "하네스(harness)"의 품질**에 의해 결과가 좌우됩니다.
하네스란 에이전트가 작동하는 환경 — 즉 **규칙·메모리·검증 루프·권한 게이팅**의 총합입니다.

이 레포지토리는 그 하네스의 **재사용 가능한 기본형(template)**을 제공합니다.

- 새 프로젝트는 이 레포를 **기반 템플릿**으로 복제해 출발합니다.
- 기존 운영 코드는 이 레포의 규칙을 **점진 도입**해 같은 표준으로 끌어올립니다.

---

## 🚀 두 가지 사용 시나리오

### A. 새 프로젝트 시작 시

1. 이 레포지토리를 새 프로젝트 디렉토리로 복제 (또는 fork)
2. **`docs/rules/01-project-structure.md`를 실제 프로젝트 구조에 맞게 재작성**
   - 현재 상태는 🟡 *잠정(Tentative)* — FastAPI 예시일 뿐
   - 도메인·언어·프레임워크 확정 후 갱신
3. `CLAUDE.md` 의 절대 규칙 확인 → `/speckit.specify` 로 첫 기능 명세 시작
4. SDD 4단계(`specify → plan → tasks → implement`) 엄격 준수

### B. 기존 운영 코드 (ITO) 에 적용 시

1. 기존 레포 루트에 `CLAUDE.md`, `docs/rules/`, `.claude/skills/`, `docs/changelog/` 를 **병합 도입**
2. **현재 소스코드를 분석해 `docs/rules/01-project-structure.md`를 최신화**
   - 실제 디렉토리 구조, 사용 중인 언어/프레임워크/테스트 도구 등 반영
   - 잠정(Tentative) 라벨 제거, 실제 운영 스택 명시
3. **SDD는 신규 기능·리팩토링에만 적용** — 1-3줄 핫픽스/타이포는 SDD 생략 가능
4. `Surgical Changes` 원칙(인접 코드 "개선" 금지)을 가장 강하게 강조
5. 변경 이력은 도입 시점부터 `docs/changelog/` 에 기록 시작

---

## 🛠 사전 설치

### 필수

| 도구 | 용도 |
|---|---|
| **Claude Code** | AI 코딩 에이전트 CLI |
| **Git 2.30+** | 버전 관리 |
| **rtk-ai** | LLM 토큰 사용량 60-90% 절감 (CLI proxy) |

### 권장 스킬 (역할별 분리)

| 스킬 팩 | 출처 | 주요 역할 |
|---|---|---|
| **superpowers** | (별도 설치) | TDD, 디버깅, 코드리뷰, 서브에이전트 위임 |
| **speckit** | 본 프로젝트 `.claude/skills/speckit-*` | SDD 4단계 워크플로우 |
| **gstack** | `garrytan/gstack` | 가상 개발팀(CEO/Eng Mgr/QA/Ship) 슬래시 명령 |
| **ECC** | `affaan-m/everything-claude-code` | Python/FastAPI 패턴, 테스트, 코딩 표준 |
| **caveman** | `JuliusBrussee/caveman` (본 프로젝트 `.claude/skills/caveman/`) | 응답 압축 모드 (토큰 ~75% 절감) |

상세 매핑: `docs/rules/03-ai-agent-guidelines.md`

### 설치 명령 (예시)

```bash
# 1) rtk-ai — Rust Token Killer
#    공식 가이드: https://github.com/rtk-ai/rtk
cargo install rtk          # 또는 brew/스크립트, 리포 README 참조
rtk init -g                # Claude Code 전역 통합

# 2) 전역 스킬 설치 (~/.claude/skills/)
mkdir -p ~/.claude/skills && cd ~/.claude/skills

git clone https://github.com/garrytan/gstack.git
git clone https://github.com/affaan-m/everything-claude-code.git ECC
git clone https://github.com/JuliusBrussee/caveman.git
# superpowers / speckit 은 별도 공식 가이드 참조

# 3) 본 레포지토리는 .claude/skills/caveman/ 와 .claude/skills/speckit-* 를
#    프로젝트 로컬로 이미 포함합니다 — 추가 설치 없이 사용 가능.
```

> ⚠️ 정확한 설치 절차는 각 리포지토리의 최신 README 가 우선합니다.

---

## 🧠 개발 방식

### Speckit 4단계 (SDD)

```
/speckit.specify  →  /speckit.plan  →  /speckit.tasks  →  /speckit.implement
   (spec.md)         (plan.md)         (tasks.md)        (src/, tests/)
```

각 단계 이동 전 **사용자 확인 필수**. `tasks.md` 체크박스는 `[ ]→[x]` 로 실시간 갱신.

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

> 원전: Andrej Karpathy, X (2026-01-26).

### 하네스 엔지니어링 원칙

- **Progressive Disclosure** — 루트 `CLAUDE.md` 짧게, 상세는 `docs/rules/` 로 위임
- **Net-zero** — 새 규칙 추가 시 기존 1개 압축 (Instruction overload 방지, ~150-200개 한계)
- **Memory Tiering** — Tier 1(CLAUDE.md) → Tier 2(docs/rules) → Tier 3(docs/spec) → Tier 4(changelog)
- **Permission Gating** — 위험 작업(rm -rf, force push, DB drop)은 사용자 명시 동의 필요

상세: `docs/rules/05-context-management.md`

---

## 📂 디렉토리 구조

```
haness/
├── CLAUDE.md                  # 하네스 루트 진입점 (이 파일 먼저 읽기)
├── README.md                  # ← 여기
├── .claude/
│   └── skills/                # 프로젝트 전용 스킬 (caveman, speckit-*)
├── .specify/                  # Speckit 설정/템플릿
├── docs/
│   ├── rules/                 # 절대 규칙 (5개 파일)
│   ├── spec/                  # Speckit 스펙 (기능별, 실 프로젝트 적용 시 생성)
│   └── changelog/             # 변경 이력 로그
└── (src/, tests/)             # 실 프로젝트 적용 시 생성
```

---

## 🔒 절대 규칙 요약

`CLAUDE.md` 의 8개 항목을 항상 적용합니다.

1. `docs/rules/` 5개 파일 반드시 읽고 준수
2. Karpathy 4원칙
3. **작업 전 사용자 확인** (Human-in-the-loop)
4. SDD 단계 엄격 (스펙 없는 코드 작성 ❌)
5. 병렬/서브에이전트 위임
6. 3단계 실행 루프 (Gather → Action → Verify)
7. 변경 이력 기록 (`docs/changelog/YYYY-MM-DD-{type}-{id}.md`)
8. Caveman 모드 (응답 토큰 절감, `.claude/skills/caveman/SKILL.md`)

---

## 📚 참고 자료

- [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — 응답 압축 스킬
- [garrytan/gstack](https://github.com/garrytan/gstack) — 가상 개발팀 스킬 팩
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) — Python/패턴 스킬
- [rtk-ai/rtk](https://github.com/rtk-ai/rtk) — Rust Token Killer (CLI proxy)
- Anthropic Claude Code 베스트 프랙티스 (Gather → Action → Verify)
- HumanLayer — *Writing a good CLAUDE.md*
- Augment Code — *Harness Engineering for AI Coding Agents*

---

## 📄 라이선스 / 사용

이 명세서는 사내 표준화 및 학습 목적입니다. 외부 공개·배포 시 별도 결정.
