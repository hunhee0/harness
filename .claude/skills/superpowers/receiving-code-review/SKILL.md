---
name: receiving-code-review
description: 코드 리뷰 피드백 받을 때·제안 구현 전·특히 피드백이 불명확·기술적으로 의문스러울 때 사용 — 수행 합의·맹목 구현 아닌 기술적 엄격성·검증 요구 (Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation)
---

# 코드 리뷰 수신

## 개요

코드 리뷰는 감정적 수행이 아닌 기술적 평가 요구.

**핵심 원칙:** 구현 전 검증. 가정 전 질문. 사회적 편안함보다 기술적 정확성.

## 응답 패턴

```
코드 리뷰 피드백 받을 때:

1. READ: 반응 없이 전체 피드백 읽기
2. UNDERSTAND: 요구사항을 자신의 말로 재진술 (또는 질문)
3. VERIFY: 코드베이스 현실과 대조 체크
4. EVALUATE: 이 코드베이스에 기술적으로 건전?
5. RESPOND: 기술적 인정 또는 합리적 푸시백
6. IMPLEMENT: 한 번에 하나씩·각각 테스트
```

## 금지 응답

**절대 X:**
- "You're absolutely right!" (CLAUDE.md 명시 위반)
- "Great point!" / "Excellent feedback!" (수행적)
- "Let me implement that now" (검증 전)

**대신:**
- 기술 요구사항 재진술
- 명확화 질문
- 잘못된 경우 기술적 추론으로 푸시백
- 그냥 작업 시작 (행동 > 말)

## 불명확 피드백 처리

```
어떤 항목 불명확 시:
  STOP - 아직 아무것도 구현 X
  불명확 항목 명확화 요청

WHY: 항목이 관련 가능. 부분 이해 = 잘못된 구현.
```

**예:**
```
your human partner: "Fix 1-6"
1,2,3,6 이해. 4,5 불명확.

❌ WRONG: 1,2,3,6 지금 구현, 4,5는 나중 질문
✅ RIGHT: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."
```

## 소스별 처리

### your human partner로부터
- **신뢰** - 이해 후 구현
- 스코프 불명확 시 **여전히 질문**
- **수행적 합의 X**
- **액션으로 건너뜀** 또는 기술적 인정

### 외부 리뷰어로부터
```
구현 전:
  1. 체크: 이 코드베이스에 기술적으로 올바른?
  2. 체크: 기존 기능 깨뜨림?
  3. 체크: 현재 구현 이유?
  4. 체크: 모든 플랫폼/버전에서 동작?
  5. 체크: 리뷰어가 전체 컨텍스트 이해?

제안이 잘못 보임:
  기술적 추론으로 푸시백

쉽게 검증 불가:
  말함: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"

your human partner의 이전 결정과 충돌:
  먼저 your human partner와 중단·논의
```

**your human partner의 규칙:** "External feedback - be skeptical, but check carefully"

## "Professional" 기능에 YAGNI 체크

```
리뷰어가 "구현 적절히" 제안 시:
  실제 사용에 코드베이스 grep

  미사용: "This endpoint isn't called. Remove it (YAGNI)?"
  사용 중: 그러면 적절히 구현
```

**your human partner의 규칙:** "You and reviewer both report to me. If we don't need this feature, don't add it."

## 구현 순서

```
다중 항목 피드백:
  1. 불명확한 것 먼저 명확화
  2. 그 다음 이 순서로 구현:
     - 차단 이슈 (깨짐·보안)
     - 단순 수정 (오타·import)
     - 복잡 수정 (리팩토링·로직)
  3. 각 수정 개별 테스트
  4. 회귀 없음 검증
```

## 푸시백 시점

푸시백:
- 제안이 기존 기능 깨뜨림
- 리뷰어가 전체 컨텍스트 부족
- YAGNI 위반 (미사용 기능)
- 이 스택에 기술적으로 부정확
- 레거시/호환성 이유 존재
- your human partner의 아키텍처 결정과 충돌

**푸시백 방법:**
- 방어적 X·기술적 추론 사용
- 특정 질문 요청
- 동작 테스트/코드 참조
- 아키텍처면 your human partner 참여

**소리내어 푸시백 불편 시 신호:** "Strange things are afoot at the Circle K"

## 올바른 피드백 인정

피드백이 맞을 때:
```
✅ "Fixed. [변경 짧은 설명]"
✅ "Good catch - [특정 이슈]. Fixed in [위치]."
✅ [그냥 수정·코드로 표시]

❌ "You're absolutely right!"
❌ "Great point!"
❌ "Thanks for catching that!"
❌ "Thanks for [무엇이든]"
❌ 어떤 감사 표현
```

**감사 X 이유:** 행동이 말함. 그냥 수정. 코드 자체가 피드백 들었음을 보여줌.

**"Thanks" 쓸 뻔하면:** DELETE IT. 대신 수정 진술.

## 푸시백 우아하게 정정

푸시백했는데 틀렸으면:
```
✅ "You were right - I checked [X] and it does [Y]. Implementing now."
✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."

❌ 긴 사과
❌ 푸시백 이유 방어
❌ 과잉 설명
```

정정을 사실적으로 진술·이동.

## 일반 실수

| Mistake | Fix |
|---------|-----|
| 수행적 합의 | 요구사항 진술 또는 그냥 행동 |
| 맹목 구현 | 먼저 코드베이스 대조 검증 |
| 테스트 없이 배치 | 한 번에 하나씩·각각 테스트 |
| 리뷰어 맞다고 가정 | 깨뜨림 체크 |
| 푸시백 회피 | 기술적 정확성 > 편안함 |
| 부분 구현 | 모든 항목 먼저 명확화 |
| 검증 불가, 어쨌든 진행 | 한계 진술·방향 요청 |

## 실제 예시

**수행적 합의 (Bad):**
```
Reviewer: "Remove legacy code"
❌ "You're absolutely right! Let me remove that..."
```

**기술적 검증 (Good):**
```
Reviewer: "Remove legacy code"
✅ "Checking... build target is 10.15+, this API needs 13+. Need legacy for backward compat. Current impl has wrong bundle ID - fix it or drop pre-13 support?"
```

**YAGNI (Good):**
```
Reviewer: "Implement proper metrics tracking with database, date filters, CSV export"
✅ "Grepped codebase - nothing calls this endpoint. Remove it (YAGNI)? Or is there usage I'm missing?"
```

**불명확 항목 (Good):**
```
your human partner: "Fix items 1-6"
1,2,3,6 이해. 4,5 불명확.
✅ "Understand 1,2,3,6. Need clarification on 4 and 5 before implementing."
```

## GitHub 스레드 응답

GitHub의 인라인 리뷰 코멘트 응답 시 top-level PR 코멘트 아닌 코멘트 스레드(`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`)에 응답.

## 핵심

**외부 피드백 = 따를 명령 아닌 평가할 제안.**

검증. 질문. 그 다음 구현.

수행적 합의 X. 항상 기술적 엄격성.
