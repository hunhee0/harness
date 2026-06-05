---
name: speckit-implement
description: tasks.md에 정의된 모든 태스크를 처리하고 실행하여 구현 계획을 수행합니다.
compatibility: .specify/ 디렉토리가 있는 spec-kit 프로젝트 구조 필요
metadata:
  author: github-spec-kit
  source: templates/commands/implement.md
disable-model-invocation: true
---

## 🇰🇷 출력 언어 (절대 규칙)

**모든 응답·진행 보고·에러 메시지는 한국어로 작성한다.** 영어로 답하지 말 것. 코드·키워드·식별자·테스트 출력·로그는 원문 유지하되 그 외 단계 설명·요약·실패 보고는 모두 한국어.

## 사용자 입력

```text
$ARGUMENTS
```

진행 전 반드시 사용자 입력을 고려하세요 (비어있지 않은 경우).

## 사전 실행 확인

**확장 훅 확인 (구현 전)**:
- 프로젝트 루트에 `.specify/extensions.yml`이 있는지 확인합니다.
- 있는 경우 읽고 `hooks.before_implement` 키 아래의 항목을 찾습니다.
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

1. 저장소 루트에서 `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks`를 실행하고 FEATURE_DIR과 AVAILABLE_DOCS 목록을 파싱합니다. 모든 경로는 절대 경로여야 합니다. args에 'I'm Groot'처럼 작은따옴표가 있는 경우 이스케이프 문법 사용: 예) 'I'\''m Groot' (또는 가능하면 큰따옴표: "I'm Groot").

2. **체크리스트 상태 확인** (FEATURE_DIR/checklists/가 있는 경우):
   - checklists/ 디렉토리의 모든 체크리스트 파일 스캔
   - 각 체크리스트에서 다음 카운트:
     - 총 항목: `- [ ]` 또는 `- [X]` 또는 `- [x]`와 일치하는 모든 줄
     - 완료된 항목: `- [X]` 또는 `- [x]`와 일치하는 줄
     - 미완료 항목: `- [ ]`와 일치하는 줄
   - 상태 테이블 생성:

     ```text
     | 체크리스트 | 총계 | 완료 | 미완료 | 상태 |
     |-----------|------|------|--------|------|
     | ux.md     | 12   | 12   | 0      | ✓ PASS |
     | test.md   | 8    | 5    | 3      | ✗ FAIL |
     | security.md | 6  | 6    | 0      | ✓ PASS |
     ```

   - 전체 상태 계산:
     - **PASS**: 모든 체크리스트가 0개의 미완료 항목
     - **FAIL**: 하나 이상의 체크리스트에 미완료 항목 있음

   - **체크리스트가 미완료인 경우**:
     - 미완료 항목 수가 있는 테이블 표시
     - **중단**하고 묻기: "일부 체크리스트가 미완료입니다. 구현을 진행하시겠습니까? (yes/no)"
     - 계속하기 전에 사용자 응답 기다리기
     - 사용자가 "no" 또는 "wait" 또는 "stop"이라고 하면 실행 중단
     - 사용자가 "yes" 또는 "proceed" 또는 "continue"라고 하면 3단계로 진행

   - **모든 체크리스트가 완료인 경우**:
     - 모든 체크리스트 통과를 보여주는 테이블 표시
     - 자동으로 3단계로 진행

3. 구현 컨텍스트 로드 및 분석:
   - **필수**: 완전한 태스크 목록과 실행 계획을 위해 tasks.md 읽기
   - **필수**: 기술 스택, 아키텍처, 파일 구조를 위해 plan.md 읽기
   - **있는 경우**: 엔티티와 관계를 위해 data-model.md 읽기
   - **있는 경우**: API 명세와 테스트 요구사항을 위해 contracts/ 읽기
   - **있는 경우**: 기술 결정과 제약을 위해 research.md 읽기
   - **있는 경우**: 통합 시나리오를 위해 quickstart.md 읽기

