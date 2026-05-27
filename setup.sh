#!/usr/bin/env bash
# setup.sh — 하네스를 새 프로젝트에 적용 (Mac/Linux)
#
# 사용법:
#   ./setup.sh /path/to/project
#   ./setup.sh ../my-project --dry-run
#   ./setup.sh ../my-project --opencode   # .claude -> .opencode 이름·내용 치환

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

# opencode 모드: 경로의 `.claude` 부분을 `.opencode`로 변환.
path_for_opencode() {
    local p="$1"
    if $OPENCODE; then
        echo "${p//.claude/.opencode}"
    else
        echo "$p"
    fi
}

# GNU/BSD sed 모두 호환되는 in-place 치환.
sed_inplace() {
    local file="$1"
    if sed --version >/dev/null 2>&1; then
        sed -i 's/\.claude/.opencode/g' "$file"
    else
        sed -i '' 's/\.claude/.opencode/g' "$file"
    fi
}

# opencode 모드일 때만, 텍스트 파일 내용의 `.claude`를 `.opencode`로 치환.
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
                sed_inplace "$f"
            fi
            ;;
    esac
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
$OPENCODE && echo "  모드: OPENCODE (.claude -> .opencode 이름·내용 치환)"
echo ""

mkdir -p "$TARGET_DIR"

echo "복사 중..."

copy_dir  ".claude/agents"              "에이전트 정의"
copy_dir  ".claude/skills"              "스킬"
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
    echo "  Opencode 모드: 하네스가 '.claude/' 대신 '.opencode/'에 복사됐습니다."
    echo "  복사된 파일을 점검하고 남은 툴/에이전트 변환은 수동으로 마무리하세요."
fi
echo ""
