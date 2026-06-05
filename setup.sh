#!/usr/bin/env bash
# setup.sh — 하네스를 새 프로젝트에 적용 (Mac/Linux)
#
# 사용법:
#   ./setup.sh /path/to/project
#   ./setup.sh ../my-project --dry-run
#   ./setup.sh ../my-project --opencode
#     ↳ opencode 자동 변환:
#       - .claude/agents   -> .opencode/agents   (복수 유지 + frontmatter: name 보존, color 제거, mode: subagent, model→KTDS Qwen, tools 배열 라인 제거)
#       - .claude/skills   -> .opencode/skills   (그대로 유지; SKILL.md 보존)
#       - .claude/commands -> .opencode/commands (복수 유지)
#       - .claude/rules    -> .opencode/rules    (복수 유지)
#       - .claude/settings.json -> .opencode/settings.json
#       - 본문 내 .claude 경로 참조는 prefix 만 .opencode 로 치환 (디렉터리명 보존)
#       - Agent(...) -> opencode `task` tool 호출 텍스트 자동 변환
#       - AskUserQuestion -> STOP(텍스트 응답 대기) 자동 변환
#       - opencode 공식 표준 + devai fork 모두 복수형 디렉터리 (agents, skills, commands, rules, plugins) 사용

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=""
DRY_RUN=false
OPENCODE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run)  DRY_RUN=true ;;
        --opencode) OPENCODE=true ;;
        *)          TARGET_DIR="$arg" ;;
    esac
done

if [[ -z "$TARGET_DIR" ]]; then
    echo "사용법: ./setup.sh <target-dir> [--dry-run] [--opencode]"
    exit 1
fi

# realpath -m 호환성 fallback (macOS 기본 환경엔 coreutils 미설치)
abs_path() {
    local p="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath -m "$p" 2>/dev/null || realpath "$p"
    elif command -v greadlink >/dev/null 2>&1; then
        greadlink -m "$p"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import os, sys; print(os.path.abspath(sys.argv[1]))" "$p"
    else
        # 마지막 fallback: 입력 그대로 (상대경로 가능)
        echo "$p"
    fi
}

TARGET_DIR="$(abs_path "$TARGET_DIR")"

# opencode 모드: 경로 매핑 (단수형 + 의미 변환).
path_for_opencode() {
    local p="$1"
    if ! $OPENCODE; then
        echo "$p"
        return
    fi

    # opencode 공식 표준: 모든 디렉터리 복수형 유지 (agents, skills, commands, rules, plugins).
    # 단수형은 backward compat 일 뿐이며 devai fork 는 복수형만 안정적으로 인식.
    # 따라서 디렉터리명은 .claude 그대로 두고 prefix 만 .opencode 로 변경.
    p="${p//.claude\//.opencode/}"
    p="${p//.claude/.opencode}"
    echo "$p"
}

# GNU/BSD sed 모두 호환 + 우선순위 매핑 in-place 치환.
sed_inplace_opencode() {
    local file="$1"
    # GNU/BSD 분기를 위한 헬퍼 — sed -i 인자 방식 차이
    local is_gnu=false
    sed --version >/dev/null 2>&1 && is_gnu=true

    _se() {
        local script="$1"
        if $is_gnu; then
            sed -i -E "$script" "$file"
        else
            sed -i '' -E "$script" "$file"
        fi
    }

    # 디렉터리명은 .claude 그대로 두고 prefix 만 .opencode 로 변경 (복수형 유지).
    _se 's#\.claude([\\/])#.opencode\1#g'
    _se 's#\.claude#.opencode#g'
}

# opencode 모드일 때만, 텍스트 파일 내용의 `.claude` 참조를 매핑 적용.
rewrite_content_for_opencode() {
    local path="$1"
    $OPENCODE || return 0
    [[ -e "$path" ]] || return 0

    local f
    if [[ -d "$path" ]]; then
        while IFS= read -r -d '' f; do
            _rewrite_one "$f"
        done < <(find "$path" -type f -print0)
    else
        _rewrite_one "$path"
    fi
}

