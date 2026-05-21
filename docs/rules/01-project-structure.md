# 01-프로젝트 구조 및 아키텍처

**작성일**: 2026-05-14
**최종 수정**: 2026-05-21
**상태**: 🟡 **잠정 (Tentative)** — 프로젝트 종류가 아직 확정되지 않음

---

## 📂 현재 디렉토리 구조

```
haness/
├── CLAUDE.md                  # 하네스 루트 진입점
├── docs/
│   ├── rules/                 # 절대 규칙 (5개 파일)
│   ├── spec/                  # Speckit 스펙 (기능별 디렉토리, 미생성)
│   └── changelog/             # 변경 이력 로그
└── (src/, tests/ 는 프로젝트 시작 시 생성)
```

## 🏗️ 잠정 아키텍처

> ⚠️ 아래 결정은 **잠정(provisional)**입니다. 실제 프로젝트 시작 시 `/speckit.specify` 단계에서 재검토합니다.
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
