# 02-개발 워크플로우 (SDD + Speckit + TDD)

**작성일**: 2026-05-14  
**최종 수정**: 2026-05-15

---

## 🔄 개발 파이프라인

이 프로젝트는 **Spec-Driven Development (SDD)** + **Test-Driven Development (TDD)** 방식을 따릅니다.

### Speckit 4단계 워크플로우

| 단계 | 명령 | 생성 파일 | 설명 |
|---|---|---|---|
| 1 | `/speckit.specify` | `docs/spec/{feature}/spec.md` | 기능 명세 작성 |
| 2 | `/speckit.plan` | `docs/spec/{feature}/plan.md` | 구현 계획 수립 |
| 3 | `/speckit.tasks` | `docs/spec/{feature}/tasks.md` | 작업 분해 |
| 4 | `/speckit.implement` | `src/` | 실제 구현 |

> ⚡ **단계 이동 전 반드시 사용자 확인 필요** — 각 단계 완료 후 다음 단계로 넘어가기 전 사용자에게 확인

### 스펙 파일 관리 규칙

1. **기능별 디렉토리 분리**: `docs/spec/{feature-name}/`
2. **날짜 필수 기록**:
   - 생성일자: `Created: YYYY-MM-DD`
   - 수정일자: `Updated: YYYY-MM-DD`
   - 구현 완료일자: `Implemented: YYYY-MM-DD` (완료 시)
3. **명확한 기능 식별**: 디렉토리명은 기능명을 영문 소문자로 (예: `user-auth`, `payment-api`)

### TDD 개발 방식

1. **테스트 먼저 작성**: 구현 코드보다 테스트 코드 먼저
2. **커버리지 목표**: 80% 이상
3. **테스트 유형**:
   - Unit test (로직 검증)
   - Integration test (컴포넌트 간 연동)
   - E2E test (전체 흐름)

### 병렬 처리 및 서브 에이전트 위임

**독립적인 작업은 항상 서브 에이전트에 병렬로 위임하세요.**

- 2개 이상의 독립 작업 → `task()` 로 병렬 위임
- 컨텍스트 절약을 위해 서브 에이전트에 명확한 범위/파일 경로/기존 패턴 전달
- 직접 구현하지 않고 프롬프트 작성에 집중

**위임 시 필수 포함 사항**:
- GOAL (성공 기준)
- 파일 경로 및 제약사항
- 기존 패턴 참조 파일
- 명확한 범위 경계 (IN scope / OUT of scope)

### tasks.md 체크박스 추적 규칙

**`/speckit.tasks` 로 생성된 `docs/spec/{feature}/tasks.md` 파일에는 `[ ]` 체크박스가 포함됩니다.**  
각 태스크 구현 완료 시 체크박스를 `[x]` 로 업데이트하세요.

**규칙**:
1. **태스크 시작 시**: 해당 태스크를 `[ ]` 상태에서 작업 시작
2. **태스크 완료 시**: 즉시 `[x]` 로 변경하고, `docs/spec/{feature}/tasks.md` 파일 업데이트
3. **진행 상황 확인**: `question` 툴 또는 텍스트로 현재 완료율 보고 가능
4. **모든 태스크 완료 시**: tasks.md 의 모든 체크박스가 `[x]` 상태가 되었는지 최종 확인

**예시**:
```markdown
## Tasks
- [x] T1: 데이터베이스 스키마 설계 → 완료 (2026-05-14)
- [x] T2: API 엔드포인트 구현 → 완료 (2026-05-14)
- [ ] T3: 프론트엔드 컴포넌트 구현 → 진행 중
- [ ] T4: E2E 테스트 작성 → 미시작
```
