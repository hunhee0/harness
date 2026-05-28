---
name: python-patterns
description: 견고·효율·유지보수 가능 Python 애플리케이션 구축용 Pythonic 관용구·PEP 8 표준·타입 힌트·모범 사례 (Pythonic idioms, PEP 8 standards, type hints, and best practices for building robust, efficient, and maintainable Python applications).
origin: ECC
---

# Python 개발 패턴

견고·효율·유지보수 가능 애플리케이션 구축용 관용 Python 패턴·모범 사례.

## 활성화 시점

- 새 Python 코드 작성
- Python 코드 리뷰
- 기존 Python 코드 리팩토링
- Python 패키지/모듈 설계

## 핵심 원칙

### 1. 가독성 중요

Python은 가독성 우선. 코드는 명확하고 이해 쉬워야 함.

```python
# Good: 명확·가독 가능
def get_active_users(users: list[User]) -> list[User]:
    """제공된 리스트에서 활성 사용자만 반환."""
    return [user for user in users if user.is_active]


# Bad: 영리하지만 혼란
def get_active_users(u):
    return [x for x in u if x.a]
```

### 2. 암묵적보다 명시적

매직 회피. 코드 동작을 명확히.

```python
# Good: 명시적 설정
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Bad: 숨겨진 사이드 이펙트
import some_module
some_module.setup()  # 이게 뭐 하는 거?
```

### 3. EAFP - Easier to Ask Forgiveness Than Permission

Python은 조건 체크보다 예외 처리 선호.

```python
# Good: EAFP 스타일
def get_value(dictionary: dict, key: str) -> Any:
    try:
        return dictionary[key]
    except KeyError:
        return default_value

# Bad: LBYL (Look Before You Leap) 스타일
def get_value(dictionary: dict, key: str) -> Any:
    if key in dictionary:
        return dictionary[key]
    else:
        return default_value
```

## 타입 힌트

### 기본 타입 어노테이션

```python
from typing import Optional, List, Dict, Any

def process_user(
    user_id: str,
    data: Dict[str, Any],
    active: bool = True
) -> Optional[User]:
    """사용자 처리, 업데이트된 User 또는 None 반환."""
    if not active:
        return None
    return User(user_id, data)
```

### 모던 타입 힌트 (Python 3.9+)

```python
# Python 3.9+ - 빌트인 타입 사용
def process_items(items: list[str]) -> dict[str, int]:
    return {item: len(item) for item in items}

# Python 3.8 이하 - typing 모듈 사용
from typing import List, Dict

def process_items(items: List[str]) -> Dict[str, int]:
    return {item: len(item) for item in items}
```

### 타입 alias·TypeVar

```python
from typing import TypeVar, Union

# 복잡한 타입의 타입 alias
JSON = Union[dict[str, Any], list[Any], str, int, float, bool, None]

def parse_json(data: str) -> JSON:
    return json.loads(data)

# 제네릭 타입
T = TypeVar('T')

def first(items: list[T]) -> T | None:
    """첫 항목 또는 빈 리스트면 None 반환."""
    return items[0] if items else None
```

### Protocol 기반 Duck Typing

```python
from typing import Protocol

class Renderable(Protocol):
    def render(self) -> str:
        """객체를 문자열로 렌더."""

def render_all(items: list[Renderable]) -> str:
    """Renderable 프로토콜 구현한 모든 항목 렌더."""
    return "\n".join(item.render() for item in items)
```

## 에러 처리 패턴

### 특정 예외 처리

```python
# Good: 특정 예외 캐치
def load_config(path: str) -> Config:
    try:
        with open(path) as f:
            return Config.from_json(f.read())
    except FileNotFoundError as e:
        raise ConfigError(f"Config file not found: {path}") from e
    except json.JSONDecodeError as e:
        raise ConfigError(f"Invalid JSON in config: {path}") from e

# Bad: bare except
def load_config(path: str) -> Config:
    try:
        with open(path) as f:
            return Config.from_json(f.read())
    except:
        return None  # 조용한 실패!
```

