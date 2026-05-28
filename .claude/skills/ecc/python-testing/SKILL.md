---
name: python-testing
description: pytest·TDD 방법론·픽스처·모킹·파라미터화·커버리지 요구사항을 사용하는 Python 테스팅 전략 (Python testing strategies using pytest, TDD methodology, fixtures, mocking, parametrization, and coverage requirements).
origin: ECC
---

# Python 테스팅 패턴

pytest·TDD 방법론·모범 사례를 사용하는 Python 애플리케이션용 포괄적 테스팅 전략.

## 활성화 시점

- 새 Python 코드 작성 (TDD 따름: red·green·refactor)
- Python 프로젝트용 테스트 스위트 설계
- Python 테스트 커버리지 리뷰
- 테스팅 인프라 셋업

## 핵심 테스팅 철학

### TDD

항상 TDD 사이클 따름:

1. **RED**: 원하는 동작에 대한 실패하는 테스트 작성
2. **GREEN**: 테스트를 통과시킬 최소 코드 작성
3. **REFACTOR**: 테스트 green 유지하며 코드 개선

```python
# Step 1: 실패 테스트 작성 (RED)
def test_add_numbers():
    result = add(2, 3)
    assert result == 5

# Step 2: 최소 구현 (GREEN)
def add(a, b):
    return a + b

# Step 3: 필요 시 리팩토링 (REFACTOR)
```

### 커버리지 요구사항

- **목표**: 80%+ 코드 커버리지
- **중요 경로**: 100% 커버리지 필요
- `pytest --cov`로 커버리지 측정

```bash
pytest --cov=mypackage --cov-report=term-missing --cov-report=html
```

## pytest 기초

### 기본 테스트 구조

```python
import pytest

def test_addition():
    """기본 덧셈 테스트."""
    assert 2 + 2 == 4

def test_string_uppercase():
    """문자열 대문자화 테스트."""
    text = "hello"
    assert text.upper() == "HELLO"

def test_list_append():
    """리스트 append 테스트."""
    items = [1, 2, 3]
    items.append(4)
    assert 4 in items
    assert len(items) == 4
```

### 단언

```python
# 동등
assert result == expected

# 부등
assert result != unexpected

# Truthiness
assert result  # Truthy
assert not result  # Falsy
assert result is True  # 정확히 True
assert result is False  # 정확히 False
assert result is None  # 정확히 None

# 멤버십
assert item in collection
assert item not in collection

# 비교
assert result > 0
assert 0 <= result <= 100

# 타입 체크
assert isinstance(result, str)

# 예외 테스트 (선호 접근)
with pytest.raises(ValueError):
    raise ValueError("error message")

# 예외 메시지 체크
with pytest.raises(ValueError, match="invalid input"):
    raise ValueError("invalid input provided")

# 예외 속성 체크
with pytest.raises(ValueError) as exc_info:
    raise ValueError("error message")
assert str(exc_info.value) == "error message"
```

## Fixture

### 기본 fixture 사용

```python
import pytest

@pytest.fixture
def sample_data():
    """샘플 데이터 제공 fixture."""
    return {"name": "Alice", "age": 30}

def test_sample_data(sample_data):
    """fixture 사용 테스트."""
    assert sample_data["name"] == "Alice"
    assert sample_data["age"] == 30
```

### setup/teardown 있는 fixture

```python
@pytest.fixture
def database():
    """setup·teardown 있는 fixture."""
    # Setup
    db = Database(":memory:")
    db.create_tables()
    db.insert_test_data()

    yield db  # 테스트에 제공

    # Teardown
    db.close()

def test_database_query(database):
    """DB 연산 테스트."""
    result = database.query("SELECT * FROM users")
    assert len(result) > 0
```

### Fixture 스코프

