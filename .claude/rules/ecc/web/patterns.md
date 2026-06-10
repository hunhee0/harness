---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.html"
---
> 이 파일은 [common/patterns.md](../common/patterns.md)를 웹 특화 패턴으로 확장한다.

# 웹 패턴 (Web Patterns)

## 컴포넌트 조합

### Compound Components

관련 UI가 상태·상호작용 의미를 공유할 때 compound components 사용:

```tsx
<Tabs defaultValue="overview">
  <Tabs.List>
    <Tabs.Trigger value="overview">Overview</Tabs.Trigger>
    <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Content value="overview">...</Tabs.Content>
  <Tabs.Content value="settings">...</Tabs.Content>
</Tabs>
```

- 부모가 상태 소유
- 자식은 context로 소비
- 복잡한 위젯에 prop drilling보다 이 방식 선호

### Render Props / Slots

- 동작은 공유되지만 마크업이 달라야 할 때 render props 또는 slot 패턴 사용
- 키보드 처리·ARIA·포커스 로직은 headless 레이어에 유지

### Container / Presentational 분할

- Container 컴포넌트가 데이터 로딩·사이드 이펙트 소유
- Presentational 컴포넌트는 props 받아 UI 렌더
- Presentational 컴포넌트는 순수성 유지

## 상태 관리

다음을 분리해 다룰 것:

| 관심사 | 도구 |
|---------|---------|
| 서버 상태 | TanStack Query·SWR·tRPC |
| 클라이언트 상태 | Zustand·Jotai·signals |
| URL 상태 | search params·route segments |
| 폼 상태 | React Hook Form 또는 동등물 |

- 서버 상태를 클라이언트 스토어에 중복 저장 금지
- 중복 계산 상태를 저장 대신 값을 도출

## URL을 상태로

공유 가능한 상태는 URL에 유지:
- 필터
- 정렬
- 페이지네이션
- 활성 탭
- 검색 쿼리

## 데이터 페칭

### Stale-While-Revalidate

- 캐시된 데이터 즉시 반환
- 백그라운드 재검증
- 직접 만들지 말고 기존 라이브러리 선호

### Optimistic Updates

- 현재 상태 스냅샷
- 낙관적 업데이트 적용
- 실패 시 롤백
- 롤백 시 사용자에게 보이는 에러 피드백 제공

### 병렬 로딩

- 독립 데이터를 병렬 페칭
- 부모-자식 요청 워터폴 회피
- 정당화될 때 다음 라우트·상태를 prefetch
