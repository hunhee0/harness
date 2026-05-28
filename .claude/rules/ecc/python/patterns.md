---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python 패턴 (Python Patterns)

> 이 파일은 [common/patterns.md](../common/patterns.md)를 Python 특화 내용으로 확장한다.

## Protocol (Duck Typing)

```python
from typing import Protocol

class Repository(Protocol):
    def find_by_id(self, id: str) -> dict | None: ...
    def save(self, entity: dict) -> dict: ...
```

## Dataclass를 DTO로

```python
from dataclasses import dataclass

@dataclass
class CreateUserRequest:
    name: str
    email: str
    age: int | None = None
```

## 컨텍스트 매니저 & 제너레이터

- 자원 관리에 컨텍스트 매니저(`with` 문) 사용
- 지연 평가·메모리 효율 순회에 제너레이터 사용

## 참조

데코레이터·동시성·패키지 구성을 포함한 포괄 패턴은 skill: `python-patterns` 참조.
