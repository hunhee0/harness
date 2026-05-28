---
name: harness-adapt
description: 기존 프로젝트에 이 하네스를 자동 분석·적응시키는 onboarding 스킬. "하네스 적용해줘", "하네스 적응", "프로젝트 분석해서 하네스 갱신", "하네스 onboarding", "기존 코드에 맞춰 하네스 수정", "프로젝트 하네스 적응", "하네스 init", "하네스 초기화" 등 setup.ps1/setup.sh로 파일을 복사한 직후 또는 기존 코드베이스에 하네스를 첫 적용·재적응할 때 반드시 이 스킬을 사용할 것. 코드 스택을 분석하여 CLAUDE.md, docs/rules/01-project-structure.md, docs/rules/03-ai-agent-guidelines.md, 필요 시 agent 정의를 자동 수정한다.
---

## 사용 시점

- `setup.ps1` / `setup.sh`로 하네스 파일 복사 직후
- 기존 프로젝트에 처음 하네스를 적용할 때
- 프로젝트 스택·구조가 크게 변경되어 재적응 필요할 때

---

## Phase 0: 사전 확인

다음 파일·디렉토리 존재 확인 (병렬 Glob):

- `.claude/agents/planner.md`, `implementer.md`, `reviewer.md`, `qa.md`
- `.claude/skills/harness-orchestrator/SKILL.md`
- `docs/rules/01-project-structure.md`
- `CLAUDE.md`

| 상황 | 조치 |
|------|------|
| 모두 존재 | Phase 1 진행 |
| 일부 누락 | 사용자에게 보고 → `setup.ps1`/`setup.sh` 먼저 실행 안내 후 종료 |
| 모두 누락 | 동일 |

---

## Phase 1: 프로젝트 스택 탐색

### 1-1. 매니페스트 감지 (병렬 Glob)

루트에서 다음 파일 패턴 탐색:

| 파일 | 언어 / 런타임 | 빌드 도구 |
|------|--------------|-----------|
| `package.json` | Node.js / TypeScript | npm / yarn / pnpm |
| `pyproject.toml`, `requirements.txt`, `Pipfile`, `setup.py` | Python | Poetry / pip / Pipenv / uv |
| `go.mod` | Go | go modules |
| `Cargo.toml` | Rust | cargo |
| `pom.xml`, `build.gradle(.kts)` | Java / Kotlin | Maven / Gradle |
| `*.csproj`, `*.sln` | C# / .NET | dotnet |
| `Package.swift`, `*.xcodeproj` | Swift | SPM / Xcode |
| `composer.json` | PHP | Composer |
| `Gemfile` | Ruby | Bundler |
| `mix.exs` | Elixir | mix |
| `pubspec.yaml` | Dart / Flutter | pub |
| `*.tf`, `Pulumi.yaml`, `cdk.json` | IaC | Terraform / Pulumi / CDK |

**여러 매니페스트 발견 시**: 모노레포·풀스택 가능성 → 디렉토리별 매핑.

### 1-2. 디렉토리 구조 파악

- **소스**: `src/`, `lib/`, `app/`, `cmd/`, `internal/`, `pkg/`
- **테스트**: `tests/`, `test/`, `__tests__/`, `specs/`
- **설정**: `config/`, `conf/`, `.env*`
- **빌드 결과**: `dist/`, `build/`, `target/`, `bin/`, `out/`

### 1-3. 도구 감지

매니페스트의 dependencies / scripts / 설정 파일에서 추출:

- **테스트**: pytest, jest, vitest, mocha, go test, cargo test, JUnit, xunit, RSpec
- **린트**: eslint, ruff, flake8, golangci-lint, clippy, rubocop, ktlint
- **포맷**: prettier, black, gofmt, rustfmt
- **타입체크**: tsc, mypy, pyright

### 1-4. 프레임워크 감지

dependencies 키워드로:

- **백엔드 웹**: fastapi, django, flask, express, nestjs, spring, ktor, gin, echo, rails, laravel
- **프론트엔드**: react, next, vue, nuxt, svelte, solid
- **ML**: torch, tensorflow, sklearn, keras, transformers, jax
- **모바일**: react-native, flutter, swiftui, jetpack compose
- **IaC**: terraform, pulumi, cdk, ansible

### 1-5. 분석 결과 정리

다음 구조로 메모리에 정리 (Phase 3에서 사용):

```yaml
stack:
  primary_language: <e.g. Python>
  runtime_version: <e.g. 3.11+>
  framework: <e.g. FastAPI>
  build_tool: <e.g. Poetry>
  test_framework: <e.g. pytest>
  linter: <e.g. ruff>
  formatter: <e.g. ruff format>
  type_checker: <e.g. mypy>

structure:
  source_dirs: [src/, ...]
  test_dirs: [tests/, ...]
  config_files: [...]

flags:
  monorepo: true|false
  multi_language: true|false
  has_db: true|false
  has_frontend: true|false
```