_rewrite_one() {
    local f="$1"
    case "$f" in
        *.md|*.json|*.ps1|*.sh|*.toml|*.yaml|*.yml|*.txt)
            if grep -q '\.claude' "$f" 2>/dev/null; then
                sed_inplace_opencode "$f"
            fi
            # Agent(...) -> opencode task tool 텍스트, AskUserQuestion -> STOP 텍스트
            # 멀티라인 캡처 필요 — sed 한계로 perl 사용 (macOS/Linux 표준 설치)
            if command -v perl >/dev/null 2>&1; then
                if grep -E -q 'Agent\(|AskUserQuestion' "$f" 2>/dev/null; then
                    rewrite_agent_calls_opencode "$f"
                fi
            fi
            ;;
    esac
}

# Agent(...) -> opencode/devai `task(...)` 호출로 변환.
# devai task 시그니처: task(subagent_type="<name>", load_skills=[...], description="...", prompt="...")
#   - subagent_type: prompt 안의 .../agents/<name>.md 에서 실제 agent 이름 추출
#   - load_skills: agent 별 기본 skill 자동 주입 (planner/implementer 만 정적 매핑)
# AskUserQuestion -> opencode 등가 도구 없음. STOP+텍스트 fallback.
rewrite_agent_calls_opencode() {
    local file="$1"
    perl -i -0777 -pe '
        sub skills_for {
            my $n = shift;
            return q{"speckit-specify", "speckit-plan", "speckit-tasks"} if $n eq "planner";
            return q{"speckit-implement"} if $n eq "implementer";
            return q{};
        }
        sub to_task {
            my ($d, $p) = @_;
            my $n = ($p =~ m{agents/([\w-]+)\.md}) ? $1 : "general-purpose";
            my $s = skills_for($n);
            return qq{task(\n  subagent_type="$n",\n  load_skills=[$s],\n  description="$d",\n  prompt="$p")};
        }
        s{
            Agent\(
            \s* subagent_type="[^"]*",
            \s* description="([^"]+)",
            \s* prompt="""([\s\S]+?)"""
            \s* \)
        }{to_task($1, $2)}gex;
        s{
            Agent\(
            \s* subagent_type="[^"]*",
            \s* description="([^"]+)",
            \s* prompt="([^"]+)"
            \s* \)
        }{to_task($1, $2)}gex;
        s{`AskUserQuestion`}{STOP(텍스트로 사용자에게 옵션 제시 후 응답 대기)}g;
        s{AskUserQuestion}{STOP(텍스트로 사용자에게 옵션 제시 후 응답 대기)}g;
    ' "$file"
}

# Agent 파일명 -> KTDS 모델 (bash 3.2 호환: 연관배열 대신 case)
#   메인 [KTDS] Qwen3.6-27B-FP8     : dense 27B, 깊은 추론 (설계·보안·전략·L1 워크플로)
#   서브 [KTDS] Qwen3.6-35B-A3B-FP8 : MoE active 3B, 경량·빠름 (패턴 리뷰·루프·문서)
# 값에 따옴표 포함 — 선행 "[" 가 YAML flow sequence 로 오인되지 않도록.
ktds_model_for() {
    case "$1" in
        code-reviewer|python-reviewer|java-reviewer|typescript-reviewer|fastapi-reviewer|loop-operator|doc-updater)
            echo '"ABCLab/[KTDS] Qwen3.6-35B-A3B-FP8"' ;;
        *)
            echo '"ABCLab/[KTDS] Qwen3.6-27B-FP8"' ;;
    esac
}

