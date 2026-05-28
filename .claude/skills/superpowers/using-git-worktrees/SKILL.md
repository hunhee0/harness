---
name: using-git-worktrees
description: 현재 워크스페이스에서 격리 필요한 기능 작업 시작 시·구현 계획 실행 전 사용 — 네이티브 도구 또는 git worktree fallback으로 격리 워크스페이스 존재 보장 (Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback)
---

# Git Worktree 사용

## 개요

작업이 격리 워크스페이스에서 발생 보장. 플랫폼의 네이티브 worktree 도구 선호. 네이티브 도구 없을 때만 수동 git worktree fallback.

**핵심 원칙:** 먼저 기존 격리 감지. 그 다음 네이티브 도구. 그 다음 git fallback. 절대 하네스와 싸우지 마라.

**시작 시 announce:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: 기존 격리 감지

**무엇이든 만들기 전 이미 격리 워크스페이스에 있는지 체크.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule 가드:** `GIT_DIR != GIT_COMMON`은 git submodule 내부에서도 참. "이미 worktree에 있음" 결론 전 submodule 아님 검증:

```bash
# 경로 반환 시 worktree 아닌 submodule — 정상 repo로 처리
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**`GIT_DIR != GIT_COMMON` (submodule X):** 이미 linked worktree에 있음. Step 3 (프로젝트 setup)로 건너뜀. 다른 worktree 생성 X.

브랜치 상태와 함께 보고:
- 브랜치 위: "Already in isolated workspace at `<path>` on branch `<name>`."
- detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**`GIT_DIR == GIT_COMMON` (또는 submodule 내부):** 정상 repo checkout에 있음.

사용자가 worktree 선호를 지시에 이미 표시? 없으면 worktree 생성 전 동의 요청:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

기존 선언된 선호 없이 따름. 사용자 동의 거부 시 in-place 작업·Step 3으로 건너뜀.

## Step 1: 격리 워크스페이스 생성

**메커니즘 2개. 이 순서로 시도.**

### 1a. 네이티브 Worktree 도구 (선호)

사용자가 격리 워크스페이스 요청 (Step 0 동의). 이미 worktree 생성 방법 보유? `EnterWorktree`·`WorktreeCreate`·`/worktree` 명령·`--worktree` 플래그 같은 이름의 도구 가능. 있으면 사용·Step 3로 건너뜀.

네이티브 도구가 디렉터리 배치·브랜치 생성·정리 자동 처리. 네이티브 도구 있을 때 `git worktree add` 사용은 하네스가 보거나 관리 못 하는 phantom 상태 생성.

네이티브 worktree 도구 없을 때만 Step 1b 진행.

### 1b. Git Worktree Fallback

**Step 1a 적용 안 될 때만 사용** — 네이티브 worktree 도구 없음. git으로 수동 worktree 생성.

#### 디렉터리 선택

이 우선순위 순서 따름. 명시적 사용자 선호가 항상 관찰된 파일시스템 상태 이김.

1. **지시에서 선언된 worktree 디렉터리 선호 체크.** 사용자가 이미 지정했으면 질문 없이 사용.

2. **기존 프로젝트 로컬 worktree 디렉터리 체크:**
   ```bash
   ls -d .worktrees 2>/dev/null     # 선호 (숨김)
   ls -d worktrees 2>/dev/null      # 대안
   ```
   발견 시 사용. 둘 다 존재 시 `.worktrees` 승리.

3. **기존 글로벌 디렉터리 체크:**
   ```bash
   project=$(basename "$(git rev-parse --show-toplevel)")
   ls -d ~/.config/superpowers/worktrees/$project 2>/dev/null
   ```
   발견 시 사용 (레거시 글로벌 경로와 하위 호환).

4. **다른 가이던스 없으면**, 프로젝트 루트의 `.worktrees/` 기본.

#### 안전 검증 (프로젝트 로컬 디렉터리만)

**worktree 생성 전 디렉터리 ignored 검증 필수:**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**NOT ignored:** .gitignore에 추가·변경 커밋·진행.

**왜 중요:** worktree 내용 저장소 우연 커밋 방지.

글로벌 디렉터리 (`~/.config/superpowers/worktrees/`)는 검증 불필요.

#### Worktree 생성

```bash
project=$(basename "$(git rev-parse --show-toplevel)")

