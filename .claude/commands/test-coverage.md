---
description: 커버리지 분석, 갭 식별, 목표 임계치까지 누락 테스트 생성 (Analyze coverage, identify gaps, and generate missing tests toward the target threshold).
---

# Test Coverage

테스트 커버리지 분석, 갭 식별, 80%+ 커버리지 달성을 위한 누락 테스트 생성.

## Step 1: 테스트 프레임워크 감지

| 지표 | 커버리지 명령 |
|-----------|-----------------|
| `jest.config.*` 또는 `package.json` jest | `npx jest --coverage --coverageReporters=json-summary` |
| `vitest.config.*` | `npx vitest run --coverage` |
| `pytest.ini` / `pyproject.toml` pytest | `pytest --cov=src --cov-report=json` |
| `Cargo.toml` | `cargo llvm-cov --json` |
| JaCoCo가 있는 `pom.xml` | `mvn test jacoco:report` |
| `go.mod` | `go test -coverprofile=coverage.out ./...` |

## Step 2: 커버리지 리포트 분석

1. 커버리지 명령 실행
2. 출력 파싱 (JSON summary 또는 터미널 출력)
3. **80% 미만 커버리지** 파일 나열, 최악 우선 정렬
4. 각 부족 파일마다 식별:
   - 테스트되지 않은 함수·메서드
   - 분기 커버리지 누락 (if/else·switch·에러 경로)
   - 분모를 부풀리는 죽은 코드

## Step 3: 누락 테스트 생성

각 부족 파일마다 다음 우선순위로 테스트 생성:

1. **Happy path** — 유효 입력의 핵심 기능
2. **에러 처리** — 잘못된 입력·누락 데이터·네트워크 실패
3. **엣지 케이스** — 빈 배열, null/undefined, 경계 값 (0·-1·MAX_INT)
4. **분기 커버리지** — 각 if/else·switch case·삼항

### 테스트 생성 규칙

- 테스트를 소스와 인접하게 배치: `foo.ts` → `foo.test.ts` (또는 프로젝트 관례)
- 프로젝트의 기존 테스트 패턴 사용 (import 스타일·assertion 라이브러리·모킹 접근)
- 외부 의존성 모킹 (DB·API·파일 시스템)
- 각 테스트 독립 — 테스트 간 공유 가변 상태 없음
- 테스트 이름은 서술적으로: `test_create_user_with_duplicate_email_returns_409`

## Step 4: 검증

1. 전체 테스트 스위트 실행 — 모든 테스트 통과해야 함
2. 커버리지 재실행 — 개선 검증
3. 여전히 80% 미만이면 남은 갭에 Step 3 반복

## Step 5: 리포트

전후 비교 표시:

```
Coverage Report
──────────────────────────────
File                   Before  After
src/services/auth.ts   45%     88%
src/utils/validation.ts 32%    82%
──────────────────────────────
Overall:               67%     84%  PASS:
```

## 집중 영역

- 복잡한 분기를 가진 함수 (high cyclomatic complexity)
- 에러 핸들러·catch 블록
- 코드베이스 전반에서 사용되는 유틸 함수
- API 엔드포인트 핸들러 (요청 → 응답 흐름)
- 엣지 케이스: null·undefined·빈 문자열·빈 배열·0·음수
