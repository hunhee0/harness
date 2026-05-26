#!/usr/bin/env bash
# setup.sh — 하네스를 새 프로젝트에 적용 (Mac/Linux)
#
# 사용법:
#   ./setup.sh /path/to/project
#   ./setup.sh ../my-project --dry-run

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=""
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *) TARGET_DIR="$arg" ;;
    esac
done

if [[ -z "$TARGET_DIR" ]]; then
    echo "사용법: ./setup.sh <target-dir> [--dry-run]"
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

copy_dir() {
    local rel_path="$1"
    local description="$2"
    local src="$SOURCE_DIR/$rel_path"
    local dest="$TARGET_DIR/$rel_path"

    if [[ ! -d "$src" ]]; then
        echo "  ⚠️  소스 없음: $rel_path — 스킵"
        return
    fi

    if $DRY_RUN; then
        echo "  [DRY RUN] $rel_path"
        return
    fi

    mkdir -p "$dest"
    cp -r "$src/." "$dest/"
    echo "  ✓ $description ($rel_path)"
}

copy_file() {
    local rel_path="$1"
    local src="$SOURCE_DIR/$rel_path"
    local dest="$TARGET_DIR/$rel_path"

    if [[ ! -f "$src" ]]; then return; fi

    if $DRY_RUN; then
        echo "  [DRY RUN] $rel_path"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    if [[ ! -f "$dest" ]]; then
        cp "$src" "$dest"
        echo "  ✓ $rel_path"
    else
        echo "  ⚠️  이미 존재 — 스킵: $rel_path"
    fi
}

# ─── 시작 ──────────────────────────────────────────────
echo ""
echo "하네스 세팅"
echo "  소스: $SOURCE_DIR"
echo "  대상: $TARGET_DIR"
$DRY_RUN && echo "  모드: DRY RUN"
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
echo ""
