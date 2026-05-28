# 테스트 요구사항 (Testing Requirements)

## 최소 테스트 커버리지: 80%

테스트 타입 (모두 필수):
1. **Unit Tests** - 개별 함수·유틸·컴포넌트
2. **Integration Tests** - API 엔드포인트·DB 연산
3. **E2E Tests** - 중요 사용자 흐름 (언어별 프레임워크 선택)

## TDD

필수 워크플로:
1. 테스트 먼저 작성 (RED)
2. 테스트 실행 — 실패해야 함
3. 최소 구현 작성 (GREEN)
4. 테스트 실행 — 통과해야 함
5. 리팩토링 (IMPROVE)
6. 커버리지 검증 (80%+)

## 테스트 실패 트러블슈팅

1. **tdd-guide** 에이전트 사용
2. 테스트 격리 확인
3. mock이 올바른지 검증
4. 테스트가 잘못된 경우 외에는 구현을 수정 (테스트가 아니라)

## 에이전트 지원

- **tdd-guide** - 새 기능에 PROACTIVELY 사용, 테스트 우선 작성 시행

## 테스트 구조 (AAA 패턴)

테스트는 Arrange-Act-Assert 구조 선호:

```typescript
test('calculates similarity correctly', () => {
  // Arrange
  const vector1 = [1, 0, 0]
  const vector2 = [0, 1, 0]

  // Act
  const similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert
  expect(similarity).toBe(0)
})
```

### 테스트 명명

테스트 대상 동작을 설명하는 서술적 이름 사용:

```typescript
test('returns empty array when no markets match query', () => {})
test('throws error when API key is missing', () => {})
test('falls back to substring search when Redis is unavailable', () => {})
```