```python
# 함수 스코프 (기본) - 각 테스트마다 실행
@pytest.fixture
def temp_file():
    with open("temp.txt", "w") as f:
        yield f
    os.remove("temp.txt")

# 모듈 스코프 - 모듈당 한 번
@pytest.fixture(scope="module")
def module_db():
    db = Database(":memory:")
    db.create_tables()
    yield db
    db.close()

# 세션 스코프 - 테스트 세션당 한 번
@pytest.fixture(scope="session")
def shared_resource():
    resource = ExpensiveResource()
    yield resource
    resource.cleanup()
```

### 파라미터 있는 fixture

```python
@pytest.fixture(params=[1, 2, 3])
def number(request):
    """파라미터화 fixture."""
    return request.param

def test_numbers(number):
    """각 파라미터마다 한 번씩 3번 실행."""
    assert number > 0
```

### 다중 fixture 사용

```python
@pytest.fixture
def user():
    return User(id=1, name="Alice")

@pytest.fixture
def admin():
    return User(id=2, name="Admin", role="admin")

def test_user_admin_interaction(user, admin):
    """다중 fixture 사용 테스트."""
    assert admin.can_manage(user)
```

### Autouse fixture

```python
@pytest.fixture(autouse=True)
def reset_config():
    """모든 테스트 전 자동 실행."""
    Config.reset()
    yield
    Config.cleanup()

def test_without_fixture_call():
    # reset_config 자동 실행
    assert Config.get_setting("debug") is False
```

### 공유 fixture용 Conftest.py

```python
# tests/conftest.py
import pytest

@pytest.fixture
def client():
    """모든 테스트용 공유 fixture."""
    app = create_app(testing=True)
    with app.test_client() as client:
        yield client

@pytest.fixture
def auth_headers(client):
    """API 테스팅용 auth 헤더 생성."""
    response = client.post("/api/login", json={
        "username": "test",
        "password": "test"
    })
    token = response.json["token"]
    return {"Authorization": f"Bearer {token}"}
```

## 파라미터화

### 기본 파라미터화

```python
@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
    ("PyThOn", "PYTHON"),
])
def test_uppercase(input, expected):
    """다른 입력으로 3번 실행."""
    assert input.upper() == expected
```

### 다중 파라미터

```python
@pytest.mark.parametrize("a,b,expected", [
    (2, 3, 5),
    (0, 0, 0),
    (-1, 1, 0),
    (100, 200, 300),
])
def test_add(a, b, expected):
    """다중 입력으로 덧셈 테스트."""
    assert add(a, b) == expected
```

### ID 있는 파라미터화

```python
@pytest.mark.parametrize("input,expected", [
    ("valid@email.com", True),
    ("invalid", False),
    ("@no-domain.com", False),
], ids=["valid-email", "missing-at", "missing-domain"])
def test_email_validation(input, expected):
    """가독 가능 테스트 ID로 이메일 검증 테스트."""
    assert is_valid_email(input) is expected
```

### 파라미터화 fixture

```python
@pytest.fixture(params=["sqlite", "postgresql", "mysql"])
def db(request):
    """다중 DB 백엔드 대상 테스트."""
    if request.param == "sqlite":
        return Database(":memory:")
    elif request.param == "postgresql":
        return Database("postgresql://localhost/test")
    elif request.param == "mysql":
        return Database("mysql://localhost/test")

def test_database_operations(db):
    """각 DB마다 한 번씩 3번 실행."""
    result = db.query("SELECT 1")
    assert result is not None
```

## 마커·테스트 선택

### 커스텀 마커

```python
# 느린 테스트 표시
@pytest.mark.slow
def test_slow_operation():
    time.sleep(5)

# 통합 테스트 표시
@pytest.mark.integration
def test_api_integration():
    response = requests.get("https://api.example.com")
    assert response.status_code == 200

# 단위 테스트 표시
@pytest.mark.unit
def test_unit_logic():
    assert calculate(2, 3) == 5
```

### 특정 테스트 실행

