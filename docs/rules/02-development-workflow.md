# 02. 개발 워크플로우 — SDD + TDD

## SDD 4단계 (Spec-Driven Development)


```
1. /speckit.specify   → docs/spec/{NNN-feature}/spec.md     (무엇을, 왜)
2. /speckit.plan      → docs/spec/{NNN-feature}/plan.md     (어떻게)
3. /speckit.tasks     → docs/spec/{NNN-feature}/tasks.md    (작업 체크리스트)
4. /speckit.implement → src/                                (실제 구현)
```



### BLOCKING 규칙

- ❌ `spec.md` 없이 `src/` 수정 금지
- ❌ 단계 건너뛰기 금지 (순서 엄격)
- ❌ `plan.md` 승인 전 `tasks.md` 생성 금지
- ✅ 각 단계 완료 후 다음 단계 진입 전 `AskUserQuestion`으로 확인
- ✅ `tasks.md` 체크박스 `[ ]` → `[x]` 실시간 업데이트

### SDD 예외 (생략 가능)

- 1~3줄 버그 수정
- 타이포 / 주석 수정
- 환경 변수 / 설정값 변경
- 의존성 minor/patch bump (breaking 아닌 경우)

## TDD 사이클


```
1. Red      → 실패하는 테스트 작성
2. Green    → 테스트 통과시키는 최소 코드
3. Refactor → 중복 제거 (테스트 깨면 안됨)
```


- 버그 수정 = **재현 테스트 먼저** → 그 다음 수정
- 테스트 위치: `tests/{대응 src 경로}/test_{module}.py`
- 신규 기능은 인수 기준(Acceptance Criteria) → 통합 테스트로 1:1 매핑

## 단계별 산출물 형식

### spec.md (무엇을 / 왜)
- 사용자 시나리오 (Given / When / Then)
- 우선순위 (P1 / P2 / P3)
- 수용 기준 (Acceptance Criteria)
- **구현 방법은 적지 않음** (그건 plan.md)

### plan.md (어떻게)
- 아키텍처 결정 (ADR 권장)
- 기술 스택 / 라이브러리 선택 근거
- 데이터 흐름 / 시퀀스
- 영향 범위 (어떤 모듈/계층)
- 위험 요소 / 대안

### tasks.md (작업 체크리스트)
- 한 작업 = 한 커밋 단위
- 양식: `[ ] T01. 작업 설명 → 검증: 확인 방법`
- 의존 관계 표기 (`T03은 T01, T02 완료 후`)

## 브랜치 / 커밋

| 항목 | 규칙 | 예 |
|---|---|---|
| 브랜치 | `{NNN}-{feature-slug}` | `003-fastapi-architecture` |
| 커밋 type | changelog와 동일 | `feat:`, `fix:`, `docs:` |
| 단위 | 1 커밋 = 1 tasks 작업 권장 | — |

## PR 체크리스트

- [ ] 관련 `spec.md` / `plan.md` / `tasks.md` 링크
- [ ] `tasks.md` 모든 체크박스 `[x]`
- [ ] `docs/changelog/` 항목 추가
- [ ] 테스트 추가/수정
- [ ] 사용자 확인 받은 단계 이동 기록
