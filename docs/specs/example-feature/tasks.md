<!-- ⚠️ [EXAMPLE] 참조용 예시. /speckit-tasks 로 생성하세요. 체크박스는 구현 완료 시 [x]로 갱신. -->

# tasks — 사용자 로그인 (example-feature) [EXAMPLE]

- **기반 plan**: `plan.md`
- 각 태스크는 TDD (RED → GREEN → REFACTOR). 테스트 먼저.
- 완료 즉시 `[ ]` → `[x]`. (아래는 미착수 예시 상태)

## Tasks

- [ ] T1: `core/config.py` — `JWT_SECRET`·`JWT_EXPIRE_MIN` 설정 로드 (test: 누락 시 에러)
- [ ] T2: `core/security.py` — `hash_password`/`verify_password` (RED: 평문≠해시, 매칭 통과)
- [ ] T3: `core/security.py` — `create_access_token`/`decode_token` (RED: 만료 경계 `<` 검증)
- [ ] T4: `schemas/auth.py` — `LoginRequest`(email 검증)·`TokenResponse`
- [ ] T5: `services/auth_service.py` — `authenticate()` 성공/실패 (RED: 무효 자격 → 예외)
- [ ] T6: `api/v1/endpoints/auth.py` — `POST /auth/login` 200/401 (통합 테스트)
- [ ] T7: rate limit (`slowapi`) 적용 → 429 (통합 테스트) [FR-5]
- [ ] T8: 만료 토큰으로 보호 엔드포인트 401 (통합 회귀 테스트)
- [ ] T9: 커버리지 측정 ≥ 80% — 미달 시 누락 테스트 보강

## 병렬 가능 그룹 (dispatching-parallel-agents 후보)

- T2·T3 (security 유닛)은 T1 후 독립 → 병렬 가능.
- T6·T7은 공유 라우터/미들웨어 상태 → 순차.