```bash
# 빠른 테스트만
pytest -m "not slow"

# 통합 테스트만
pytest -m integration

# 통합 또는 느린 테스트
pytest -m "integration or slow"

# unit 표시되었지만 slow는 아닌 테스트
pytest -m "unit and not slow"
```

### pytest.ini의 마커 설정

```ini
[pytest]
markers =
    slow: 느린 테스트 표시
    integration: 통합 테스트 표시
    unit: 단위 테스트 표시
    django: Django 필요 테스트 표시
```

## 모킹·패칭

### 함수 모킹

```python
from unittest.mock import patch, Mock

@patch("mypackage.external_api_call")
def test_with_mock(api_call_mock):
    """모킹된 외부 API로 테스트."""
    api_call_mock.return_value = {"status": "success"}

    result = my_function()

    api_call_mock.assert_called_once()
    assert result["status"] == "success"
```

### 반환 값 모킹

```python
@patch("mypackage.Database.connect")
def test_database_connection(connect_mock):
    """모킹된 DB 연결로 테스트."""
    connect_mock.return_value = MockConnection()

    db = Database()
    db.connect()

    connect_mock.assert_called_once_with("localhost")
```

### 예외 모킹

```python
@patch("mypackage.api_call")
def test_api_error_handling(api_call_mock):
    """모킹된 예외로 에러 처리 테스트."""
    api_call_mock.side_effect = ConnectionError("Network error")

    with pytest.raises(ConnectionError):
        api_call()

    api_call_mock.assert_called_once()
```

### 컨텍스트 매니저 모킹

```python
@patch("builtins.open", new_callable=mock_open)
def test_file_reading(mock_file):
    """모킹된 open으로 파일 읽기 테스트."""
    mock_file.return_value.read.return_value = "file content"

    result = read_file("test.txt")

    mock_file.assert_called_once_with("test.txt", "r")
    assert result == "file content"
```

### Autospec 사용

```python
@patch("mypackage.DBConnection", autospec=True)
def test_autospec(db_mock):
    """API 오용 잡기 위한 autospec 테스트."""
    db = db_mock.return_value
    db.query("SELECT * FROM users")

    # DBConnection에 query 메서드 없으면 실패
    db_mock.assert_called_once()
```

### Mock 클래스 인스턴스

```python
class TestUserService:
    @patch("mypackage.UserRepository")
    def test_create_user(self, repo_mock):
        """모킹된 리포지토리로 사용자 생성 테스트."""
        repo_mock.return_value.save.return_value = User(id=1, name="Alice")

        service = UserService(repo_mock.return_value)
        user = service.create_user(name="Alice")

        assert user.name == "Alice"
        repo_mock.return_value.save.assert_called_once()
```

### Mock 프로퍼티

```python
@pytest.fixture
def mock_config():
    """프로퍼티 있는 mock 생성."""
    config = Mock()
    type(config).debug = PropertyMock(return_value=True)
    type(config).api_key = PropertyMock(return_value="test-key")
    return config

def test_with_mock_config(mock_config):
    """모킹된 config 프로퍼티로 테스트."""
    assert mock_config.debug is True
    assert mock_config.api_key == "test-key"
```

## Async 코드 테스팅

### pytest-asyncio로 async 테스트

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    """async 함수 테스트."""
    result = await async_add(2, 3)
    assert result == 5

@pytest.mark.asyncio
async def test_async_with_fixture(async_client):
    """async fixture로 async 테스트."""
    response = await async_client.get("/api/users")
    assert response.status_code == 200
```

### Async fixture

```python
@pytest.fixture
async def async_client():
    """async test client 제공 async fixture."""
    app = create_app()
    async with app.test_client() as client:
        yield client

@pytest.mark.asyncio
async def test_api_endpoint(async_client):
    """async fixture 사용 테스트."""
    response = await async_client.get("/api/data")
    assert response.status_code == 200
