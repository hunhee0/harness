---
description: 프로젝트 구조 스캔, 토큰 효율적 아키텍처 코드맵 생성 (Scan project structure and generate token-lean architecture codemaps).
---

# Update Codemaps

코드베이스 구조 분석, 토큰 효율적 아키텍처 문서 생성.

## Step 1: 프로젝트 구조 스캔

1. 프로젝트 타입 식별 (monorepo·단일 앱·라이브러리·마이크로서비스)
2. 모든 소스 디렉터리 검색 (src/·lib/·app/·packages/)
3. 진입점 매핑 (main.ts·index.ts·app.py·main.go 등)

## Step 2: 코드맵 생성

`docs/CODEMAPS/` (또는 `.reports/codemaps/`)에 코드맵 생성·업데이트:

| File | Contents |
|------|----------|
| `architecture.md` | 상위 시스템 다이어그램·서비스 경계·데이터 흐름 |
| `backend.md` | API 라우트·미들웨어 체인·service → repository 매핑 |
| `frontend.md` | 페이지 트리·컴포넌트 계층·상태 관리 흐름 |
| `data.md` | DB 테이블·관계·마이그레이션 히스토리 |
| `dependencies.md` | 외부 서비스·서드파티 통합·공유 라이브러리 |

### 코드맵 형식

각 코드맵은 토큰 효율적이어야 함 — AI 컨텍스트 소비에 최적화:

```markdown
# Backend Architecture

## Routes
POST /api/users → UserController.create → UserService.create → UserRepo.insert
GET  /api/users/:id → UserController.get → UserService.findById → UserRepo.findById

## Key Files
src/services/user.ts (business logic, 120 lines)
src/repos/user.ts (database access, 80 lines)

## Dependencies
- PostgreSQL (primary data store)
- Redis (session cache, rate limiting)
- Stripe (payment processing)
```

## Step 3: Diff 탐지

1. 이전 코드맵 존재 시 diff 퍼센티지 계산
2. 변경 > 30%면 diff 표시·덮어쓰기 전 사용자 승인 요청
3. 변경 <= 30%면 인플레이스 업데이트

## Step 4: 메타데이터 추가

각 코드맵에 freshness 헤더 추가:

```markdown
<!-- Generated: 2026-02-11 | Files scanned: 142 | Token estimate: ~800 -->
```

## Step 5: 분석 리포트 저장

`.reports/codemap-diff.txt`에 요약 작성:
- 마지막 스캔 이후 추가/제거/수정된 파일
- 감지된 새 의존성
- 아키텍처 변경 (새 라우트·새 서비스 등)
- 90일 이상 업데이트 안 된 문서의 staleness 경고

## 팁

- 구현 디테일이 아닌 **상위 구조**에 집중
- 전체 코드 블록보다 **파일 경로·함수 시그니처** 선호
- 효율적 컨텍스트 로딩을 위해 각 코드맵 **1000 토큰 미만** 유지
- 장황한 설명 대신 데이터 흐름에 ASCII 다이어그램 사용
- 주요 기능 추가·리팩토링 세션 후 실행
