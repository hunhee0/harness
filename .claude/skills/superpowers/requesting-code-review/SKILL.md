---
name: requesting-code-review
description: 태스크 완료·주요 기능 구현 후·merge 전 작업이 요구사항 만족하는지 검증 (Use when completing tasks, implementing major features, or before merging to verify work meets requirements)
---

# 코드 리뷰 요청

이슈가 cascading되기 전 잡기 위해 코드 리뷰어 서브 에이전트 디스패치. 리뷰어는 세션 히스토리 아닌 평가용 정밀 컨텍스트 받음. 이로써 리뷰어가 사고 프로세스 아닌 작업 산출물에 집중·자체 컨텍스트를 계속 작업에 보존.

**핵심 원칙:** 일찍·자주 리뷰.

## 리뷰 요청 시점

**필수:**
- 서브 에이전트 주도 개발의 각 태스크 후
- 주요 기능 완료 후
- main merge 전

**선택적이지만 가치:**
- 막힐 때 (신선한 관점)
- 리팩토링 전 (베이스라인 체크)
- 복잡 버그 수정 후

## 요청 방법

**1. git SHA 획득:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # 또는 origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. 코드 리뷰어 서브 에이전트 디스패치:**

`general-purpose` 타입의 Task 도구 사용. `code-reviewer.md` 템플릿 채움.

**플레이스홀더:**
- `{DESCRIPTION}` - 구축한 것의 짧은 요약
- `{PLAN_OR_REQUIREMENTS}` - 무엇 해야 하는지
- `{BASE_SHA}` - 시작 커밋
- `{HEAD_SHA}` - 끝 커밋

**3. 피드백에 따라 행동:**
- Critical 이슈 즉시 수정
- 진행 전 Important 이슈 수정
- 나중 위해 Minor 이슈 기록
- 리뷰어가 잘못이면 (추론과 함께) 푸시백

## 예시

```
[Task 2 완료: 검증 함수 추가]

You: 진행 전 코드 리뷰 요청.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[코드 리뷰어 서브 에이전트 디스패치]
  DESCRIPTION: 4 이슈 타입으로 verifyIndex()·repairIndex() 추가
  PLAN_OR_REQUIREMENTS: docs/superpowers/plans/deployment-plan.md의 Task 2
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[서브 에이전트 반환]:
  Strengths: 깔끔한 아키텍처·실제 테스트
  Issues:
    Important: 진행 표시 누락
    Minor: 리포팅 간격에 매직 넘버(100)
  Assessment: 진행 준비

You: [진행 표시 수정]
[Task 3로 계속]
```

## 워크플로 통합

**서브 에이전트 주도 개발:**
- 각 태스크 후 리뷰
- 복합 전 이슈 잡기
- 다음 태스크 전 수정

**계획 실행:**
- 각 태스크 후 또는 자연 체크포인트에서 리뷰
- 피드백 받고·적용·계속

**ad-hoc 개발:**
- merge 전 리뷰
- 막힐 때 리뷰

## 적신호

**절대 X:**
- "단순"하다고 리뷰 건너뜀
- Critical 이슈 무시
- 미수정 Important 이슈로 진행
- 유효한 기술적 피드백과 논쟁

**리뷰어 잘못 시:**
- 기술적 추론으로 푸시백
- 동작 증명하는 코드/테스트 표시
- 명확화 요청

템플릿: requesting-code-review/code-reviewer.md 참조
