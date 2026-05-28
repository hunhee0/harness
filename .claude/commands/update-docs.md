---
description: 스크립트·스키마·라우트·export 같은 단일 진실 원천 파일에서 문서 동기화 (Sync documentation from source-of-truth files such as scripts, schemas, routes, and exports).
---

# Update Documentation

코드베이스와 문서 동기화, 단일 진실 원천 파일에서 생성.

## Step 1: 단일 진실 원천 식별

| Source | Generates |
|--------|-----------|
| `package.json` scripts | 사용 가능한 명령 레퍼런스 |
| `.env.example` | 환경 변수 문서 |
| `openapi.yaml` / 라우트 파일 | API 엔드포인트 레퍼런스 |
| 소스 코드 export | public API 문서 |
| `Dockerfile` / `docker-compose.yml` | 인프라 셋업 문서 |

## Step 2: 스크립트 레퍼런스 생성

1. `package.json` (또는 `Makefile`·`Cargo.toml`·`pyproject.toml`) 읽기
2. 모든 스크립트/명령과 설명 추출
3. 레퍼런스 테이블 생성:

```markdown
| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server with hot reload |
| `npm run build` | Production build with type checking |
| `npm test` | Run test suite with coverage |
```

## Step 3: 환경 변수 문서 생성

1. `.env.example` (또는 `.env.template`·`.env.sample`) 읽기
2. 모든 변수와 용도 추출
3. 필수 vs 선택 분류
4. 기대 형식·유효 값 문서화

```markdown
| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DATABASE_URL` | Yes | PostgreSQL connection string | `postgres://user:pass@host:5432/db` |
| `LOG_LEVEL` | No | Logging verbosity (default: info) | `debug`, `info`, `warn`, `error` |
```

## Step 4: 기여 가이드 업데이트

`docs/CONTRIBUTING.md` 생성·업데이트:
- 개발 환경 셋업 (필수 요건·설치 단계)
- 사용 가능 스크립트와 용도
- 테스트 절차 (실행 방법·새 테스트 작성 방법)
- 코드 스타일 시행 (린터·포매터·pre-commit hook)
- PR 제출 체크리스트

## Step 5: 런북 업데이트

`docs/RUNBOOK.md` 생성·업데이트:
- 배포 절차 (단계별)
- 헬스 체크 엔드포인트와 모니터링
- 일반 이슈와 수정
- 롤백 절차
- 알림·에스컬레이션 경로

## Step 6: Staleness 체크

1. 90일 이상 수정 안 된 문서 파일 찾기
2. 최근 소스 코드 변경과 교차 참조
3. 잠재적으로 outdated된 문서를 수동 리뷰용으로 플래그

## Step 7: 요약 표시

```
Documentation Update
──────────────────────────────
Updated:  docs/CONTRIBUTING.md (scripts table)
Updated:  docs/ENV.md (3 new variables)
Flagged:  docs/DEPLOY.md (142 days stale)
Skipped:  docs/API.md (no changes detected)
──────────────────────────────
```

## 규칙

- **단일 진실 원천**: 항상 코드에서 생성, 생성된 섹션 수동 편집 금지
- **수동 섹션 보존**: 생성된 섹션만 업데이트, 손으로 쓴 산문은 그대로
- **생성 컨텐츠 표시**: 생성된 섹션 주변에 `<!-- AUTO-GENERATED -->` 마커 사용
- **무단 문서 생성 금지**: 명령이 명시적으로 요청할 때만 새 문서 파일 생성
