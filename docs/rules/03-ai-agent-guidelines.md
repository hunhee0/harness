# 03-AI 에이전트 사용 가이드라인

**작성일**: 2026-05-14  
**최종 수정**: 2026-05-15

---

## 🤖 설치된 스킬/에이전트 목록

이 프로젝트는 전역적으로 다음 스킬/에이전트들을 사용할 수 있습니다.

### superpowers

| 스킬 | 사용 시점 |
|---|---|
| `brainstorming` | 새 기능 설계 전 |
| `writing-plans` | 구현 전 계획 수립 |
| `test-driven-development` | 코드 작성 시 (TDD) |
| `systematic-debugging` | 버그/오류 발생 시 |
| `verification-before-completion` | 작업 완료 전 검증 |
| `subagent-driven-development` | 복잡한 구현 위임 시 |
| `dispatching-parallel-agents` | 독립 작업 병렬 처리 시 |
| `requesting-code-review` | 코드 리뷰 요청 전 |
| `receiving-code-review` | 코드 리뷰 피드백 받을 때 |
| `finishing-a-development-branch` | 브랜치 완료/PR 시 |

### speckit

| 스킬 | 사용 시점 |
|---|---|
| `/speckit-specify` | 새 기능 스펙 작성 시 |
| `/speckit-plan` | 스펙 기반 구현 계획 시 |
| `/speckit-tasks` | 태스크 분해 시 |
| `/speckit-implement` | 태스크 기반 구현 시 |

### gstack

| 스킬 | 사용 시점 |
|---|---|
| `/investigate` | 이슈 루트 원인 분석 |
| `/qa`, `/qa-only` | QA 테스트 |
| `/review` | PR 코드 리뷰 |
| `/ship` | 배포 워크플로우 |
| `/health` | 코드 품질 스코어 |
| `/cso` | 보안 감사 |
| `/plan-eng-review` | 엔지니어링 아키텍처 리뷰 |

### ECC

| 스킬 | 사용 시점 |
|---|---|
| `python-patterns` | Python 코드 작성 |
| `python-testing` | Python 테스트 작성 |
| `backend-patterns` | FastAPI/백엔드 작업 |
| `api-design` | REST API 설계 |
| `tdd-workflow` | TDD 워크플로우 |
| `coding-standards` | 코딩 컨벤션 준수 |

### etc
| 스킬 | 사용 시점 |
|---|---|
| `ktds-security-checklist` | KTDS 보안 체크리스트 |

---

## ⚠️ 스킬 사용 규칙

1. **사용 전 확인**: 스킬 실행 전 `question` 툴로 사용자 확인 (옵션 작성 원칙은 `CLAUDE.md` §3 참조).
   메타 옵션("진행/보류/질문") 대신 **실제 의사결정 분기**(스킬 A vs B, 범위 축소 vs 전체)로 제시.
2. **Domain Matching**: 작업 도메인과 가장 잘 맞는 스킬 선택
3. **User Skills Priority**: 사용자 설치 스킬이 기본 스킬보다 우선
4. **유연한 활용**: Speckit에 국한되지 않고 superpowers/ECC/gstack 스킬을 상황에 맞게 활용
5. **Net-zero 원칙**: 새 스킬을 추가할 때 사용하지 않는 스킬은 이 목록에서 제거 (Instruction overload 방지)
