---
name: speckit-plan
description: plan 템플릿을 사용하여 구현 계획 워크플로우를 실행하고 설계 아티팩트를 생성합니다.
compatibility: .specify/ 디렉토리가 있는 spec-kit 프로젝트 구조 필요
metadata:
  author: github-spec-kit
  source: templates/commands/plan.md
disable-model-invocation: true
---

## 사용자 입력

```text
$ARGUMENTS
```

진행 전 반드시 사용자 입력을 고려하세요 (비어있지 않은 경우).

## 사전 실행 확인

**확장 훅 확인 (계획 전)**:
- 프로젝트 루트에 `.specify/extensions.yml`이 있는지 확인합니다.
- 있는 경우 읽고 `hooks.before_plan` 키 아래의 항목을 찾습니다.
- YAML을 파싱할 수 없거나 유효하지 않은 경우 훅 확인을 자동으로 건너뜁니다.
- `enabled`가 명시적으로 `false`인 훅 필터링. `enabled` 필드가 없는 훅은 기본적으로 활성화된 것으로 처리.
- 각 나머지 훅에 대해 훅 `condition` 표현식 해석 또는 평가 **시도 안 함**:
  - 훅에 `condition` 필드가 없거나 null/비어있으면 훅을 실행 가능으로 처리
  - 훅이 비어있지 않은 `condition`을 정의하면 훅을 건너뛰고 조건 평가를 HookExecutor 구현에 맡김
- 각 실행 가능한 훅에 대해 `optional` 플래그에 따라 다음을 출력:
  - **선택적 훅** (`optional: true`):
    ```
    ## 확장 훅

    **선택적 사전 훅**: {extension}
    명령: `/{command}`
    설명: {description}

    프롬프트: {prompt}
    실행하려면: `/{command}`
    ```
  - **필수 훅** (`optional: false`):
    ```
    ## 확장 훅

    **자동 사전 훅**: {extension}
    실행 중: `/{command}`
    EXECUTE_COMMAND: {command}

    개요로 진행하기 전에 훅 명령 결과를 기다리세요.
    ```
- 훅이 등록되지 않았거나 `.specify/extensions.yml`이 없는 경우 자동으로 건너뜀

## 개요

1. **설정**: 저장소 루트에서 `.specify/scripts/powershell/setup-plan.ps1 -Json`을 실행하고 JSON에서 FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH를 파싱합니다. args에 'I'm Groot'처럼 작은따옴표가 있는 경우 이스케이프 문법 사용: 예) 'I'\''m Groot' (또는 가능하면 큰따옴표: "I'm Groot").

2. **컨텍스트 로드**: FEATURE_SPEC과 `.specify/memory/constitution.md`를 읽습니다. IMPL_PLAN 템플릿 로드 (이미 복사됨).

3. **계획 워크플로우 실행**: IMPL_PLAN 템플릿의 구조에 따라:
   - 기술 컨텍스트 채우기 (알 수 없는 것은 "NEEDS CLARIFICATION"으로 표시)
   - 헌법에서 헌법 확인 섹션 채우기
   - 게이트 평가 (위반이 정당화되지 않으면 ERROR)
   - 0단계: research.md 생성 (모든 NEEDS CLARIFICATION 해결)
   - 1단계: data-model.md, contracts/, quickstart.md 생성
   - 1단계: 에이전트 스크립트를 실행하여 에이전트 컨텍스트 업데이트
   - 설계 후 헌법 확인 재평가

4. **중단 및 보고**: 명령은 2단계 계획 후 종료. 브랜치, IMPL_PLAN 경로, 생성된 아티팩트 보고.

5. **확장 훅 확인**: 보고 후 프로젝트 루트에 `.specify/extensions.yml`이 있는지 확인합니다.
   - 있는 경우 읽고 `hooks.after_plan` 키 아래의 항목을 찾습니다.
   - YAML을 파싱할 수 없거나 유효하지 않은 경우 훅 확인을 자동으로 건너뜁니다.
   - `enabled`가 명시적으로 `false`인 훅 필터링. `enabled` 필드가 없는 훅은 기본적으로 활성화된 것으로 처리.
   - 각 나머지 훅에 대해 훅 `condition` 표현식 해석 또는 평가 **시도 안 함**:
     - 훅에 `condition` 필드가 없거나 null/비어있으면 훅을 실행 가능으로 처리
     - 훅이 비어있지 않은 `condition`을 정의하면 훅을 건너뛰고 조건 평가를 HookExecutor 구현에 맡김
   - 각 실행 가능한 훅에 대해 `optional` 플래그에 따라 다음을 출력:
     - **선택적 훅** (`optional: true`):
       ```
       ## 확장 훅

       **선택적 훅**: {extension}
       명령: `/{command}`
       설명: {description}

       프롬프트: {prompt}
       실행하려면: `/{command}`
       ```
     - **필수 훅** (`optional: false`):
       ```
       ## 확장 훅

       **자동 훅**: {extension}
       실행 중: `/{command}`
       EXECUTE_COMMAND: {command}
       ```
   - 훅이 등록되지 않았거나 `.specify/extensions.yml`이 없는 경우 자동으로 건너뜀

## 단계

### 0단계: 개요 및 연구

1. **기술 컨텍스트에서 알 수 없는 것 추출**:
   - 각 NEEDS CLARIFICATION → 연구 태스크
   - 각 의존성 → 모범 사례 태스크
   - 각 통합 → 패턴 태스크

2. **연구 에이전트 생성 및 디스패치**:

   ```text
   기술 컨텍스트의 각 알 수 없는 것에 대해:
     태스크: "{기능 컨텍스트}를 위한 {알 수 없는 것} 연구"
   각 기술 선택에 대해:
     태스크: "{도메인}에서 {기술}에 대한 모범 사례 찾기"
   ```

3. 다음 형식을 사용하여 `research.md`에 **발견 통합**:
   - 결정: [선택된 것]
   - 근거: [선택 이유]
   - 고려된 대안: [평가된 다른 것]

**출력**: 모든 NEEDS CLARIFICATION이 해결된 research.md

### 1단계: 설계 및 계약

**전제 조건:** `research.md` 완료

1. **기능 스펙에서 엔티티 추출** → `data-model.md`:
   - 엔티티 이름, 필드, 관계
   - 요구사항에서 유효성 검사 규칙
   - 해당하는 경우 상태 전환

2. **인터페이스 계약 정의** (프로젝트에 외부 인터페이스가 있는 경우) → `/contracts/`:
   - 프로젝트가 사용자 또는 다른 시스템에 노출하는 인터페이스 식별
   - 프로젝트 유형에 적합한 계약 형식 문서화
   - 예시: 라이브러리의 공개 API, CLI 도구의 명령 스키마, 웹 서비스의 엔드포인트, 파서의 문법, 애플리케이션의 UI 계약
   - 프로젝트가 순전히 내부용인 경우 건너뜀 (빌드 스크립트, 일회용 도구 등)

3. **에이전트 컨텍스트 업데이트**:
   - `.specify/scripts/powershell/update-agent-context.ps1 -AgentType claude` 실행
   - 이 스크립트는 사용 중인 AI 에이전트를 탐지함
   - 적절한 에이전트별 컨텍스트 파일 업데이트
   - 현재 계획의 새 기술만 추가
   - 마커 사이의 수동 추가 보존

**출력**: data-model.md, /contracts/*, quickstart.md, 에이전트별 파일

## 핵심 규칙

- 절대 경로 사용
- 게이트 실패 또는 미해결 명확화 시 ERROR