### 1-6. `[STACK]` 키 매핑 (orchestrator 호환 필수)

`harness-orchestrator/SKILL.md` Phase 0.5 + 각 L1 agent.md 에서 사용하는 `[STACK]` 키. 감지 결과를 다음 키로 정규화하여 모든 산출물(`spec.md` 헤더·orchestrator 매핑 표)에 일관 적용:

| 감지 조건 | `[STACK]` 키 |
|-----------|---------------|
| `pyproject.toml`/`requirements.txt` + FastAPI 의존 | `python-fastapi` |
| `pyproject.toml`/`requirements.txt` (일반 Python) | `python` |
| `pom.xml`/`build.gradle` + Spring 의존 | `java-spring` |
| `pom.xml`/`build.gradle` (일반 Java/Kotlin) | `java` |
| `package.json` + `next.config.*` | `ts-next` |
| `package.json` + `*.tsx`/`*.ts` 다수 | `typescript` |
| `package.json` (JS만) | `javascript` |
| `go.mod` | `go` (신규 — orchestrator 매핑 표에 보강 필요) |
| `Cargo.toml` | `rust` (신규) |
| 기타 (Ruby/PHP/Swift/Dart 등) | 언어 키 그대로 사용 + orchestrator 매핑 표 보강 |

**다중 스택 (모노레포·풀스택)**: `[STACK]=[python-fastapi, ts-next]` 배열 형태로 저장. Phase 3 reviewer 팬아웃이 변경 파일별로 분기.

---

## Phase 2: 도메인 분류

스택·구조 단서로 도메인 추정 후 사용자 확인:

| 단서 | 도메인 |
|------|--------|
| 백엔드 웹 프레임워크 + DB 의존 | **백엔드 API** |
| 프론트엔드 프레임워크 + 빌드 산출물 | **프론트엔드 SPA** |
| 백엔드 + 프론트엔드 동시 | **풀스택** |
| `cmd/`, `bin/`, `cli.ts` 진입점 + 라이브러리성 | **CLI 도구** |
| 외부 의존 적음 + 배포 메타(pypi/crates 등) | **라이브러리 / SDK** |
| ML 라이브러리 + 데이터 디렉토리 | **ML / 데이터** |
| Terraform / Pulumi / CDK / Ansible | **IaC / 인프라** |
| react-native / flutter / swiftui | **모바일** |
| 게임 엔진(Unity/Unreal/Godot) | **게임** |

**추정 결과는 반드시 사용자 `question` 확인** — 추정이 틀리면 이후 모든 수정이 잘못됨.

---

## Phase 3: 파일 자동 수정

### 3-1. 수정 계획 사용자 확인

수정 대상 파일 목록 + 각 파일 변경 요약을 사용자에게 보여주고 옵션 제시:

- **전부 진행** (권장): 모든 파일 일괄 수정
- **선택적 진행**: 파일별 확인
- **보류**: 분석 결과만 보여주고 수정 안 함

### 3-2. 파일별 수정 내용

#### `docs/rules/01-project-structure.md`

| 변경 | 출처 |
|------|------|
| 🟡 잠정(Tentative) 라벨 제거 | 확정 스택 적용 |
| "잠정 기술 스택 후보" 표 → 실제 스택 표 (`[STACK]` 키 포함) | Phase 1-5/1-6 결과 |
| "예시 src/ 레이아웃" → 실제 디렉토리 트리 | Phase 1-2 결과 |
| `.claude/` 디렉토리 트리는 유지 (agents L1+L2, skills/ecc, skills/superpowers, commands, rules/ecc 포함) | 하네스 표준 자원 — 도메인 무관 |
| "아키텍처 원칙" 섹션 | 기존 유지 (도메인 무관) |

#### `CLAUDE.md`

| 변경 | 내용 |
|------|------|
| 제목 | `# CLAUDE.md — {프로젝트명} 진입점`으로 보정 |
| "프로젝트 구조 개요" | 실제 디렉토리 트리 반영. `.claude/` 하위 (agents/skills/commands/rules) 인벤토리는 그대로 유지 |
| Rule 9 변경 이력 테이블 | 초기화 → 첫 행에 "하네스 적응(harness-adapt) 적용 — 스택: `[STACK]` 값, 활성화 L2: ..." 기록 |
| Rule 9 자원 줄 | "스킬 자원: speckit/ECC/superpowers/commands 인벤토리는 03 참조"로 유지 |

#### `docs/rules/03-ai-agent-guidelines.md`

