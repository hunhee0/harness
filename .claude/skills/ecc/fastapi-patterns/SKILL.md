---
name: fastapi-patterns
description: async API·DI·Pydantic 요청/응답 모델·OpenAPI 문서·테스트·보안·프로덕션 준비도용 FastAPI 패턴 (FastAPI patterns for async APIs, dependency injection, Pydantic request and response models, OpenAPI docs, tests, security, and production readiness).
origin: community
---

# FastAPI 패턴

FastAPI 서비스용 프로덕션 지향 패턴.

## 사용 시점

- FastAPI 앱 구축·리뷰.
- 라우터·스키마·의존성·DB 접근 분할.
- DB·외부 서비스를 호출하는 async 엔드포인트 작성.
- 인증·인가·OpenAPI 문서·테스트·배포 설정 추가.
- FastAPI PR을 복붙 가능 예제·프로덕션 리스크 확인.

## 동작 원리

FastAPI 앱을 명시적 의존성·서비스 코드 위의 얇은 HTTP 레이어로 취급:

- `main.py`: 앱 구성·미들웨어·예외 핸들러·라우터 등록 소유.
- `schemas/`: Pydantic 요청·응답 모델 소유.
- `dependencies.py`: DB·auth·페이지네이션·요청 스코프 의존성 소유.
- `services/` 또는 `crud/`: 비즈니스·영속화 연산 소유.
- `tests/`: 프로덕션 자원을 여는 대신 의존성 오버라이드.

작은 라우터와 명시적 `response_model` 선언 선호. 응답 스키마에 원시 ORM 객체·시크릿·프레임워크 글로벌 포함 금지.

## 프로젝트 레이아웃

```text
app/
|-- main.py
|-- config.py
|-- dependencies.py
|-- exceptions.py
|-- api/
|   `-- routes/
|       |-- users.py
|       `-- health.py
|-- core/
|   |-- security.py
|   `-- middleware.py
|-- db/
|   |-- session.py
|   `-- crud.py
|-- models/
|-- schemas/
`-- tests/
```

## 애플리케이션 팩토리

테스트·워커가 통제된 설정으로 앱 구축 가능하도록 팩토리 사용.

```python
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import health, users
from app.config import settings
from app.db.session import close_db, init_db
from app.exceptions import register_exception_handlers


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await close_db()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.api_title,
        version=settings.api_version,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=bool(settings.cors_origins),
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
    )

    register_exception_handlers(app)
    app.include_router(health.router, prefix="/health", tags=["health"])
    app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
    return app


app = create_app()
```

`allow_origins=["*"]`를 `allow_credentials=True`와 함께 사용 금지. 브라우저가 그 조합을 거부하며 Starlette는 자격증명 요청에 대해 비허용.

## Pydantic 스키마

요청·업데이트·응답 모델 분리 유지.

```python
from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserBase(BaseModel):
    email: EmailStr
    full_name: Annotated[str, Field(min_length=1, max_length=100)]


class UserCreate(UserBase):
    password: Annotated[str, Field(min_length=12, max_length=128)]


class UserUpdate(BaseModel):
    email: EmailStr | None = None
    full_name: Annotated[str | None, Field(min_length=1, max_length=100)] = None


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime
```

응답 모델에는 비밀번호 해시·액세스 토큰·refresh 토큰·내부 인가 상태 절대 포함 금지.

## 의존성

요청 스코프 자원에 의존성 주입 사용.

```python
from collections.abc import AsyncIterator
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_token
from app.db.session import session_factory
from app.models.user import User


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


async def get_db() -> AsyncIterator[AsyncSession]:
    async with session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    payload = decode_token(token)
    user_id = UUID(payload["sub"])
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    return user
```

라우트 핸들러 내부에서 세션·클라이언트·자격증명 인라인 생성 회피.

## Async 엔드포인트

라우트 핸들러가 I/O 수행 시 async 유지하고 내부에서 async 라이브러리 사용.

```python
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.user import UserResponse


router = APIRouter()


@router.get("/", response_model=list[UserResponse])
async def list_users(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(User).order_by(User.created_at.desc()).limit(limit).offset(offset)
    )
    return result.scalars().all()
```

async 핸들러에서 외부 HTTP 호출에 `httpx.AsyncClient` 사용. async 라우트에서 `requests` 호출 금지.

## 에러 처리

도메인 예외 중앙 집중·응답 모양 안정 유지.

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class ApiError(Exception):
    def __init__(self, status_code: int, code: str, message: str):
        self.status_code = status_code
        self.code = code
        self.message = message


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def api_error_handler(request: Request, exc: ApiError):
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": {"code": exc.code, "message": exc.message}},
        )
```

## OpenAPI 커스터마이징

커스텀 OpenAPI callable을 `app.openapi`에 할당. 함수를 한 번만 호출 금지.

```python
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi


def install_openapi(app: FastAPI) -> None:
    def custom_openapi():
        if app.openapi_schema:
            return app.openapi_schema
        app.openapi_schema = get_openapi(
            title="Service API",
            version="1.0.0",
            routes=app.routes,
        )
        return app.openapi_schema

    app.openapi = custom_openapi
```

## 테스팅

라우트 핸들러가 절대 참조하지 않는 내부 헬퍼가 아닌 `Depends`가 사용하는 의존성 오버라이드.

```python
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db
from app.main import create_app


@pytest.fixture
async def client(test_session: AsyncSession):
    app = create_app()

    async def override_get_db():
        yield test_session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as test_client:
        yield test_client
    app.dependency_overrides.clear()
```

## 보안 체크리스트

- `argon2-cffi`·`bcrypt`·현재 passlib 호환 hasher로 비밀번호 해시.
- JWT issuer·audience·만료·서명 알고리즘 검증.
- CORS 출처를 환경별로 유지.
- auth·쓰기 무거운 엔드포인트에 rate limit 설정.
- 모든 요청 body에 Pydantic 모델 사용.
- ORM 파라미터 바인딩 또는 SQLAlchemy Core 표현식 사용. f-string으로 SQL 절대 빌드 금지.
- 토큰·Authorization 헤더·쿠키·비밀번호를 로그에서 마스킹.
- CI에서 의존성 감사 도구 실행.

## 성능 체크리스트

- DB 커넥션 풀링 명시적 설정.
- 리스트 엔드포인트에 페이지네이션 추가.
- N+1 쿼리 주시하고 의도적으로 eager loading 사용.
- async 경로에 async HTTP/DB 클라이언트 사용.
- 페이로드 크기·CPU 트레이드오프 확인 후에만 압축 추가.
- 안정 고비용 읽기는 명시적 무효화 뒤에 캐시.

## 예시

이 예제를 패턴으로 사용. 프로젝트 전반 템플릿 X:

- 애플리케이션 팩토리: `create_app`에 미들웨어·라우터 한 번 설정.
- 스키마 분할: `UserCreate`·`UserUpdate`·`UserResponse`는 다른 책임.
- 의존성 오버라이드: 테스트가 `get_db` 직접 오버라이드.
- OpenAPI 커스터마이징: `app.openapi = custom_openapi` 할당.

## See Also

- Agent: `fastapi-reviewer`
- Command: `/fastapi-review`
- Skill: `python-patterns`
- Skill: `python-testing`
- Skill: `api-design`