```

### Async 함수 모킹

```python
@pytest.mark.asyncio
@patch("mypackage.async_api_call")
async def test_async_mock(api_call_mock):
    """mock으로 async 함수 테스트."""
    api_call_mock.return_value = {"status": "ok"}

    result = await my_async_function()

    api_call_mock.assert_awaited_once()
    assert result["status"] == "ok"
```

## 예외 테스팅

### 예상 예외 테스팅

```python
def test_divide_by_zero():
    """0으로 나누면 ZeroDivisionError 발생 테스트."""
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

def test_custom_exception():
    """메시지 있는 커스텀 예외 테스트."""
    with pytest.raises(ValueError, match="invalid input"):
        validate_input("invalid")
```

### 예외 속성 테스팅

```python
def test_exception_with_details():
    """커스텀 속성 있는 예외 테스트."""
    with pytest.raises(CustomError) as exc_info:
        raise CustomError("error", code=400)

    assert exc_info.value.code == 400
    assert "error" in str(exc_info.value)
```

## 사이드 이펙트 테스팅

### 파일 연산 테스팅

```python
import tempfile
import os

def test_file_processing():
    """temp 파일로 파일 처리 테스트."""
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
        f.write("test content")
        temp_path = f.name

    try:
        result = process_file(temp_path)
        assert result == "processed: test content"
    finally:
        os.unlink(temp_path)
```

### pytest의 tmp_path Fixture로 테스팅

```python
def test_with_tmp_path(tmp_path):
    """pytest 빌트인 temp 경로 fixture 사용 테스트."""
    test_file = tmp_path / "test.txt"
    test_file.write_text("hello world")

    result = process_file(str(test_file))
    assert result == "hello world"
    # tmp_path 자동 정리
```

### tmpdir Fixture로 테스팅

```python
def test_with_tmpdir(tmpdir):
    """pytest tmpdir fixture 사용 테스트."""
    test_file = tmpdir.join("test.txt")
    test_file.write("data")

    result = process_file(str(test_file))
    assert result == "data"
```

## 테스트 구성

### 디렉터리 구조

```
tests/
├── conftest.py                 # 공유 fixture
├── __init__.py
├── unit/                       # 단위 테스트
│   ├── __init__.py
│   ├── test_models.py
│   ├── test_utils.py
│   └── test_services.py
├── integration/                # 통합 테스트
│   ├── __init__.py
│   ├── test_api.py
│   └── test_database.py
└── e2e/                        # End-to-end 테스트
    ├── __init__.py
    └── test_user_flow.py
