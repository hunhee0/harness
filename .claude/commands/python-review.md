---
description: PEP 8 준수·타입 힌트·보안·Pythonic 관용구를 위한 포괄적 Python 코드 리뷰. python-reviewer 에이전트 호출 (Comprehensive Python code review for PEP 8 compliance, type hints, security, and Pythonic idioms. Invokes the python-reviewer agent).
---

# Python 코드 리뷰

이 명령은 포괄적 Python 특화 코드 리뷰를 위해 **python-reviewer** 에이전트를 호출한다.

## 이 명령이 하는 일

1. **Python 변경 식별**: `git diff`로 수정된 `.py` 파일 찾기
2. **정적 분석 실행**: `ruff`, `mypy`, `pylint`, `black --check` 실행
3. **보안 스캔**: SQL 인젝션·명령 인젝션·안전하지 않은 역직렬화 체크
4. **타입 안전 리뷰**: 타입 힌트·mypy 에러 분석
5. **Pythonic 코드 체크**: 코드가 PEP 8·Python 모범 사례 따르는지 검증
6. **리포트 생성**: 심각도별 이슈 분류

## 사용 시점

`/python-review` 사용 시점:
- Python 코드 작성·수정 후
- Python 변경 커밋 전
- Python 코드 PR 리뷰
- 새 Python 코드베이스 온보딩
- Pythonic 패턴·관용구 학습

## 리뷰 카테고리

### CRITICAL (반드시 수정)
- SQL/명령 인젝션 취약점
- 안전하지 않은 eval/exec 사용
- Pickle 안전하지 않은 역직렬화
- 하드코딩된 자격증명
- YAML unsafe load
- 에러를 숨기는 bare except 절

### HIGH (수정 권장)
- public 함수의 타입 힌트 누락
- 변경 가능한 기본 인자
- 예외를 조용히 삼킴
- 자원에 컨텍스트 매니저 미사용
- 컴프리헨션 대신 C 스타일 루프
- isinstance() 대신 type() 사용
- 락 없는 race condition

### MEDIUM (고려)
- PEP 8 포맷 위반
- public 함수에 docstring 누락
- logging 대신 print 문
- 비효율 문자열 연산
- 명명 상수 없는 매직 넘버
- 포맷팅에 f-string 미사용
- 불필요한 list 생성

## 자동 실행 체크

```bash
# 타입 체크
mypy .

# 린팅·포맷팅
ruff check .
black --check .
isort --check-only .

# 보안 스캔
bandit -r .

# 의존성 감사
pip-audit
safety check

# 테스트
pytest --cov=app --cov-report=term-missing
```

## 사용 예시

```text
User: /python-review

Agent:
# Python Code Review Report

## Files Reviewed
- app/routes/user.py (modified)
- app/services/auth.py (modified)

## Static Analysis Results
✓ ruff: No issues
✓ mypy: No errors
WARNING: black: 2 files need reformatting
✓ bandit: No security issues

## Issues Found

[CRITICAL] SQL 인젝션 취약점
File: app/routes/user.py:42
Issue: 사용자 입력이 SQL 쿼리에 직접 보간됨
```python
query = f"SELECT * FROM users WHERE id = {user_id}"  # Bad
```
Fix: 파라미터화 쿼리 사용
```python
query = "SELECT * FROM users WHERE id = %s"  # Good
cursor.execute(query, (user_id,))
```

[HIGH] 변경 가능한 기본 인자
File: app/services/auth.py:18
Issue: 변경 가능한 기본 인자가 공유 상태 유발
```python
def process_items(items=[]):  # Bad
    items.append("new")
    return items
```
Fix: None을 기본값으로
```python
def process_items(items=None):  # Good
    if items is None:
        items = []
    items.append("new")
    return items
```

[MEDIUM] 타입 힌트 누락
File: app/services/auth.py:25
Issue: 타입 어노테이션 없는 public 함수
```python
def get_user(user_id):  # Bad
    return db.find(user_id)