03은 이미 ECC 21·superpowers 8·agents L1+L2 15·commands 10 인벤토리를 완비. **인벤토리 표는 손대지 말 것** (Net-zero). 다음 항목만 추가:

| 변경 | 조건 |
|------|------|
| "L2 활성화 권장 표" 신규 섹션 | 도메인 분류 결과 따라 — 활성 L2와 적용 시점 명시 (아래 3-2-A 표 사용) |
| "도메인 특화 신규 agent" 신규 섹션 | 표준 L2로 커버 안 되는 도메인일 때만 (아래 3-2-B 표) |
| 기존 인벤토리 표 | **수정 금지** — 03 의 ECC/superpowers/commands/agents 항목은 그대로 유지 |

##### 3-2-A. 표준 L2 활성화 권장 (이미 포함, 활성화 신호만 추가)

도메인 분류 결과에 따라 다음 L2 agent를 reviewer 팬아웃 라우팅에 자동 포함시키도록 03에 신호 기록:

| 도메인 | 활성화 L2 agent | 활성화 신호 |
|--------|-----------------|-------------|
| 백엔드 API (Python/FastAPI) | `fastapi-reviewer`, `python-reviewer`, `security-reviewer` (auth 키워드) | `[STACK]=python-fastapi` |
| 백엔드 API (일반 Python) | `python-reviewer`, `security-reviewer` (조건부) | `[STACK]=python` |
| 백엔드 API (Java/Spring) | `java-reviewer`, `security-reviewer` (조건부) + skills: `ecc/springboot-*` | `[STACK]=java-spring` |
| 프론트엔드 SPA | `typescript-reviewer`, `code-reviewer` + skills: `ecc/frontend-patterns`, `ecc/motion-ui`, `ecc/liquid-glass-design`, `ecc/ui-demo` | `[STACK]∈{ts-next, typescript, javascript}` |
| 풀스택 | 위 백엔드 + 프론트 모두 (파일 경로별 분기) | `[STACK]=[backend, frontend]` 배열 |
| 보안 중점 (금융·헬스케어) | `security-reviewer` 를 **항상** 활성 (키워드 게이트 무시) | 사용자 도메인 명시 |

##### 3-2-B. 도메인 특화 신규 agent (표준 L2 미커버 시만 생성)

다음 도메인은 표준 L2로 커버 안 됨 → 사용자 확인 후 `.claude/agents/` 신규 생성:

| 도메인 | 권장 신규 agent | 책임 |
|--------|----------------|------|
| ML / 데이터 | `data-validator`, `model-evaluator` | 데이터 누수·shape·메트릭·재현성 |
| IaC / 인프라 | `iac-validator` | terraform plan diff·비용·보안 정책 |
| 모바일 (iOS/Android) | `platform-reviewer` | iOS HIG / Android Material 준수 |
| 게임 | `gameplay-validator` | 프레임 예산·물리·입력 처리 |
| Go / Rust 백엔드 | `go-reviewer` / `rust-reviewer` | 언어 관용·동시성·메모리 |

신규 agent 추가 시:
1. `.claude/agents/{name}.md` 생성
2. `harness-orchestrator/SKILL.md` Phase 3-2 라우팅 표에 행 추가
3. `docs/rules/03-ai-agent-guidelines.md` L2 인벤토리 표에 행 추가
4. `[STACK]` 키가 신규면 orchestrator Phase 0.5 표에도 추가

### 3-3. 보존 항목 (수정 안 함)

- `docs/rules/02-development-workflow.md` (SDD 흐름은 도메인 무관)
- `docs/rules/04~07` (변경이력·컨텍스트·브랜치·에러복구는 일반론)
- L1 4 agent (planner/implementer/reviewer/qa) 본문 — 위임/팬아웃 매트릭스는 도메인 무관
  - 단, qa.md 의 `검증 깊이 가이드` 표는 도메인별 보강 가능 (사용자 확인 후)
- L2 agent 본문 — 기본 정의 유지. 도메인별 활성화 신호만 03에 추가
- ECC·superpowers·commands 인벤토리 — **수정 금지** (Net-zero)
- `.claude/skills/harness-orchestrator/SKILL.md` 본문 — 신규 `[STACK]` 키 발견·신규 L2 추가 시에만 매핑 표 보강
- `.claude/skills/caveman/`, `.claude/skills/harness-orchestrator/`, `.claude/skills/harness-adapt/` 본문 — 도메인 무관
- `.specify/memory/constitution.md` (헌법은 사용자 직접 작성 — 자동 수정 금지)

---

## Phase 4: 검증 및 보고

### 4-1. 수정 결과 요약

각 수정 파일에 대해:
- 변경 라인 수
- 핵심 변경 사항 3줄 이내
- 보존된 섹션 명시

### 4-2. constitution.md 작성 권유