```

### 테스트 클래스

```python
class TestUserService:
    """관련 테스트를 클래스에 그룹화."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """이 클래스의 각 테스트 전 setup 실행."""
        self.service = UserService()

    def test_create_user(self):
        """사용자 생성 테스트."""
        user = self.service.create_user("Alice")
        assert user.name == "Alice"

    def test_delete_user(self):
        """사용자 삭제 테스트."""
        user = User(id=1, name="Bob")
        self.service.delete_user(user)
        assert not self.service.user_exists(1)
```

## 모범 사례

### DO

- **TDD 따름**: 코드 전에 테스트 작성 (red-green-refactor)
- **하나만 테스트**: 각 테스트가 단일 동작 검증
- **서술적 이름**: `test_user_login_with_invalid_credentials_fails`
- **fixture 사용**: fixture로 중복 제거
- **외부 의존성 mock**: 외부 서비스에 의존 X
- **엣지 케이스 테스트**: 빈 입력·None 값·경계 조건
- **80%+ 커버리지 목표**: 중요 경로에 집중
- **테스트 빠르게 유지**: 느린 테스트 분리에 mark 사용

### DON'T

- **구현 테스트 X**: 내부가 아닌 동작 테스트
- **테스트에 복잡 조건문 X**: 테스트 단순 유지
- **테스트 실패 무시 X**: 모든 테스트 통과 필수
- **서드파티 코드 테스트 X**: 라이브러리 신뢰
- **테스트 간 상태 공유 X**: 테스트 독립적
- **테스트에서 예외 catch X**: `pytest.raises` 사용
- **print 문 X**: 단언과 pytest 출력 사용
- **너무 brittle한 테스트 X**: 과도하게 구체적인 mock 회피

## 일반 패턴

### API 엔드포인트 테스팅 (FastAPI/Flask)

```python
@pytest.fixture
def client():
    app = create_app(testing=True)
    return app.test_client()

def test_get_user(client):
    response = client.get("/api/users/1")
    assert response.status_code == 200
    assert response.json["id"] == 1

def test_create_user(client):
    response = client.post("/api/users", json={
        "name": "Alice",
        "email": "alice@example.com"
    })
    assert response.status_code == 201
    assert response.json["name"] == "Alice"
```

### DB 연산 테스팅

```python
@pytest.fixture
def db_session():
    """테스트 DB 세션 생성."""
    session = Session(bind=engine)
    session.begin_nested()
    yield session
    session.rollback()
    session.close()

def test_create_user(db_session):
    user = User(name="Alice", email="alice@example.com")
    db_session.add(user)
    db_session.commit()

    retrieved = db_session.query(User).filter_by(name="Alice").first()
    assert retrieved.email == "alice@example.com"
```

### 클래스 메서드 테스팅

```python
class TestCalculator:
    @pytest.fixture
    def calculator(self):
        return Calculator()

    def test_add(self, calculator):
        assert calculator.add(2, 3) == 5

    def test_divide_by_zero(self, calculator):
        with pytest.raises(ZeroDivisionError):
            calculator.divide(10, 0)
```

## pytest 설정

### pytest.ini

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    --strict-markers
    --disable-warnings
    --cov=mypackage
    --cov-report=term-missing
    --cov-report=html
markers =
    slow: 느린 테스트 표시
    integration: 통합 테스트 표시
    unit: 단위 테스트 표시
```

### pyproject.toml

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--cov=mypackage",
    "--cov-report=term-missing",
    "--cov-report=html",
]
markers = [
    "slow: 느린 테스트 표시",
    "integration: 통합 테스트 표시",
    "unit: 단위 테스트 표시",
]
```

## 테스트 실행

```bash
# 모든 테스트 실행
pytest

# 특정 파일 실행
pytest tests/test_utils.py

# 특정 테스트 실행
pytest tests/test_utils.py::test_function

# verbose 출력
pytest -v

# 커버리지 포함 실행
pytest --cov=mypackage --cov-report=html

# 빠른 테스트만
pytest -m "not slow"

# 첫 실패까지 실행
pytest -x

# N개 실패에서 중단
pytest --maxfail=3

# 마지막 실패 테스트 실행
pytest --lf

# 패턴으로 테스트 실행
pytest -k "test_user"

# 실패 시 디버거 실행
pytest --pdb
```

## 빠른 레퍼런스

| Pattern | Usage |
|---------|-------|
| `pytest.raises()` | 예상 예외 테스트 |
| `@pytest.fixture()` | 재사용 가능 테스트 fixture 생성 |
| `@pytest.mark.parametrize()` | 다중 입력으로 테스트 실행 |
| `@pytest.mark.slow` | 느린 테스트 표시 |
| `pytest -m "not slow"` | 느린 테스트 건너뜀 |
| `@patch()` | 함수·클래스 mock |
| `tmp_path` fixture | 자동 temp 디렉터리 |
| `pytest --cov` | 커버리지 리포트 생성 |
| `assert` | 단순·가독 가능 단언 |

**기억하라**: 테스트도 코드다. 깨끗하고 가독 가능하고 유지보수 가능하게 유지. 좋은 테스트는 버그를 잡고, 훌륭한 테스트는 버그를 방지한다.
