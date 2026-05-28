---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python 테스팅 (Python Testing)

> 이 파일은 [common/testing.md](../common/testing.md)를 Python 특화 내용으로 확장한다.

## 프레임워크

테스팅 프레임워크로 **pytest** 사용.

## 커버리지

```bash
pytest --cov=src --cov-report=term-missing
```

## 테스트 구조

테스트 분류에 `pytest.mark` 사용:

```python
import pytest

@pytest.mark.unit
def test_calculate_total():
    ...

@pytest.mark.integration
def test_database_connection():
    ...
```

## 참조

자세한 pytest 패턴·픽스처는 skill: `python-testing` 참조.