### 예외 체이닝

```python
def process_data(data: str) -> Result:
    try:
        parsed = json.loads(data)
    except json.JSONDecodeError as e:
        # 예외 체이닝으로 traceback 보존
        raise ValueError(f"Failed to parse data: {data}") from e
```

### 커스텀 예외 계층

```python
class AppError(Exception):
    """모든 애플리케이션 에러의 base 예외."""
    pass

class ValidationError(AppError):
    """입력 검증 실패 시 발생."""
    pass

class NotFoundError(AppError):
    """요청된 자원 미발견 시 발생."""
    pass

# 사용
def get_user(user_id: str) -> User:
    user = db.find_user(user_id)
    if not user:
        raise NotFoundError(f"User not found: {user_id}")
    return user
```

## 컨텍스트 매니저

### 자원 관리

```python
# Good: 컨텍스트 매니저 사용
def process_file(path: str) -> str:
    with open(path, 'r') as f:
        return f.read()

# Bad: 수동 자원 관리
def process_file(path: str) -> str:
    f = open(path, 'r')
    try:
        return f.read()
    finally:
        f.close()
```

### 커스텀 컨텍스트 매니저

```python
from contextlib import contextmanager

@contextmanager
def timer(name: str):
    """코드 블록 타이밍 컨텍스트 매니저."""
    start = time.perf_counter()
    yield
    elapsed = time.perf_counter() - start
    print(f"{name} took {elapsed:.4f} seconds")

# 사용
with timer("data processing"):
    process_large_dataset()
```

### 컨텍스트 매니저 클래스

```python
class DatabaseTransaction:
    def __init__(self, connection):
        self.connection = connection

    def __enter__(self):
        self.connection.begin_transaction()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is None:
            self.connection.commit()
        else:
            self.connection.rollback()
        return False  # 예외 억제 X

# 사용
with DatabaseTransaction(conn):
    user = conn.create_user(user_data)
    conn.create_profile(user.id, profile_data)
```

## 컴프리헨션·제너레이터

### 리스트 컴프리헨션

```python
# Good: 단순 변환에 리스트 컴프리헨션
names = [user.name for user in users if user.is_active]

# Bad: 수동 루프
names = []
for user in users:
    if user.is_active:
        names.append(user.name)

# 복잡한 컴프리헨션은 확장
# Bad: 너무 복잡
result = [x * 2 for x in items if x > 0 if x % 2 == 0]

# Good: 제너레이터 함수 사용
def filter_and_transform(items: Iterable[int]) -> list[int]:
    result = []
    for x in items:
        if x > 0 and x % 2 == 0:
            result.append(x * 2)
    return result
```

### 제너레이터 표현식

```python
# Good: 지연 평가용 제너레이터
total = sum(x * x for x in range(1_000_000))

# Bad: 큰 중간 리스트 생성
total = sum([x * x for x in range(1_000_000)])
```

### 제너레이터 함수

```python
def read_large_file(path: str) -> Iterator[str]:
    """큰 파일 라인별 읽기."""
    with open(path) as f:
        for line in f:
            yield line.strip()

# 사용
for line in read_large_file("huge.txt"):
    process(line)
```

## 데이터 클래스·Named Tuple

### 데이터 클래스

```python
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class User:
    """자동 __init__·__repr__·__eq__ 있는 User 엔티티."""
    id: str
    name: str
    email: str
    created_at: datetime = field(default_factory=datetime.now)
    is_active: bool = True

# 사용
user = User(
    id="123",
    name="Alice",
    email="alice@example.com"
)
```

### 검증 있는 데이터 클래스

```python
@dataclass
class User:
    email: str
    age: int

    def __post_init__(self):
        # 이메일 형식 검증
        if "@" not in self.email:
            raise ValueError(f"Invalid email: {self.email}")
        # 나이 범위 검증
        if self.age < 0 or self.age > 150:
            raise ValueError(f"Invalid age: {self.age}")
```