4. **프로젝트 설정 확인**:
   - **필수**: 실제 프로젝트 설정에 따라 무시 파일 생성/확인:

   **탐지 및 생성 로직**:
   - 다음 명령이 성공하는지 확인하여 저장소가 git 저장소인지 결정 (.gitignore 생성/확인):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Dockerfile*이 있거나 plan.md에 Docker가 있으면 → .dockerignore 생성/확인
   - .eslintrc*가 있으면 → .eslintignore 생성/확인
   - eslint.config.*가 있으면 → config의 `ignores` 항목이 필요한 패턴을 커버하는지 확인
   - .prettierrc*가 있으면 → .prettierignore 생성/확인
   - .npmrc 또는 package.json이 있으면 → .npmignore 생성/확인 (게시하는 경우)
   - terraform 파일(*.tf)이 있으면 → .terraformignore 생성/확인
   - .helmignore가 필요한 경우 (helm 차트가 있음) → .helmignore 생성/확인

   **무시 파일이 이미 있는 경우**: 필수 패턴 포함 여부 확인, 누락된 중요 패턴만 추가
   **무시 파일이 없는 경우**: 탐지된 기술에 맞는 전체 패턴 세트로 생성

   **기술별 일반 패턴** (plan.md 기술 스택에서):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `*.dll`, `autom4te.cache/`, `config.status`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **범용**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **도구별 패턴**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

5. tasks.md 구조를 파싱하고 다음을 추출:
   - **태스크 단계**: 설정, 테스트, 코어, 통합, 마무리
   - **태스크 의존성**: 순차적 vs 병렬 실행 규칙
   - **태스크 세부사항**: ID, 설명, 파일 경로, 병렬 마커 [P]
   - **실행 흐름**: 순서와 의존성 요구사항

6. 태스크 계획에 따라 구현 실행:
   - **단계별 실행**: 다음으로 이동하기 전에 각 단계 완료
   - **의존성 존중**: 순차적 태스크는 순서대로, 병렬 태스크 [P]는 함께 실행 가능
   - **TDD 방식 따르기**: 해당 구현 태스크 전에 테스트 태스크 실행
   - **파일 기반 조정**: 동일 파일에 영향을 주는 태스크는 순차적으로 실행해야 함
   - **검증 체크포인트**: 진행 전에 각 단계 완료 확인

7. 구현 실행 규칙:
   - **설정 먼저**: 프로젝트 구조, 의존성, 설정 초기화
   - **코드 전 테스트**: 계약, 엔티티, 통합 시나리오에 대한 테스트를 작성해야 하는 경우
   - **코어 개발**: 모델, 서비스, CLI 명령, 엔드포인트 구현
   - **통합 작업**: 데이터베이스 연결, 미들웨어, 로깅, 외부 서비스
   - **마무리 및 검증**: 단위 테스트, 성능 최적화, 문서화

8. 진행 추적 및 오류 처리:
   - 각 완료된 태스크 후 진행 보고
   - 비병렬 태스크가 실패하면 실행 중단
   - 병렬 태스크 [P]의 경우 성공한 태스크는 계속하고 실패한 것은 보고
   - 디버깅을 위한 컨텍스트와 함께 명확한 오류 메시지 제공
   - 구현을 진행할 수 없는 경우 다음 단계 제안
   - **중요** 완료된 태스크의 경우 tasks 파일에서 [X]로 표시해야 합니다.

9. 완료 검증:
   - 모든 필수 태스크가 완료되었는지 확인
   - 구현된 기능이 원래 명세와 일치하는지 확인
   - 테스트가 통과하고 커버리지가 요구사항을 충족하는지 검증
   - 구현이 기술 계획을 따르는지 확인
   - 완료된 작업 요약과 함께 최종 상태 보고

참고: 이 명령은 tasks.md에 완전한 태스크 분해가 있다고 가정합니다. 태스크가 불완전하거나 없는 경우 `/speckit-tasks`를 먼저 실행하여 태스크 목록을 재생성하도록 제안합니다.

10. **확장 훅 확인**: 완료 검증 후 프로젝트 루트에 `.specify/extensions.yml`이 있는지 확인합니다.
    - 있는 경우 읽고 `hooks.after_implement` 키 아래의 항목을 찾습니다.
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
