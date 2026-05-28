---
name: tdd-workflow
description: 새 기능 작성·버그 수정·코드 리팩토링 시 이 스킬 사용. unit·integration·E2E 테스트 포함 80%+ 커버리지로 TDD 시행 (Use this skill when writing new features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit, integration, and E2E tests).
origin: ECC
---

# TDD 워크플로

이 스킬은 모든 코드 개발이 포괄적 테스트 커버리지의 TDD 원칙을 따르도록 보장.

## 활성화 시점

- 새 기능·기능 작성
- 버그·이슈 수정
- 기존 코드 리팩토링
- API 엔드포인트 추가
- 새 컴포넌트 생성

## 핵심 원칙

### 1. 코드 전 테스트
항상 테스트 먼저 작성, 그 다음 통과시킬 코드 구현.

### 2. 커버리지 요구사항
- 최소 80% 커버리지 (unit + integration + E2E)
- 모든 엣지 케이스 커버
- 에러 시나리오 테스트
- 경계 조건 검증

### 3. 테스트 타입

#### 단위 테스트
- 개별 함수·유틸
- 컴포넌트 로직
- 순수 함수
- 헬퍼·유틸

#### 통합 테스트
- API 엔드포인트
- DB 연산
- 서비스 상호작용
- 외부 API 호출

#### E2E 테스트 (Playwright)
- 중요 사용자 흐름
- 완전 워크플로
- 브라우저 자동화
- UI 상호작용

### 4. Git 체크포인트
- 저장소가 Git 하면 각 TDD 단계 후 체크포인트 커밋 생성
- 워크플로 완료까지 체크포인트 커밋 squash·rewrite 금지
- 각 체크포인트 커밋 메시지가 단계와 캡처된 정확한 증거 기술
- 현재 활성 브랜치에서 현재 작업용으로 생성된 커밋만 카운트
- 다른 브랜치의 커밋·이전 무관 작업·먼 브랜치 히스토리를 유효 체크포인트 증거로 취급 금지
- 체크포인트 만족으로 취급 전, 현재 활성 브랜치의 현재 `HEAD`에서 도달 가능하고 현재 작업 시퀀스에 속하는지 검증
- 선호되는 컴팩트 워크플로:
  - 실패 테스트 추가·RED 검증된 커밋 하나
  - 최소 수정 적용·GREEN 검증된 커밋 하나
  - 리팩토링 완료된 선택 커밋 하나
- 테스트 커밋이 RED에 명확히 해당하고 수정 커밋이 GREEN에 명확히 해당하면 별도 증거 전용 커밋은 불필요

## TDD 워크플로 단계

### Step 1: 사용자 여정 작성
```
[역할]로서, [혜택]을 위해 [액션]하기를 원함

예:
사용자로서, 정확한 키워드 없이도 관련 마켓을 찾을 수 있도록
시맨틱하게 마켓을 검색하기를 원함.
```

### Step 2: 테스트 케이스 생성
각 사용자 여정마다 포괄적 테스트 케이스 생성:

```typescript
describe('Semantic Search', () => {
  it('returns relevant markets for query', async () => {
    // 테스트 구현
  })

  it('handles empty query gracefully', async () => {
    // 엣지 케이스 테스트
  })

  it('falls back to substring search when Redis unavailable', async () => {
    // fallback 동작 테스트
  })

  it('sorts results by similarity score', async () => {
    // 정렬 로직 테스트
  })
})
```

### Step 3: 테스트 실행 (실패해야 함)
```bash
npm test
# 테스트 실패해야 함 - 아직 구현 안 함
```

이 단계는 필수이며 모든 프로덕션 변경의 RED 게이트.

비즈니스 로직·기타 프로덕션 코드 수정 전에 다음 경로 중 하나로 유효 RED 상태 검증:
- 런타임 RED:
  - 관련 테스트 타겟이 컴파일 성공
  - 새·변경된 테스트가 실제로 실행됨
  - 결과가 RED
- 컴파일 타임 RED:
  - 새 테스트가 버그가 있는 코드 경로를 새로 인스턴스화·참조·실행
  - 컴파일 실패 자체가 의도한 RED 신호
- 어느 경우든, 실패는 의도한 비즈니스 로직 버그·정의되지 않은 동작·누락된 구현으로 인함
- 실패는 무관 구문 에러·깨진 테스트 setup·누락 의존성·무관 회귀로만 인한 게 아님

작성만 되고 컴파일·실행 안 된 테스트는 RED 카운트 X.

이 RED 상태 확인 전 프로덕션 코드 편집 금지.