### Named Tuple

```python
from typing import NamedTuple

class Point(NamedTuple):
    """불변 2D 포인트."""
    x: float
    y: float

    def distance(self, other: 'Point') -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5

# 사용
p1 = Point(0, 0)
p2 = Point(3, 4)
print(p1.distance(p2))  # 5.0
```

## 데코레이터

### 함수 데코레이터

```python
import functools
import time

def timer(func: Callable) -> Callable:
    """함수 실행 타이밍 데코레이터."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__} took {elapsed:.4f}s")
        return result
    return wrapper

@timer
def slow_function():
    time.sleep(1)

# slow_function() 출력: slow_function took 1.0012s
```

### 파라미터화 데코레이터

```python
def repeat(times: int):
    """함수 여러 번 반복 데코레이터."""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            results = []
            for _ in range(times):
                results.append(func(*args, **kwargs))
            return results
        return wrapper
    return decorator

@repeat(times=3)
def greet(name: str) -> str:
    return f"Hello, {name}!"

# greet("Alice") 반환 ["Hello, Alice!", "Hello, Alice!", "Hello, Alice!"]
```

### 클래스 기반 데코레이터

```python
class CountCalls:
    """함수 호출 횟수 카운트 데코레이터."""
    def __init__(self, func: Callable):
        functools.update_wrapper(self, func)
        self.func = func
        self.count = 0

    def __call__(self, *args, **kwargs):
        self.count += 1
        print(f"{self.func.__name__} has been called {self.count} times")
        return self.func(*args, **kwargs)

@CountCalls
def process():
    pass

# process() 호출마다 카운트 출력
```

## 동시성 패턴

### I/O 바운드 작업용 Threading

```python
import concurrent.futures
import threading

def fetch_url(url: str) -> str:
    """URL fetch (I/O 바운드 연산)."""
    import urllib.request
    with urllib.request.urlopen(url) as response:
        return response.read().decode()

def fetch_all_urls(urls: list[str]) -> dict[str, str]:
    """스레드로 여러 URL 동시 fetch."""
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        future_to_url = {executor.submit(fetch_url, url): url for url in urls}
        results = {}
        for future in concurrent.futures.as_completed(future_to_url):
            url = future_to_url[future]
            try:
                results[url] = future.result()
            except Exception as e:
                results[url] = f"Error: {e}"
    return results
```

### CPU 바운드 작업용 Multiprocessing

```python
def process_data(data: list[int]) -> int:
    """CPU 집약 계산."""
    return sum(x ** 2 for x in data)

def process_all(datasets: list[list[int]]) -> list[int]:
    """다중 프로세스로 다중 데이터셋 처리."""
    with concurrent.futures.ProcessPoolExecutor() as executor:
        results = list(executor.map(process_data, datasets))
    return results
```

### 동시 I/O용 Async/Await

```python
import asyncio

async def fetch_async(url: str) -> str:
    """비동기 URL fetch."""
    import aiohttp
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.text()

async def fetch_all(urls: list[str]) -> dict[str, str]:
    """여러 URL 동시 fetch."""
    tasks = [fetch_async(url) for url in urls]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    return dict(zip(urls, results))
```

## 패키지 구성

### 표준 프로젝트 레이아웃

```
myproject/
├── src/
│   └── mypackage/
│       ├── __init__.py
│       ├── main.py
│       ├── api/
│       │   ├── __init__.py
│       │   └── routes.py
│       ├── models/
│       │   ├── __init__.py
│       │   └── user.py
│       └── utils/
│           ├── __init__.py
│           └── helpers.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_api.py
│   └── test_models.py
├── pyproject.toml
├── README.md
└── .gitignore
```

### Import 관례

```python
# Good: import 순서 - stdlib·서드파티·로컬
import os
import sys
from pathlib import Path

import requests
from fastapi import FastAPI

from mypackage.models import User
from mypackage.utils import format_name

# Good: 자동 import 정렬에 isort 사용
# pip install isort
```

### 패키지 export용 __init__.py

