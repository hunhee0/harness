# 테스팅 안티패턴

**이 레퍼런스 로딩 시점:** 테스트 작성·변경, mock 추가, 프로덕션 코드에 테스트 전용 메서드 추가 유혹 시.

## 개요

테스트는 mock 동작 아닌 실제 동작 검증 필수. mock은 격리 수단, 테스트 대상 아님.

**핵심 원칙:** 코드가 무엇 하는지 테스트, mock이 무엇 하는지 X.

**엄격한 TDD 준수가 이 안티패턴 방지.**

## 철칙

```
1. mock 동작 절대 테스트 X
2. 프로덕션 클래스에 테스트 전용 메서드 절대 추가 X
3. 의존성 이해 없이 절대 mock X
```

## 안티패턴 1: Mock 동작 테스팅

**위반:**
```typescript
// ❌ BAD: mock 존재 테스트
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```

**왜 잘못:**
- mock 동작 검증, 컴포넌트 동작 X
- mock 존재 시 통과·없으면 실패
- 실제 동작에 대해 아무것도 알려 X

**your human partner의 정정:** "Are we testing the behavior of a mock?"

**수정:**
```typescript
// ✅ GOOD: 실제 컴포넌트 테스트·mock X
test('renders sidebar', () => {
  render(<Page />);  // sidebar mock X
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});

// 또는 격리 위해 sidebar mock 필수:
// mock에 단언 X - sidebar 존재 시 Page 동작 테스트
```

### Gate 함수

```
어떤 mock 요소에 단언 전:
  질문: "실제 컴포넌트 동작 테스트 또는 mock 존재만?"

  mock 존재 테스트 시:
    STOP - 단언 삭제 또는 컴포넌트 unmock

  대신 실제 동작 테스트
```

## 안티패턴 2: 프로덕션의 테스트 전용 메서드

**위반:**
```typescript
// ❌ BAD: destroy()가 테스트에서만 사용됨
class Session {
  async destroy() {  // 프로덕션 API처럼 보임!
    await this._workspaceManager?.destroyWorkspace(this.id);
    // ... 정리
  }
}

// 테스트에서
afterEach(() => session.destroy());
```

**왜 잘못:**
- 프로덕션 클래스가 테스트 전용 코드로 오염
- 프로덕션에서 우연히 호출 시 위험
- YAGNI·관심사 분리 위반
- 객체 라이프사이클과 엔티티 라이프사이클 혼동

**수정:**
```typescript
// ✅ GOOD: 테스트 유틸이 테스트 정리 처리
// Session에 destroy() 없음 - 프로덕션에서 무상태

// test-utils/에
export async function cleanupSession(session: Session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) {
    await workspaceManager.destroyWorkspace(workspace.id);
  }
}

// 테스트에서
afterEach(() => cleanupSession(session));
```

### Gate 함수

```
프로덕션 클래스에 메서드 추가 전:
  질문: "테스트에서만 사용?"

  yes:
    STOP - 추가 X
    대신 테스트 유틸에 넣음

  질문: "이 클래스가 이 자원의 라이프사이클 소유?"

  no:
    STOP - 이 메서드용 잘못된 클래스
```

## 안티패턴 3: 이해 없이 Mocking

**위반:**
```typescript
// ❌ BAD: mock이 테스트 로직 깨뜨림
test('detects duplicate server', () => {
  // mock이 테스트 의존하는 config write 방지!
  vi.mock('ToolCatalog', () => ({
    discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
  }));

  await addServer(config);
  await addServer(config);  // throw해야 함 - 하지만 안 함!
});
```

**왜 잘못:**
- mock된 메서드가 테스트 의존하는 사이드 이펙트 가짐 (config 쓰기)
- "안전 위해" 과잉 mock이 실제 동작 깨뜨림
- 테스트가 잘못된 이유로 통과 또는 신비롭게 실패

**수정:**
```typescript
// ✅ GOOD: 올바른 레벨에서 mock
test('detects duplicate server', () => {
  // 느린 부분만 mock, 테스트 필요 동작 보존
  vi.mock('MCPServerManager'); // 느린 서버 시작만 mock

  await addServer(config);  // config 쓰여짐
  await addServer(config);  // 중복 감지 ✓
});
```

### Gate 함수

