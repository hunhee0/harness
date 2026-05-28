> 이 파일은 [common/testing.md](../common/testing.md)를 웹 특화 테스팅으로 확장한다.

# 웹 테스팅 규칙 (Web Testing Rules)

## 우선순위 순서

### 1. Visual Regression

- 핵심 브레이크포인트 스크린샷: 320·768·1024·1440
- hero 섹션·scrollytelling 섹션·의미 있는 상태 테스트
- 시각 중심 작업에는 Playwright 스크린샷 사용
- 양쪽 테마가 있으면 모두 테스트

### 2. 접근성

- 자동 접근성 체크 실행
- 키보드 네비게이션 테스트
- reduced-motion 동작 검증
- 색 대비 검증

### 3. 성능

- 의미 있는 페이지에 Lighthouse 또는 동등물 실행
- [performance.md](performance.md)의 CWV 목표 유지

### 4. 크로스 브라우저

- 최소: Chrome·Firefox·Safari
- 스크롤·모션·fallback 동작 테스트

### 5. 반응형

- 320·375·768·1024·1440·1920 테스트
- 오버플로 없음 검증
- 터치 상호작용 검증

## E2E 모양

```ts
import { test, expect } from '@playwright/test';

test('landing hero loads', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('h1')).toBeVisible();
});
```

- 타이밍 기반 flaky 단언 회피
- 결정론적 wait 선호

## Unit 테스트

- 유틸·데이터 변환·커스텀 hook 테스트
- 매우 시각적인 컴포넌트는 깨지기 쉬운 마크업 단언보다 visual regression이 더 의미 있음
- visual regression은 커버리지 목표를 보완. 대체하지 않음.
