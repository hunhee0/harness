<!-- ⚠️ [EXAMPLE] 참조용 예시. /speckit-plan 으로 생성하세요. -->

# plan — 사용자 로그인 (example-feature) [EXAMPLE]

- **Created**: 2026-06-03
- **기반 spec**: `spec.md` (FR-1~5)

## 1. 접근 방식

Thin Router → Fat Service. 라우터는 입출력만, 인증 로직은 `AuthService`로 분리. JWT는 `python-jose`, 해시는 `passlib[bcrypt]`.

## 2. 아키텍처 / 모듈

| 계층 | 파일 | 책임 |
|------|------|------|
| Router | `src/api/v1/endpoints/auth.py` | `POST /auth/login` I/O, 의존성 주입 |
| Schema | `src/schemas/auth.py` | `LoginRequest`, `TokenResponse` (Pydantic) |
| Service | `src/services/auth_service.py` | 자격 검증, 토큰 발급 |
| Core | `src/core/security.py` | 해시 비교, JWT encode/decode |
| Config | `src/core/config.py` | `JWT_SECRET`, `JWT_EXPIRE_MIN` (pydantic-settings) |

## 3. 데이터 흐름

`login()` → `AuthService.authenticate(email, pw)` → repo 사용자 조회 → `verify_password` → `create_access_token(sub=user_id)` → `TokenResponse`.

## 4. 의존성 / 결정

- rate limit: `slowapi` (FR-5). 미들웨어로 `/auth/login`에 적용.
- 시크릿: `.env`의 `JWT_SECRET` (≥32바이트). `.gitignore`로 보호.

## 5. 위험 / 트레이드오프

- bcrypt 비용 인자 ↑ = 보안 ↑ / 지연 ↑. 기본 12로 시작, NFR p95 측정 후 조정.
- 계정 열거 방지를 위해 "사용자 없음"과 "비번 틀림"을 동일 401로 처리.

## 6. 테스트 전략

- 단위: `verify_password`, `create/decode token`(만료 경계 `<` 포함), `authenticate` 성공/실패.
- 통합: `POST /auth/login` 200/401/429, 만료 토큰으로 보호 엔드포인트 401.