```
어떤 메서드 mock 전:
  STOP - 아직 mock X

  1. 질문: "실제 메서드의 사이드 이펙트는?"
  2. 질문: "이 테스트가 그 사이드 이펙트에 의존?"
  3. 질문: "테스트가 무엇 필요한지 완전 이해?"

  사이드 이펙트 의존:
    더 낮은 레벨에서 mock (실제 느린/외부 연산)
    또는 필요 동작 보존하는 test double 사용
    테스트 의존하는 high-level 메서드 X

  테스트 의존 불확실:
    먼저 실제 구현으로 테스트 실행
    실제로 무엇 일어나야 하는지 관찰
    그 다음 올바른 레벨에 최소 mock 추가

  적신호:
    - "안전 위해 mock"
    - "느릴 수 있음·mock 좋음"
    - 의존성 체인 이해 없이 mock
```

## 안티패턴 4: 불완전 Mock

**위반:**
```typescript
// ❌ BAD: 부분 mock - 필요하다 생각한 필드만
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' }
  // 누락: 다운스트림 코드가 사용하는 metadata
};

// 나중: 코드가 response.metadata.requestId 접근 시 깨짐
```

**왜 잘못:**
- **부분 mock이 구조적 가정 숨김** - 알고 있는 필드만 mock
- **다운스트림 코드가 포함 안 한 필드 의존 가능** - 조용한 실패
- **테스트 통과하지만 통합 실패** - mock 불완전, 실제 API 완전
- **거짓 자신감** - 테스트가 실제 동작 아무것도 증명 X

**철칙:** 즉시 테스트가 사용하는 필드만 아닌 현실에 존재하는 완전 데이터 구조를 mock.

**수정:**
```typescript
// ✅ GOOD: 실제 API 완전성 미러링
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' },
  metadata: { requestId: 'req-789', timestamp: 1234567890 }
  // 실제 API 반환하는 모든 필드
};
```

### Gate 함수

```
mock 응답 생성 전:
  체크: "실제 API 응답이 포함하는 필드는?"

  액션:
    1. docs/예시에서 실제 API 응답 검사
    2. 시스템이 다운스트림 소비할 수 있는 모든 필드 포함
    3. mock이 실제 응답 스키마와 완전 일치 검증

  중요:
    mock 생성 시 전체 구조 이해 필수
    부분 mock은 코드가 생략 필드 의존 시 조용히 실패

  불확실: 모든 문서화 필드 포함
```

## 안티패턴 5: 통합 테스트가 후속

**위반:**
```
✅ 구현 완료
❌ 테스트 작성 안 됨
"테스트 준비"
```

**왜 잘못:**
- 테스팅은 구현의 일부, 선택 follow-up X
- TDD가 이를 잡았을 것
- 테스트 없이 완료 주장 불가

**수정:**
```
TDD 사이클:
1. 실패 테스트 작성
2. 통과시킬 구현
3. 리팩토링
4. 그 다음 완료 주장
```

## Mock이 너무 복잡해질 때

**경고 신호:**
- mock setup이 테스트 로직보다 김
- 테스트 통과시키려 모든 것 mock
- mock이 실제 컴포넌트 메서드 누락
- mock 변경 시 테스트 깨짐

**your human partner의 질문:** "Do we need to be using a mock here?"

**고려:** 실제 컴포넌트로 통합 테스트가 종종 복잡 mock보다 단순

## TDD가 이 안티패턴 방지

**TDD 도움 이유:**
1. **테스트 먼저 작성** → 실제로 무엇 테스트하는지 생각 강제
2. **실패 관찰** → 테스트가 mock 아닌 실제 동작 테스트 확인
3. **최소 구현** → 테스트 전용 메서드 침입 X
4. **실제 의존성** → mock 전 테스트가 실제 무엇 필요한지 봄

**mock 동작 테스트 중이면 TDD 위반** - 먼저 실제 코드 대조 테스트 실패 관찰 없이 mock 추가.

## 빠른 레퍼런스

| Anti-Pattern | Fix |
|--------------|-----|
| mock 요소에 단언 | 실제 컴포넌트 테스트 또는 unmock |
| 프로덕션의 테스트 전용 메서드 | 테스트 유틸로 이동 |
| 이해 없이 mock | 먼저 의존성 이해·최소 mock |
| 불완전 mock | 실제 API 완전 미러링 |
| 후속 테스트 | TDD - 테스트 먼저 |
| 과잉 복잡 mock | 통합 테스트 고려 |

## 적신호

- `*-mock` 테스트 ID 단언 체크
- 테스트 파일에서만 호출되는 메서드
- mock setup이 테스트 50% 이상
- mock 제거 시 테스트 실패
- mock 필요 이유 설명 불가
- "안전 위해" mock

## 핵심

**mock은 격리 도구, 테스트할 것 X.**

TDD가 mock 동작 테스트 중이라 드러내면 잘못 갔음.

수정: 실제 동작 테스트 또는 왜 mock하는지 질문.