저장소가 Git 하면 이 단계 검증 직후 체크포인트 커밋 생성.
권장 커밋 메시지 형식:
- `test: add reproducer for <기능 또는 버그>`
- 이 커밋은 reproducer가 컴파일·실행되어 의도한 이유로 실패했다면 RED 검증 체크포인트 역할도 가능
- 계속 전에 이 체크포인트 커밋이 현재 활성 브랜치에 있는지 검증

### Step 4: 코드 구현
테스트를 통과시킬 최소 코드 작성:

```typescript
// 테스트가 안내하는 구현
export async function searchMarkets(query: string) {
  // 구현
}
```

저장소가 Git 하면 최소 수정을 staging하되 Step 5에서 GREEN 검증까지 체크포인트 커밋 보류.

### Step 5: 테스트 재실행
```bash
npm test
# 이제 테스트 통과해야 함
```

수정 후 동일 관련 테스트 타겟 재실행하고 이전 실패 테스트가 이제 GREEN인지 확인.

유효 GREEN 결과 후에만 리팩토링 진행 가능.

저장소가 Git 하면 GREEN 검증 직후 체크포인트 커밋 생성.
권장 커밋 메시지 형식:
- `fix: <기능 또는 버그>`
- 동일 관련 테스트 타겟 재실행되어 통과했다면 수정 커밋이 GREEN 검증 체크포인트 역할도 가능
- 계속 전에 이 체크포인트 커밋이 현재 활성 브랜치에 있는지 검증

### Step 6: 리팩토링
테스트 green 유지하며 코드 품질 개선:
- 중복 제거
- 명명 개선
- 성능 최적화
- 가독성 향상

저장소가 Git 하면 리팩토링 완료·테스트 green 유지 직후 체크포인트 커밋 생성.
권장 커밋 메시지 형식:
- `refactor: clean up after <기능 또는 버그> implementation`
- TDD 사이클 완료 고려 전에 이 체크포인트 커밋이 현재 활성 브랜치에 있는지 검증

### Step 7: 커버리지 검증
```bash
npm run test:coverage
# 80%+ 커버리지 달성 검증
```

## 테스팅 패턴

### 단위 테스트 패턴 (Jest/Vitest)
```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from './Button'

describe('Button Component', () => {
  it('renders with correct text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('calls onClick when clicked', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click</Button>)

    fireEvent.click(screen.getByRole('button'))

    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Click</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })
})
```

### API 통합 테스트 패턴
```typescript
import { NextRequest } from 'next/server'
import { GET } from './route'

describe('GET /api/markets', () => {
  it('returns markets successfully', async () => {
    const request = new NextRequest('http://localhost/api/markets')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.success).toBe(true)
    expect(Array.isArray(data.data)).toBe(true)
  })

  it('validates query parameters', async () => {
    const request = new NextRequest('http://localhost/api/markets?limit=invalid')
    const response = await GET(request)

    expect(response.status).toBe(400)
  })

  it('handles database errors gracefully', async () => {
    // DB 실패 mock
    const request = new NextRequest('http://localhost/api/markets')
    // 에러 처리 테스트
  })
})
```

### E2E 테스트 패턴 (Playwright)
```typescript
import { test, expect } from '@playwright/test'

test('user can search and filter markets', async ({ page }) => {
  // 마켓 페이지 이동
  await page.goto('/')
  await page.click('a[href="/markets"]')

  // 페이지 로딩 검증
  await expect(page.locator('h1')).toContainText('Markets')

  // 마켓 검색
  await page.fill('input[placeholder="Search markets"]', 'election')

  // debounce·결과 대기
  await page.waitForTimeout(600)

  // 검색 결과 표시 검증
  const results = page.locator('[data-testid="market-card"]')
  await expect(results).toHaveCount(5, { timeout: 5000 })

  // 결과에 검색어 포함 검증
  const firstResult = results.first()
  await expect(firstResult).toContainText('election', { ignoreCase: true })

  // 상태로 필터
  await page.click('button:has-text("Active")')

  // 필터링된 결과 검증
  await expect(results).toHaveCount(3)
})

test('user can create a new market', async ({ page }) => {
  // 먼저 로그인
  await page.goto('/creator-dashboard')

  // 마켓 생성 폼 채우기
  await page.fill('input[name="name"]', 'Test Market')
  await page.fill('textarea[name="description"]', 'Test description')
  await page.fill('input[name="endDate"]', '2025-12-31')

  // 폼 제출
  await page.click('button[type="submit"]')

  // 성공 메시지 검증
  await expect(page.locator('text=Market created successfully')).toBeVisible()

  // 마켓 페이지로 리다이렉트 검증
  await expect(page).toHaveURL(/\/markets\/test-market/)
})
```

