# 01-프로젝트 구조 및 아키텍처

**작성일**: 2026-05-14
**최종 수정**: 2026-05-28
**상태**: 🟡 **잠정 (Tentative)** — 이 레포는 하네스 명세서이며, 실제 도메인 코드는 미정

---

## 📂 현재 디렉토리 구조

```
harness/
├── CLAUDE.md                              # 하네스 루트 진입점
├── README.md                              # 프로젝트 개요
├── .claude/
│   ├── agents/                            # 에이전트 팀 (L1 4 + L2 11 = 15개)
│   ├── skills/
│   │   ├── caveman/                       # 응답 토큰 압축 (always-on)
│   │   ├── harness-orchestrator/          # 기능 개발 파이프라인 진입점
│   │   ├── harness-adapt/                 # 기존 프로젝트 onboarding
│   │   ├── speckit-*/                     # SDD 5개 (constitution/specify/plan/tasks/implement)
│   │   ├── ecc/                           # 도메인 패턴·테스트 21개
│   │   └── superpowers/                   # 메타 워크플로 8개
│   ├── commands/                          # 슬래시 커맨드 10개 (gan-design, multi-*, update-*, /test-coverage 등)
│   ├── rules/
│   │   └── ecc/                           # ECC 부속 규칙 (common/java/python/typescript/web 패턴·테스트)
│   └── settings.json                      # 훅 + 권한 설정
├── .specify/
│   ├── memory/constitution.md             # 프로젝트 원칙 (시작 시 작성)
│   ├── templates/                         # Speckit 템플릿
│   └── scripts/                           # Speckit 스크립트
├── docs/
│   ├── INSTALL.md                         # 이식 + opencode 변환 가이드
│   ├── rules/                             # 절대 규칙 7개 파일 (01~07)
│   ├── specs/                             # Speckit 스펙 (기능별, 실 적용 시 생성)
│   └── changelog/                         # 변경 이력 로그
├── setup.ps1                              # Windows 이식 스크립트
├── setup.sh                               # Mac/Linux 이식 스크립트
└── (src/, tests/ 는 실 프로젝트 적용 시 생성)
```

## 🏗️ 잠정 아키텍처

> ⚠️ 아래 결정은 **잠정(provisional)**입니다. 실제 프로젝트 시작 시 `/speckit-specify` 단계에서 재검토합니다.
> FastAPI는 **예시일 뿐**이며, 실제 도메인이 정해지면 다른 스택(Django, Node.js, Next.js, Go 등)이 선택될 수 있습니다.

### 잠정 기술 스택 후보 (FastAPI 예시)

| 항목 | 잠정 값 | 비고 |
|---|---|---|
| 언어/런타임 | Python 3.11+ | 도메인 결정 후 재검토 |
| 웹 프레임워크 | FastAPI + Uvicorn | 대안: Django, Flask, Node.js, Go 등 |
| 의존성 관리 | Poetry | 대안: uv, pip-tools |
| 테스트 | pytest + httpx | 언어 변경 시 재검토 |
| 린팅/포맷 | ruff | 언어 변경 시 재검토 |

### 예시 `src/` 레이아웃 (FastAPI 기준, 채택 시)

```
src/
├── main.py              # 진입점
├── api/v1/endpoints/    # 라우터 (Thin Router)
├── core/config.py       # pydantic-settings
├── schemas/             # Pydantic 응답 모델
└── services/            # 비즈니스 로직 (Fat Service)
tests/
├── conftest.py
├── api/                 # API 통합 테스트
└── services/            # 서비스 단위 테스트
```

## 📐 아키텍처 원칙 (기술 스택과 무관, 항상 적용)

- **순환 참조 금지** — 계층 간 단방향 의존성 유지
- **단일 책임** — 각 모듈은 하나의 명확한 책임만
- **Thin Router → Fat Service** — 진입점은 입출력만, 비즈니스 로직은 분리
- **SDD 준수** — 스펙 → 계획 → 태스크 → 구현 순서 엄격 (`02-development-workflow.md`)
- **명시적 의존성** — 의존성 주입(DI) 패턴 사용, 전역 상태 최소화