# Agent .md frontmatter 정리 (opencode/devai 양식):
#   - name: 보장 (devai fork 필수 필드 — 원본 유지, 없으면 파일명으로 frontmatter 최상단 삽입)
#   - color: 라인 제거 (opencode agent frontmatter 에 color 필드 없음)
#   - mode: subagent 추가 (없으면) — description 다음 줄
#   - tools: [..] 배열 라인 제거 (opencode 는 tools 를 record/list 로 기대 — 미지정 시 기본 도구 상속)
#   - model: KTDS 모델로 매핑/삽입 (claude 모델 미지원)
convert_agent_frontmatter() {
    local agent_dir="$1"
    $OPENCODE || return 0
    [[ -d "$agent_dir" ]] || return 0

    local is_gnu=false
    sed --version >/dev/null 2>&1 && is_gnu=true

    _sed_i() {
        local script="$1"
        local file="$2"
        if $is_gnu; then
            sed -i -E "$script" "$file"
        else
            sed -i '' -E "$script" "$file"
        fi
    }

    local f base model
    while IFS= read -r -d '' f; do
        base="$(basename "$f" .md)"
        model="$(ktds_model_for "$base")"

        # name: 보장 (devai fork 필수 필드). 원본 name 유지, 없으면 파일명으로
        # frontmatter 최상단(첫 --- 다음)에 삽입.
        if ! grep -qE '^name:[[:space:]]*[^[:space:]]' "$f"; then
            awk -v nm="$base" 'NR==1 && /^---$/{print; print "name: " nm; next} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        fi
        # color: 라인 제거 (opencode agent frontmatter 에 color 필드 없음)
        _sed_i '/^color:[[:space:]]/d' "$f"
        # tools: [..] 배열 라인 제거
        _sed_i '/^tools:[[:space:]]*\[.*\]/d' "$f"
        # mode: 이미 있으면 skip, 없으면 description 다음에 추가
        if ! grep -qE '^mode:[[:space:]]*[^[:space:]]' "$f"; then
            _sed_i '/^description:/a\
mode: subagent' "$f"
        fi
        # model: 있으면 치환, 없으면 mode: subagent 다음에 삽입
        if grep -qE '^model:[[:space:]]*[^[:space:]]' "$f"; then
            _sed_i "s|^model:.*|model: ${model}|" "$f"
        else
            _sed_i "/^mode:[[:space:]]*subagent/a\\
model: ${model}" "$f"
        fi
    done < <(find "$agent_dir" -type f -name "*.md" -print0)
}

copy_dir() {
    local rel_path="$1"
    local description="$2"
    local src="$SOURCE_DIR/$rel_path"
    local dest_rel
    dest_rel="$(path_for_opencode "$rel_path")"
    local dest="$TARGET_DIR/$dest_rel"

    if [[ ! -d "$src" ]]; then
        echo "  ⚠️  소스 없음: $rel_path — 스킵"
        return
    fi

    if $DRY_RUN; then
        echo "  [DRY RUN] $rel_path -> $dest_rel"
        return
    fi

    mkdir -p "$dest"
    cp -r "$src/." "$dest/"
    rewrite_content_for_opencode "$dest"
    echo "  ✓ $description ($dest_rel)"
}

copy_file() {
    local rel_path="$1"
    local src="$SOURCE_DIR/$rel_path"
    local dest_rel
    dest_rel="$(path_for_opencode "$rel_path")"
    local dest="$TARGET_DIR/$dest_rel"

    if [[ ! -f "$src" ]]; then return; fi

    if $DRY_RUN; then
        echo "  [DRY RUN] $dest_rel"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    if [[ ! -f "$dest" ]]; then
        cp "$src" "$dest"
        rewrite_content_for_opencode "$dest"
        echo "  ✓ $dest_rel"
    else
        echo "  ⚠️  이미 존재 — 스킵: $dest_rel"
    fi
}

# ─── 시작 ──────────────────────────────────────────────
echo ""
echo "하네스 세팅"
echo "  소스: $SOURCE_DIR"
echo "  대상: $TARGET_DIR"
$DRY_RUN  && echo "  모드: DRY RUN"
if $OPENCODE; then
    echo "  모드: OPENCODE"
    echo "    .claude/agents   -> .opencode/agents   (복수 유지 + frontmatter: mode: subagent, model→KTDS Qwen, tools 제거)"
    echo "    .claude/skills   -> .opencode/skills   (그대로 유지; SKILL.md 보존)"
    echo "    .claude/commands -> .opencode/commands (복수 유지)"
    echo "    .claude/rules    -> .opencode/rules    (복수 유지)"
    echo "    .claude/settings.json -> .opencode/settings.json"
