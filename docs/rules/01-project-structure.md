# 01. 프로젝트 구조

## 폴더 구조





```
haness/
├── CLAUDE.md              # 진입점 (라우팅)
├── docs/
│   ├── rules/             # 절대 규칙 (이 폴더)
│   ├── spec/              # SDD 산출물
│   │   └── {NNN-feature}/ # spec.md, plan.md, tasks.md
│   └── changelog/         # YYYY-MM-DD-{type}-{slug}.md
├── src/
│   ├── routers/           # FastAPI 엔드포인트
│   ├── schemas/           # Pydantic 모델
│   ├── services/          # 비즈니스 로직
│   ├── config/            # 환경 설정
│   └── main.py            # FastAPI 앱 진입점
├── tests/                 # src와 동일 구조 (test_*.py)
├── pyproject.toml         # Poetry 의존성
└── .env.example           # 환경 변수 템플릿
```









## 계층 책임

| 계층 | 책임 | 허용 의존 |
|---|---|---|
| `routers/` | HTTP I/O, 요청 검증 위임, 응답 직렬화 | `schemas/`, `services/` |
| `schemas/` | 데이터 모델, 검증 규칙 (Pydantic) | (없음) |
| `services/` | 비즈니스 로직, 외부 호출 | `schemas/`, `config/` |
| `config/` | 환경 변수, 상수, settings | (없음) |

## 의존 방향 (BLOCKING)





```
routers → services → schemas
   ↓         ↓
schemas   config
```







- `schemas`는 어디서든 import 가능
- `services`는 `routers` import 금지 (역방향 의존 금지)
- 순환 의존 발견 시 즉시 리팩터링

## 명명 규칙

| 종류 | 규칙 | 예 |
|---|---|---|
| 파일 | `snake_case.py` | `user_router.py` |
| 클래스 | `PascalCase` | `UserService` |
| 함수/변수 | `snake_case` | `get_user_by_id` |
| 상수 | `UPPER_SNAKE_CASE` | `MAX_RETRY` |
| 라우터 | `{resource}_router.py` | `health_router.py` |
| 스키마 | `{resource}_schema.py` | `user_schema.py` |
| 서비스 | `{resource}_service.py` | `auth_service.py` |
| 테스트 | `test_{module}.py` | `test_user_service.py` |

## 폴더 추가 시 규칙

- 새 폴더는 `__init__.py` 포함
- 책임이 위 4계층 어디에도 안 들어가면 → 신규 계층 추가 전에 사용자 확인 필수