```
Fix: 타입 힌트 추가
```python
def get_user(user_id: str) -> Optional[User]:  # Good
    return db.find(user_id)
```

[MEDIUM] 컨텍스트 매니저 미사용
File: app/routes/user.py:55
Issue: 예외 시 파일 닫히지 않음
```python
f = open("config.json")  # Bad
data = f.read()
f.close()
```
Fix: 컨텍스트 매니저 사용
```python
with open("config.json") as f:  # Good
    data = f.read()
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 2

Recommendation: FAIL: CRITICAL 이슈 수정 전까지 merge 차단

## Formatting Required
Run: `black app/routes/user.py app/services/auth.py`
```

## 승인 기준

| Status | Condition |
|--------|-----------|
| PASS: Approve | CRITICAL·HIGH 이슈 없음 |
| WARNING: Warning | MEDIUM 이슈만 (주의해서 merge) |
| FAIL: Block | CRITICAL 또는 HIGH 이슈 발견 |

## 다른 명령과의 통합

- 테스트 통과 보장을 위해 `tdd-workflow` 스킬을 먼저 사용
- 비-Python 특화 우려에는 `/code-review` 사용
- 커밋 전에 `/python-review` 사용
- 정적 분석 도구 실패 시 `/build-fix` 사용

## 프레임워크별 리뷰

### Django 프로젝트
리뷰어가 다음을 체크:
- N+1 쿼리 이슈 (`select_related`와 `prefetch_related` 사용)
- 모델 변경에 마이그레이션 누락
- ORM으로 가능한데 raw SQL 사용
- 다단계 연산에 `transaction.atomic()` 누락

### FastAPI 프로젝트
리뷰어가 다음을 체크:
- CORS 잘못된 설정
- 요청 검증용 Pydantic 모델
- 응답 모델 정확성
- 적절한 async/await 사용
- DI 패턴

### Flask 프로젝트
리뷰어가 다음을 체크:
- 컨텍스트 관리 (app context·request context)
- 적절한 에러 처리
- Blueprint 구성
- 설정 관리

## 관련

- Agent: `agents/python-reviewer.md`
- Skills: `skills/python-patterns/`, `skills/python-testing/`

## 일반적인 수정

### 타입 힌트 추가
```python
# Before
def calculate(x, y):
    return x + y

# After
from typing import Union

def calculate(x: Union[int, float], y: Union[int, float]) -> Union[int, float]:
    return x + y
```

### 컨텍스트 매니저 사용
```python
# Before
f = open("file.txt")
data = f.read()
f.close()

# After
with open("file.txt") as f:
    data = f.read()
```

### List 컴프리헨션 사용
```python
# Before
result = []
for item in items:
    if item.active:
        result.append(item.name)

# After
result = [item.name for item in items if item.active]
```

### 변경 가능한 기본값 수정
```python
# Before
def append(value, items=[]):
    items.append(value)
    return items

# After
def append(value, items=None):
    if items is None:
        items = []
    items.append(value)
    return items
```

### f-string 사용 (Python 3.6+)
```python
# Before
name = "Alice"
greeting = "Hello, " + name + "!"
greeting2 = "Hello, {}".format(name)

# After
greeting = f"Hello, {name}!"
```

### 루프 내 문자열 결합 수정
```python
# Before
result = ""
for item in items:
    result += str(item)

# After
result = "".join(str(item) for item in items)
```

## Python 버전 호환성

리뷰어는 코드가 새 Python 버전 기능을 사용할 때 알림:

| Feature | Minimum Python |
|---------|----------------|
| Type hints | 3.5+ |
| f-strings | 3.6+ |
| Walrus operator (`:=`) | 3.8+ |
| Position-only parameters | 3.8+ |
| Match statements | 3.10+ |
| Type unions (&#96;x &#124; None&#96;) | 3.10+ |

프로젝트의 `pyproject.toml`·`setup.py`가 올바른 최소 Python 버전을 명세하는지 확인.