```python
# mypackage/__init__.py
"""mypackage - 샘플 Python 패키지."""

__version__ = "1.0.0"

# 메인 클래스/함수를 패키지 레벨에서 export
from mypackage.models import User, Post
from mypackage.utils import format_name

__all__ = ["User", "Post", "format_name"]
```

## 메모리·성능

### 메모리 효율용 __slots__

```python
# Bad: 일반 클래스는 __dict__ 사용 (더 많은 메모리)
class Point:
    def __init__(self, x: float, y: float):
        self.x = x
        self.y = y

# Good: __slots__로 메모리 사용 감소
class Point:
    __slots__ = ['x', 'y']

    def __init__(self, x: float, y: float):
        self.x = x
        self.y = y
```

### 큰 데이터용 제너레이터

```python
# Bad: 메모리에 전체 리스트 반환
def read_lines(path: str) -> list[str]:
    with open(path) as f:
        return [line.strip() for line in f]

# Good: 라인 한 번에 하나씩 yield
def read_lines(path: str) -> Iterator[str]:
    with open(path) as f:
        for line in f:
            yield line.strip()
```

### 루프 내 문자열 결합 회피

```python
# Bad: 문자열 불변성으로 O(n²)
result = ""
for item in items:
    result += str(item)

# Good: join으로 O(n)
result = "".join(str(item) for item in items)

# Good: 빌딩용 StringIO
from io import StringIO

buffer = StringIO()
for item in items:
    buffer.write(str(item))
result = buffer.getvalue()
```

## Python 도구 통합

### 필수 명령

```bash
# 코드 포맷팅
black .
isort .

# 린팅
ruff check .
pylint mypackage/

# 타입 체크
mypy .

# 테스팅
pytest --cov=mypackage --cov-report=html

# 보안 스캔
bandit -r .

# 의존성 관리
pip-audit
safety check
```

### pyproject.toml 설정

```toml
[project]
name = "mypackage"
version = "1.0.0"
requires-python = ">=3.9"
dependencies = [
    "requests>=2.31.0",
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.5.0",
]

[tool.black]
line-length = 88
target-version = ['py39']

[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "W"]

[tool.mypy]
python_version = "3.9"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=mypackage --cov-report=term-missing"
```

## 빠른 레퍼런스: Python 관용구

| Idiom | Description |
|-------|-------------|
| EAFP | Easier to Ask Forgiveness than Permission |
| 컨텍스트 매니저 | 자원 관리에 `with` 사용 |
| 리스트 컴프리헨션 | 단순 변환용 |
| 제너레이터 | 지연 평가·큰 데이터셋용 |
| 타입 힌트 | 함수 시그니처 어노테이트 |
| 데이터 클래스 | 자동 생성 메서드 있는 데이터 컨테이너용 |
| `__slots__` | 메모리 최적화용 |
| f-string | 문자열 포맷팅용 (Python 3.6+) |
| `pathlib.Path` | 경로 연산용 (Python 3.4+) |
| `enumerate` | 루프의 index-element pair용 |

## 회피할 안티패턴

```python
# Bad: 변경 가능한 기본 인자
def append_to(item, items=[]):
    items.append(item)
    return items

# Good: None 사용·새 리스트 생성
def append_to(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items

# Bad: type()으로 타입 체크
if type(obj) == list:
    process(obj)

# Good: isinstance 사용
if isinstance(obj, list):
    process(obj)

# Bad: ==로 None 비교
if value == None:
    process()

# Good: is 사용
if value is None:
    process()

# Bad: from module import *
from os.path import *

# Good: 명시적 import
from os.path import join, exists

# Bad: bare except
try:
    risky_operation()
except:
    pass

# Good: 특정 예외
try:
    risky_operation()
except SpecificError as e:
    logger.error(f"Operation failed: {e}")
```

__기억하라__: Python 코드는 가독 가능·명시적이어야 하고 least surprise 원칙 따름. 의심 시 영리함보다 명료성 우선.