## 테스트 파일 구성

```
src/
├── components/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.test.tsx          # 단위 테스트
│   │   └── Button.stories.tsx       # Storybook
│   └── MarketCard/
│       ├── MarketCard.tsx
│       └── MarketCard.test.tsx
├── app/
│   └── api/
│       └── markets/
│           ├── route.ts
│           └── route.test.ts         # 통합 테스트
└── e2e/
    ├── markets.spec.ts               # E2E 테스트
    ├── trading.spec.ts
    └── auth.spec.ts
```

## 외부 서비스 모킹

### Supabase Mock
```typescript
jest.mock('@/lib/supabase', () => ({
  supabase: {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => Promise.resolve({
          data: [{ id: 1, name: 'Test Market' }],
          error: null
        }))
      }))
    }))
  }
}))
```

### Redis Mock
```typescript
jest.mock('@/lib/redis', () => ({
  searchMarketsByVector: jest.fn(() => Promise.resolve([
    { slug: 'test-market', similarity_score: 0.95 }
  ])),
  checkRedisHealth: jest.fn(() => Promise.resolve({ connected: true }))
}))
```

### OpenAI Mock
```typescript
jest.mock('@/lib/openai', () => ({
  generateEmbedding: jest.fn(() => Promise.resolve(
    new Array(1536).fill(0.1) // 1536-dim 임베딩 mock
  ))
}))
```

## 테스트 커버리지 검증

### 커버리지 리포트 실행
```bash
npm run test:coverage
```

### 커버리지 임계치
```json
{
  "jest": {
    "coverageThresholds": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

## 회피할 일반 테스팅 실수

### FAIL: WRONG: 구현 디테일 테스팅
```typescript
// 내부 상태 테스트 X
expect(component.state.count).toBe(5)
```

### PASS: CORRECT: 사용자 가시 동작 테스트
```typescript
// 사용자가 보는 것 테스트
expect(screen.getByText('Count: 5')).toBeInTheDocument()
```

### FAIL: WRONG: Brittle Selector
```typescript
// 쉽게 깨짐
await page.click('.css-class-xyz')
```

### PASS: CORRECT: 시맨틱 Selector
```typescript
// 변경에 견고
await page.click('button:has-text("Submit")')
await page.click('[data-testid="submit-button"]')
```

### FAIL: WRONG: 테스트 격리 없음
```typescript
// 테스트가 서로 의존
test('creates user', () => { /* ... */ })
test('updates same user', () => { /* 이전 테스트에 의존 */ })
```

### PASS: CORRECT: 독립 테스트
```typescript
// 각 테스트가 자체 데이터 설정
test('creates user', () => {
  const user = createTestUser()
  // 테스트 로직
})

test('updates user', () => {
  const user = createTestUser()
  // 업데이트 로직
})
```

## 지속 테스팅

### 개발 중 Watch 모드
```bash
npm test -- --watch
# 파일 변경 시 자동 테스트 실행
```

### Pre-Commit Hook
```bash
# 모든 커밋 전 실행
npm test && npm run lint
```

### CI/CD 통합
```yaml
# GitHub Actions
- name: Run Tests
  run: npm test -- --coverage
- name: Upload Coverage
  uses: codecov/codecov-action@v3
```

## 모범 사례

1. **테스트 먼저** - 항상 TDD
2. **테스트당 단언 하나** - 단일 동작에 집중
3. **서술적 테스트 이름** - 무엇이 테스트되는지 설명
4. **Arrange-Act-Assert** - 명확한 테스트 구조
5. **외부 의존성 mock** - 단위 테스트 격리
6. **엣지 케이스 테스트** - null·undefined·empty·large
7. **에러 경로 테스트** - happy path만 아님
8. **테스트 빠르게 유지** - 단위 테스트 각 50ms 미만
9. **테스트 후 정리** - 사이드 이펙트 없음
10. **커버리지 리포트 리뷰** - 갭 식별

## 성공 지표

- 80%+ 코드 커버리지 달성
- 모든 테스트 통과 (green)
- skip·disabled 테스트 없음
- 빠른 테스트 실행 (단위 테스트 30s 미만)
- E2E 테스트가 중요 사용자 흐름 커버
- 테스트가 프로덕션 전 버그 잡음

---

**기억하라**: 테스트는 선택이 아니다. 자신감 있는 리팩토링·빠른 개발·프로덕션 신뢰성을 가능하게 하는 안전망이다.