# 선택 위치 기반 경로 결정
# 프로젝트 로컬: path="$LOCATION/$BRANCH_NAME"
# 글로벌: path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** `git worktree add`가 권한 에러 (sandbox denial) 실패 시 사용자에게 sandbox가 worktree 생성 차단·현재 디렉터리에서 작업 알림. 그 다음 in place setup·baseline 테스트 실행.

## Step 3: 프로젝트 Setup

자동 감지·적절한 setup 실행:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 4: 깨끗한 베이스라인 검증

워크스페이스 깨끗 시작 보장 위해 테스트 실행:

```bash
# 프로젝트 적절한 명령 사용
npm test / cargo test / pytest / go test ./...
```

**테스트 실패:** 실패 보고·진행 또는 조사 질문.

**테스트 통과:** 준비 보고.

### 보고

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## 빠른 레퍼런스

| Situation | Action |
|-----------|--------|
| 이미 linked worktree | 생성 건너뜀 (Step 0) |
| submodule 내부 | 정상 repo로 처리 (Step 0 가드) |
| 네이티브 worktree 도구 | 사용 (Step 1a) |
| 네이티브 도구 없음 | git worktree fallback (Step 1b) |
| `.worktrees/` 존재 | 사용 (ignored 검증) |
| `worktrees/` 존재 | 사용 (ignored 검증) |
| 둘 다 존재 | `.worktrees/` 사용 |
| 둘 다 없음 | 지시 파일 체크·기본 `.worktrees/` |
| 글로벌 경로 존재 | 사용 (하위 호환) |
| 디렉터리 ignored 안 됨 | .gitignore 추가·커밋 |
| 생성 시 권한 에러 | Sandbox fallback·in place 작업 |
| 베이스라인 동안 테스트 실패 | 실패 보고·질문 |
| package.json/Cargo.toml 없음 | 의존성 설치 건너뜀 |

## 일반 실수

### 하네스와 싸움

- **문제:** 플랫폼이 이미 격리 제공할 때 `git worktree add` 사용
- **수정:** Step 0가 기존 격리 감지. Step 1a가 네이티브 도구 위임.

### 감지 건너뜀

- **문제:** 기존 worktree 내부에 중첩 worktree 생성
- **수정:** 무엇이든 생성 전 항상 Step 0 실행

### ignore 검증 건너뜀

- **문제:** worktree 내용이 추적됨·git status 오염
- **수정:** 프로젝트 로컬 worktree 생성 전 항상 `git check-ignore` 사용

### 디렉터리 위치 가정

- **문제:** 불일치 생성·프로젝트 관례 위반
- **수정:** 우선순위 따름: 기존 > 글로벌 레거시 > 지시 파일 > 기본

### 실패 테스트로 진행

- **문제:** 새 버그와 기존 이슈 구별 불가
- **수정:** 실패 보고·진행 명시 허가 획득

## 적신호

**절대 X:**
- Step 0가 기존 격리 감지 시 worktree 생성
- 네이티브 worktree 도구 (예: `EnterWorktree`) 있을 때 `git worktree add` 사용. #1 실수 — 있으면 사용.
- Step 1a 건너뛰고 Step 1b의 git 명령으로 직진
- ignored 검증 없이 worktree 생성 (프로젝트 로컬)
- 베이스라인 테스트 검증 건너뜀
- 실패 테스트로 질문 없이 진행

**항상:**
- 먼저 Step 0 감지 실행
- git fallback보다 네이티브 도구 선호
- 디렉터리 우선순위 따름: 기존 > 글로벌 레거시 > 지시 파일 > 기본
- 프로젝트 로컬에 디렉터리 ignored 검증
- 프로젝트 setup 자동 감지·실행
- 깨끗한 테스트 베이스라인 검증