`question` 옵션:
- **지금 작성**: `/speckit-constitution` 안내
- **직접 편집**: `.specify/memory/README.md` 가이드 안내
- **나중에**: 다음 단계로

### 4-3. 첫 사용 가이드 출력

```
다음 단계:
1. (선택) /speckit-constitution 으로 프로젝트 헌법 작성
2. 첫 기능 개발: "기능 만들어줘" → harness-orchestrator 자동 트리거
3. SDD 4단계 진행 (specify → plan → tasks → implement)
```

### 4-4. changelog 자동 기록

`docs/changelog/YYYY-MM-DD-chore-harness-adaptation.md` 생성:
- 감지된 스택·도메인 + 정규화된 `[STACK]` 키
- 수정된 파일 목록 및 요약
- 활성화한 L2 agent 목록 (기본 reviewer 팬아웃 라우팅에 포함)
- 추가된 신규 agent (3-2-B 항목, 있으면)
- orchestrator `[STACK]` 매핑 표 보강 여부

---

## 에러 핸들링

원칙: 1회 재시도 → 재실패 시 누락 명시 + 사용자 에스컬레이션 (`docs/rules/07-error-recovery.md`)

| 상황 | 조치 |
|------|------|
| 매니페스트 0개 감지 | 사용자에게 직접 입력 요청 (`question` 옵션: Python/Node/Go/Rust/...) |
| 매니페스트 다수 (모노레포) | 사용자에게 디렉토리별 매핑 확인 |
| 도메인 추정 불명확 (단서 모호) | 사용자에게 도메인 분류 `question` 제시 |
| Phase 3 파일 수정 중 오류 | 해당 파일만 롤백(git revert 권장), 다음 파일 진행, 보고서에 명시 |
| 1회 재시도 후 재실패 | 누락 명시 + 사용자에게 수동 수정 가이드 제공 |

---

## 출력 스타일 (caveman 경계)

caveman lite 적용 **제외** (사용자 보고 중심 스킬):
- Phase별 진행 상황 보고
- 분석 결과 요약
- 수정 계획 diff
- `question` 옵션
- 최종 완료 보고

내부 도구 호출 (Glob / Read / Edit) 은 정상 처리.

---

## 테스트 시나리오

**정상 흐름 (Python FastAPI 백엔드)**:
"이 프로젝트에 하네스 적용해줘"
→ Phase 0: 하네스 파일 존재 확인 ✓
→ Phase 1: `pyproject.toml` 감지 → Python 3.11 + FastAPI + pytest + ruff 식별
→ Phase 2: 백엔드 API 도메인 → 사용자 확인 ✓
→ Phase 3: `01-project-structure.md` / `CLAUDE.md` 수정 계획 → 사용자 확인 → 일괄 적용
→ Phase 4: constitution 작성 권유 + changelog 기록 → 완료

**모노레포 흐름 (Next.js + Go)**:
"하네스 적응시켜줘"
→ Phase 1: `package.json` + `go.mod` 동시 감지
→ Phase 2: 사용자 확인 ("Frontend Next.js + Backend Go 풀스택이 맞나요?")
→ Phase 3: 디렉토리별 스택 매핑하여 `01-project-structure.md` 작성 (`apps/web/` Next.js, `apps/api/` Go)

**ML 프로젝트 흐름**:
→ Phase 1: torch + transformers + datasets 감지 → `[STACK]=python` + ML 도메인 플래그
→ Phase 2: ML 도메인 추정 → 사용자 확인 ✓
→ Phase 3:
   - 3-2-A (표준 L2 활성화): `python-reviewer`, `code-reviewer` (security-reviewer 는 키워드 게이트 적용)
   - 3-2-B (신규 생성): `data-validator`, `model-evaluator` agent 추가 권장 → 사용자 승인 → `.claude/agents/`에 생성
   - orchestrator Phase 3-2 라우팅 표 + Phase 0.5 [STACK] 표에 ML 분기 보강

**보안 중점 도메인 (금융)**:
→ Phase 1: Java + Spring Boot 감지 → `[STACK]=java-spring`
→ Phase 2: "금융 백엔드 API + 규제 준수 필요" → 사용자 확인 ✓
→ Phase 3-2-A: `java-reviewer` + ECC `springboot-security` 활성. **`security-reviewer` 는 키워드 게이트 무시하고 항상 활성** (도메인 신호 기록)
→ Phase 4-4: changelog 에 "security-reviewer always-on" 명시

**에러 흐름 (매니페스트 0개)**:
→ Phase 1: 어떤 매니페스트도 감지 안 됨
→ `question`으로 "프로젝트 언어/프레임워크를 알려주세요" 옵션 제시
→ 사용자 입력 받아 Phase 2부터 정상 진행
