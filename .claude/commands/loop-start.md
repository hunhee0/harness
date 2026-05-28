---
description: 안전 기본값과 명시적 종료 조건을 갖춘 매니지드 자율 루프 패턴 시작 (Start a managed autonomous loop pattern with safety defaults and explicit stop conditions).
---

# Loop Start 명령

안전 기본값을 갖춘 매니지드 자율 루프 패턴 시작.

## 사용법

`/loop-start [pattern] [--mode safe|fast]`

- `pattern`: `sequential`, `continuous-pr`, `rfc-dag`, `infinite`
- `--mode`:
  - `safe` (기본): 엄격한 품질 게이트·체크포인트
  - `fast`: 속도를 위해 감소된 게이트

## 흐름

1. 저장소 상태와 브랜치 전략 확인.
2. 루프 패턴과 모델 티어 전략 선택.
3. 선택 모드에 필요한 hook·프로필 활성화.
4. 루프 계획 작성 및 `.claude/plans/` 하위에 runbook 작성.
5. 루프 시작·모니터링 명령 출력.

## 필수 안전 체크

- 첫 루프 반복 전에 테스트 통과 확인.
- `ECC_HOOK_PROFILE`가 전역 비활성화되지 않았는지 확인.
- 루프에 명시적 종료 조건 존재 확인.

## 인자

$ARGUMENTS:
- `<pattern>` 선택 (`sequential|continuous-pr|rfc-dag|infinite`)
- `--mode safe|fast` 선택
