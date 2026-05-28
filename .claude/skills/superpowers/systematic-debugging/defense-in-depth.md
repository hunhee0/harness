# 다층 방어 검증

## 개요

잘못된 데이터로 인한 버그 수정 시 한 곳에 검증 추가는 충분해 보임. 그러나 그 단일 체크는 다른 코드 경로·리팩토링·mock으로 우회 가능.

**핵심 원칙:** 데이터가 거치는 모든 레이어에서 검증. 버그를 구조적으로 불가능하게 만듦.

## 왜 다중 레이어

단일 검증: "버그 수정했음"
다중 레이어: "버그를 불가능하게 만들었음"

다른 레이어가 다른 케이스 잡음:
- 진입 검증이 대부분 버그 잡음
- 비즈니스 로직이 엣지 케이스 잡음
- 환경 가드가 컨텍스트 특정 위험 방지
- 디버그 로깅이 다른 레이어 실패 시 도움

## 4 레이어

### Layer 1: 진입점 검증
**목적:** API 경계에서 명백히 잘못된 입력 거부

```typescript
function createProject(name: string, workingDirectory: string) {
  if (!workingDirectory || workingDirectory.trim() === '') {
    throw new Error('workingDirectory cannot be empty');
  }
  if (!existsSync(workingDirectory)) {
    throw new Error(`workingDirectory does not exist: ${workingDirectory}`);
  }
  if (!statSync(workingDirectory).isDirectory()) {
    throw new Error(`workingDirectory is not a directory: ${workingDirectory}`);
  }
  // ... 진행
}
```

### Layer 2: 비즈니스 로직 검증
**목적:** 이 연산에 데이터 의미 있는지 보장

```typescript
function initializeWorkspace(projectDir: string, sessionId: string) {
  if (!projectDir) {
    throw new Error('projectDir required for workspace initialization');
  }
  // ... 진행
}
```

### Layer 3: 환경 가드
**목적:** 특정 컨텍스트에서 위험한 연산 방지

```typescript
async function gitInit(directory: string) {
  // 테스트에서 temp 디렉터리 외 git init 거부
  if (process.env.NODE_ENV === 'test') {
    const normalized = normalize(resolve(directory));
    const tmpDir = normalize(resolve(tmpdir()));

    if (!normalized.startsWith(tmpDir)) {
      throw new Error(
        `Refusing git init outside temp dir during tests: ${directory}`
      );
    }
  }
  // ... 진행
}
```

### Layer 4: 디버그 instrumentation
**목적:** 포렌식용 컨텍스트 캡처

```typescript
async function gitInit(directory: string) {
  const stack = new Error().stack;
  logger.debug('About to git init', {
    directory,
    cwd: process.cwd(),
    stack,
  });
  // ... 진행
}
```

## 패턴 적용

버그 발견 시:

1. **데이터 흐름 추적** - 잘못된 값 어디서 발생·어디 사용?
2. **모든 체크포인트 매핑** - 데이터 거치는 모든 지점 나열
3. **각 레이어에 검증 추가** - 진입·비즈니스·환경·디버그
4. **각 레이어 테스트** - layer 1 우회 시도·layer 2가 잡는지 검증

## 세션의 예

버그: 빈 `projectDir`가 소스 코드에서 `git init` 유발

**데이터 흐름:**
1. 테스트 setup → 빈 문자열
2. `Project.create(name, '')`
3. `WorkspaceManager.createWorkspace('')`
4. `git init`이 `process.cwd()`에서 실행

**4 레이어 추가:**
- Layer 1: `Project.create()`가 비어있지 않음·존재·쓰기 가능 검증
- Layer 2: `WorkspaceManager`가 projectDir 비어있지 않음 검증
- Layer 3: `WorktreeManager`가 테스트의 tmpdir 외 git init 거부
- Layer 4: git init 전 스택 트레이스 로깅

**결과:** 1847 테스트 모두 통과·버그 재현 불가

## 핵심 insight

4 레이어 모두 필요. 테스팅 동안 각 레이어가 다른 레이어 놓친 버그 잡음:
- 다른 코드 경로가 진입 검증 우회
- mock이 비즈니스 로직 체크 우회
- 다른 플랫폼의 엣지 케이스가 환경 가드 필요
- 디버그 로깅이 구조적 오용 식별

**한 검증 지점에서 멈추지 X.** 모든 레이어에 체크 추가.