fi
echo ""

mkdir -p "$TARGET_DIR"

echo "복사 중..."

copy_dir  ".claude/agents"              "에이전트 정의 (L1 4 + L2 11)"
copy_dir  ".claude/skills"              "스킬 (caveman·speckit·harness·ecc·superpowers)"
copy_dir  ".claude/commands"            "슬래시 커맨드 (10개)"
copy_dir  ".claude/rules"               "ECC 부속 규칙"

# opencode 후처리 (디렉토리 복사 직후, settings.json 복사 전)
if $OPENCODE && ! $DRY_RUN; then
    convert_agent_frontmatter "$TARGET_DIR/.opencode/agents"
    # devai 의 task() subagent resolution 은 .claude/agents/ 를 읽는다
    # (devai.js: mergeWithClaudeCodeAgents -> loadProjectAgents).
    # 등록·@멘션(/agents 목록)은 .opencode/agents/ 를 읽는다.
    # 두 경로 모두 필요하므로 변환 완료된 agent 를 .claude/agents/ 에도 사본 배치.
    rm -rf "$TARGET_DIR/.claude/agents"
    mkdir -p "$TARGET_DIR/.claude/agents"
    cp -r "$TARGET_DIR/.opencode/agents/." "$TARGET_DIR/.claude/agents/"
    echo "  ✓ Opencode 후처리 (agent frontmatter + .claude/agents task-resolution 사본)"
fi

copy_file ".claude/settings.json"
copy_dir  "docs/rules"                  "규칙 파일"
copy_dir  ".specify/templates"          ".specify 템플릿"
copy_dir  ".specify/scripts"            ".specify 스크립트"
copy_dir  ".specify/integrations"       ".specify 통합"
copy_file ".specify/init-options.json"
copy_file ".specify/integration.json"
copy_file ".specify/memory/constitution.md"
copy_file "CLAUDE.md"

echo ""
echo "완료."
echo ""
echo "다음 단계:"
echo "  1. CLAUDE.md                          — 프로젝트명 및 기술 스택 업데이트"
echo "  2. .specify/memory/constitution.md    — 프로젝트 핵심 원칙 작성"
echo "  3. docs/rules/01-project-structure.md — 실제 기술 스택 확정"
echo "  4. (선택) docs/rules/03-ai-agent-guidelines.md — 프로젝트별 스킬 목록 정리"
if $OPENCODE; then
    echo ""
    echo "  Opencode 모드 — 자동 변환 완료 + 추가 수동 검토 필요:"
    echo "    [auto] Agent(subagent_type=..., description=X, prompt=Y) -> 'task' tool 호출 텍스트로 자동 변환"
    echo "    [auto] AskUserQuestion -> STOP(텍스트 응답 대기) 로 자동 변환"
    echo "    [auto] .claude/{agents,skills,commands,rules} -> .opencode/{agents,skills,commands,rules} (복수 유지) 경로 자동 변환"
    echo ""
    echo "    a) /Skill(...) 같은 그 외 Claude Code 전용 도구 호출이 있으면 사내 fork 등가 표기로 수동 치환 필요"
    echo "    b) .opencode/settings.json 의 훅 키 (UserPromptSubmit 등) — opencode 는 plugin (.opencode/plugin/*.ts) 사용. settings.json hook 은 무력화됨"
    echo "    c) primary agent 지정: 기본은 모두 subagent. 한 agent의 frontmatter 를 mode: primary 로 변경"
    echo "    d) .opencode/skills/<skill>/ 의 nested 구조 (SKILL.md 보존) + 보조 파일 (scripts/) — 사내 fork 지원 여부 확인"
    echo "    e) .opencode/rules/ 는 .claude/rules/ 의 ECC 부속 규칙 보존용. opencode 표준은 AGENTS.md 단일 파일 권장 — 필요 시 변환"
    echo "    f) agent 'model:' 이 KTDS Qwen 으로 매핑됨 ([KTDS] Qwen3.6-27B-FP8 메인 / -35B-A3B-FP8 서브) — opencode provider 가 기대하는 model id 형식 확인"
fi
echo ""
