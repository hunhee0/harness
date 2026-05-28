#!/usr/bin/env bash
# setup.sh — 하네스를 새 프로젝트에 적용 (Mac/Linux)
#
# 사용법:
#   ./setup.sh /path/to/project
#   ./setup.sh ../my-project --dry-run
#   ./setup.sh ../my-project --opencode
#     ↳ opencode 자동 변환:
#       - .claude/agents   -> .opencode/agent     (단수 + frontmatter cleanup: name 제거, mode: subagent 추가)
#       - .claude/skills   -> .opencode/command   (의미 변환; SKILL.md -> <skill-name>.md)
#       - .claude/commands -> .opencode/command   (병합)
#       - .claude/rules    -> .opencode/rule      (단수)
#       - .claude/settings.json -> ./opencode.json (프로젝트 루트; _note 키 추가 — hook schema 수동 검토 필요)
#       - 본문 내 .claude 경로 참조는 동일 매핑으로 치환됨
#       - Skill/Agent 호출 표기는 자동 변환 불가 — 수동 검토 필요

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

    # 우선순위 매핑 (긴 패턴 먼저)
    # settings.json -> opencode.json (루트)
    if [[ "$p" == ".claude/settings.json" ]]; then echo "opencode.json"; return; fi

    # 단수형/의미 변환
    p="${p//.claude\/agents/.opencode/agent}"
    p="${p//.claude\/skills/.opencode/command}"
    p="${p//.claude\/commands/.opencode/command}"
    p="${p//.claude\/rules/.opencode/rule}"
    # fallback
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

    # 우선순위 매핑 (확장 정규식 -E)
    _se 's#\.claude([\\/])agents#.opencode\1agent#g'
    _se 's#\.claude([\\/])skills#.opencode\1command#g'
    _se 's#\.claude([\\/])commands#.opencode\1command#g'
    _se 's#\.claude([\\/])rules#.opencode\1rule#g'
    # fallback
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
            ;;
    esac
}

# Agent .md frontmatter 정리 (opencode 양식):
#   - name: 라인 제거 (파일명이 식별자 역할)
#   - mode: subagent 추가 (없으면) — description 다음 줄
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

    local f
    while IFS= read -r -d '' f; do
        # name: 라인 제거 (frontmatter 영역 가정)
        _sed_i '/^name:[[:space:]]/d' "$f"
        # mode: 이미 있으면 skip, 없으면 description 다음에 추가
        if ! grep -qE '^mode:[[:space:]]*[^[:space:]]' "$f"; then
            _sed_i '/^description:/a\
mode: subagent' "$f"
        fi
    done < <(find "$agent_dir" -type f -name "*.md" -print0)
}

# SKILL.md -> <skill-name>.md rename (opencode 는 SKILL.md 개념 없음)
rename_skill_to_command() {
    local command_dir="$1"
    $OPENCODE || return 0
    [[ -d "$command_dir" ]] || return 0

    local skill_file
    while IFS= read -r -d '' skill_file; do
        local parent_dir parent_name new_name new_path
        parent_dir="$(dirname "$skill_file")"
        parent_name="$(basename "$parent_dir")"
        # 안전한 파일명 (영문/숫자/하이픈만)
        new_name="$(echo "$parent_name" | sed 's/[^a-zA-Z0-9_-]/-/g')"
        new_path="$parent_dir/$new_name.md"
        if [[ ! -e "$new_path" ]]; then
            mv "$skill_file" "$new_path"
        fi
    done < <(find "$command_dir" -type f -name "SKILL.md" -print0)
}

# opencode.json 본문에 _note 키 삽입 (hook schema 수동 검토 안내)
inject_opencode_settings_note() {
    local file="$1"
    [[ -f "$file" ]] || return 0

    local is_gnu=false
    sed --version >/dev/null 2>&1 && is_gnu=true

    local note='"_note": "Converted from .claude/settings.json by setup.sh --opencode. Hook keys (UserPromptSubmit, PreToolUse, etc.) may need migration to opencode event names (user_prompt_submit, pre_tool_use, ...). Verify per your opencode fork docs.",'

    if $is_gnu; then
        sed -i -E "0,/\\{/{s|\\{|{\n  $note|}" "$file"
    else
        sed -i '' -E "1,/\\{/{s|\\{|{\\
  $note|;}" "$file"
    fi
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
        # settings.json → opencode.json 인 경우만 _note 주입
        if $OPENCODE && [[ "$rel_path" == ".claude/settings.json" ]]; then
            inject_opencode_settings_note "$dest"
        fi
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
    echo "    .claude/agents   -> .opencode/agent     (단수 + frontmatter cleanup)"
    echo "    .claude/skills   -> .opencode/command   (의미 변환; SKILL.md rename)"
    echo "    .claude/commands -> .opencode/command   (병합)"
    echo "    .claude/rules    -> .opencode/rule"
    echo "    .claude/settings.json -> ./opencode.json (루트, _note 추가)"
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
    convert_agent_frontmatter "$TARGET_DIR/.opencode/agent"
    rename_skill_to_command   "$TARGET_DIR/.opencode/command"
    echo "  ✓ Opencode 후처리 (agent frontmatter, SKILL.md rename)"
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
    echo "  Opencode 모드 — 추가 수동 검토 필요:"
    echo "    a) .opencode/command/*.md 본문의 'Agent(...)' / 'Skill(...)' 호출 표기"
    echo "       사내 fork의 '@agent-name' / '/command-name' 양식으로 교체"
    echo "    b) opencode.json 의 훅 키 (UserPromptSubmit 등) — opencode 이벤트명으로 마이그레이션"
    echo "    c) primary agent 지정: 기본은 모두 subagent. 한 agent의 frontmatter 를 mode: primary 로 변경"
    echo "    d) .opencode/command/<skill>/ 의 nested 구조 + 보조 파일 (scripts/) — 사내 fork 지원 여부 확인"
    echo "    e) .opencode/rule/ 디렉토리명 — 사내 fork 의 rules 디렉토리 규약 확인"
fi
echo ""
