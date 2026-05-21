# 01-프로젝트 구조 및 아키텍처

**작성일**: 2026-05-14  
**최종 수정**: 2026-05-15

---

## 📂 프로젝트 구조

```
haness_test/
├── CLAUDE.md
├── AGENTS.md
├── pyproject.toml
├── .env.example
├── .gitignore
├── docs/
│   ├── rules/
│   ├── spec/
│   └── changelog/
├── src/
│   ├── __init__.py
│   ├── main.py              # FastAPI 진입점
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py          # 공유 의존성 주입
│   │   ├── router.py        # 라우터 어그리게이터
│   │   └── v1/
│   │       ├── __init__.py
│   │       └── endpoints/
│   │           ├── __init__.py
│   │           └── health.py
│   ├── core/
│   │   ├── __init__.py
│   │   └── config.py        # pydantic-settings 설정
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── common.py        # 공통 응답 스키마
│   │   └── health.py        # health 응답 스키마
│   └── services/
│       ├── __init__.py
│       └── health_service.py
└── tests/
    ├── __init__.py
    ├── conftest.py
    ├── test_config.py
    ├── test_schemas.py
    ├── api/
    │   ├── __init__.py
    │   └── test_health.py
    └── services/
        ├── __init__.py
        └── test_health_service.py
```

## 🏗️ 아키텍처

**확정일자**: 2026-05-15

- **기술 스택**: Python 3.11+, FastAPI, Uvicorn, pydantic-settings
- **Dependency 관리**: Poetry
- **테스트**: pytest + httpx
- **린팅**: ruff

### 아키텍처 원칙

- **순환 참조 금지**: 계층 간 단방향 의존성 유지
- **단일 책임**: 각 모듈은 하나의 명확한 책임만 가짐
- **Thin Router → Fat Service**: 라우터는 HTTP 처리만, 비즈니스 로직은 services/로 분리
- **SDD 준수**: 스펙 → 계획 → 태스크 → 구현 순서 엄격 준수
