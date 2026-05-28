---
name: api-connector-builder
description: 타겟 레포의 기존 통합 패턴을 정확히 맞춰 새 API 커넥터·프로바이더 구축. 별도 아키텍처를 만들지 않고 통합 한 개를 추가할 때 사용 (Build a new API connector or provider by matching the target repo's existing integration pattern exactly. Use when adding one more integration without inventing a second architecture).
origin: ECC direct-port adaptation
version: "1.0.0"
---

# API Connector Builder

일반적 HTTP 클라이언트가 아닌 레포 네이티브 통합 표면 추가 작업에 사용.

핵심은 호스트 저장소의 패턴 매칭:

- 커넥터 레이아웃
- 설정 스키마
- 인증 모델
- 에러 처리
- 테스트 스타일
- 등록/디스커버리 와이어링

## 사용 시점

- "이 프로젝트에 Jira 커넥터 구축"
- "기존 패턴 따라 Slack 프로바이더 추가"
- "이 API용 새 통합 만들기"
- "레포의 커넥터 스타일에 맞는 플러그인 구축"

## 가드레일

- 레포에 이미 통합 아키텍처가 있는데 새 아키텍처 발명 금지
- 벤더 docs만으로 시작 금지. 기존 in-repo 커넥터부터 시작
- 레포가 registry 와이어링·테스트·문서를 기대하는데 transport 코드에서 멈추기 금지
- 더 새로운 현재 패턴이 있는데 오래된 커넥터를 cargo-cult 금지

## 워크플로

### 1. 하우스 스타일 학습

기존 커넥터·프로바이더 최소 2개 검사·매핑:

- 파일 레이아웃
- 추상화 경계
- 설정 모델
- 재시도 / 페이지네이션 관례
- registry hook
- 테스트 픽스처·명명

### 2. 타겟 통합 좁히기

레포가 실제로 필요한 표면만 정의:

- 인증 흐름
- 핵심 엔티티
- 핵심 read/write 연산
- 페이지네이션·rate limit
- webhook 또는 폴링 모델

### 3. 레포 네이티브 레이어로 구축

전형적 슬라이스:

- config/schema
- client/transport
- mapping 레이어
- connector/provider 진입점
- registration
- 테스트

### 4. 소스 패턴 대비 검증

새 커넥터는 코드베이스에서 자연스러워 보여야 함. 다른 생태계에서 가져온 것처럼 보이면 안 됨.

## 참조 형태

### Provider 스타일

```text
providers/
  existing_provider/
    __init__.py
    provider.py
    config.py
```

### Connector 스타일

```text
integrations/
  existing/
    client.py
    models.py
    connector.py
```

### TypeScript 플러그인 스타일

```text
src/integrations/
  existing/
    index.ts
    client.ts
    types.ts
    test.ts
```

## 품질 체크리스트

- [ ] 기존 in-repo 통합 패턴과 일치
- [ ] 설정 검증 존재
- [ ] 인증·에러 처리가 명시적
- [ ] 페이지네이션·재시도 동작이 레포 표준 따름
- [ ] registry/discovery 와이어링 완전
- [ ] 테스트가 호스트 레포 스타일 미러링
- [ ] 레포가 기대하면 문서·예제 업데이트

## 관련 스킬

- `backend-patterns`
- `mcp-server-patterns`
- `github-ops`
