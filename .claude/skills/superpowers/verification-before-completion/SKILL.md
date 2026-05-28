---
name: verification-before-completion
description: 작업 완료·수정·통과 주장 직전·커밋·PR 생성 전 사용 — 어떤 성공 주장 전 검증 명령 실행·출력 확인 요구. 단언 전 항상 증거 (Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always)
---

# 완료 전 검증

## 개요

검증 없이 작업 완료 주장은 효율이 아닌 부정직.

**핵심 원칙:** 항상 주장 전 증거.

**이 규칙의 문자 위반은 이 규칙의 정신 위반.**

## 철칙

```
신선한 검증 증거 없이 완료 주장 X
```

이 메시지에서 검증 명령 실행 안 했으면 통과 주장 불가.

## Gate 함수

```
어떤 상태 주장·만족 표현 전:

1. IDENTIFY: 어떤 명령이 이 주장 증명?
2. RUN: 전체 명령 실행 (신선·완전)
3. READ: 전체 출력·exit code 체크·실패 카운트
4. VERIFY: 출력이 주장 확인?
   - NO: 증거와 함께 실제 상태 진술
   - YES: 증거와 함께 주장 진술
5. 그 후에만: 주장

어떤 단계 건너뜀 = 검증 아닌 거짓말
```

## 일반 실패

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| 테스트 통과 | 테스트 명령 출력: 0 실패 | 이전 실행·"통과해야 함" |
| 린터 깨끗 | 린터 출력: 0 에러 | 부분 체크·추정 |
| 빌드 성공 | 빌드 명령: exit 0 | 린터 통과·로그 좋아 보임 |
| 버그 수정 | 원래 증상 테스트: 통과 | 코드 변경·수정 가정 |
| 회귀 테스트 동작 | red-green 사이클 검증 | 테스트 한 번 통과 |
| 에이전트 완료 | VCS diff가 변경 표시 | 에이전트가 "성공" 보고 |
| 요구사항 만족 | 라인별 체크리스트 | 테스트 통과 |

## 적신호 - STOP

- "should"·"probably"·"seems to" 사용
- 검증 전 만족 표현 ("Great!"·"Perfect!"·"Done!" 등)
- 검증 없이 커밋/push/PR 직전
- 에이전트 성공 보고 신뢰
- 부분 검증 의존
- "이번만" 생각
- 피곤·작업 끝내고 싶음
- **검증 실행 없이 성공 암시하는 어떤 표현**

## 합리화 방지

| Excuse | Reality |
|--------|---------|
| "이제 동작해야 함" | 검증 실행 |
| "자신 있음" | 자신감 ≠ 증거 |
| "이번만" | 예외 X |
| "린터 통과" | 린터 ≠ 컴파일러 |
| "에이전트가 성공 말함" | 독립 검증 |
| "피곤함" | 피로 ≠ 변명 |
| "부분 체크로 충분" | 부분은 아무것도 증명 X |
| "다른 단어라 규칙 적용 X" | 문자 위 정신 |

## 핵심 패턴

**테스트:**
```
✅ [테스트 명령 실행] [보임: 34/34 통과] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**회귀 테스트 (TDD Red-Green):**
```
✅ 작성 → 실행 (통과) → 수정 revert → 실행 (반드시 실패) → 복원 → 실행 (통과)
❌ "I've written a regression test" (red-green 검증 없이)
```

**빌드:**
```
✅ [빌드 실행] [보임: exit 0] "Build passes"
❌ "Linter passed" (린터가 컴파일 체크 X)
```

**요구사항:**
```
✅ 계획 재읽음 → 체크리스트 생성 → 각각 검증 → 갭·완료 보고
❌ "Tests pass, phase complete"
```

**에이전트 위임:**
```
✅ 에이전트가 성공 보고 → VCS diff 체크 → 변경 검증 → 실제 상태 보고
❌ 에이전트 보고 신뢰
```

## 왜 중요

24 실패 메모리에서:
- your human partner가 "I don't believe you" 말함 - 신뢰 깨짐
- 정의 안 된 함수 출하 - crash
- 누락 요구사항 출하 - 불완전 기능
- 거짓 완료에 낭비된 시간 → 리디렉션 → 재작업
- 위반: "Honesty is a core value. If you lie, you'll be replaced."

## 적용 시점

**항상 전:**
- 어떤 성공·완료 주장 변형
- 어떤 만족 표현
- 작업 상태에 대한 어떤 긍정 진술
- 커밋·PR 생성·태스크 완료
- 다음 태스크 이동
- 에이전트 위임

**규칙 적용:**
- 정확한 문구
- 패러프레이즈·동의어
- 성공 암시
- 완료·정확성 시사하는 어떤 통신

## 핵심

**검증 단축 없음.**

명령 실행. 출력 읽기. 그 후 결과 주장.

협상 불가.
