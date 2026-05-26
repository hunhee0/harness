# setup.ps1 — 하네스를 새 프로젝트에 적용
#
# 사용법:
#   .\setup.ps1 -TargetDir "C:\path\to\project"
#   .\setup.ps1 -TargetDir "../my-project" -DryRun

param(
    [Parameter(Mandatory=$true, HelpMessage="하네스를 적용할 프로젝트 디렉토리")]
    [string]$TargetDir,

    [switch]$DryRun
)

$SourceDir = $PSScriptRoot
$TargetDir = (Resolve-Path -Path $TargetDir -ErrorAction SilentlyContinue)?.Path ?? $TargetDir

function Write-Step {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Cyan
}

function Copy-HarnessDir {
    param([string]$RelPath, [string]$Description)
    $source = Join-Path $SourceDir $RelPath
    $dest   = Join-Path $TargetDir $RelPath

    if (-not (Test-Path $source)) {
        Write-Host "  ⚠️ 소스 없음: $RelPath — 스킵" -ForegroundColor Yellow
        return
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] $RelPath" -ForegroundColor Gray
        return
    }

    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -Path "$source\*" -Destination $dest -Recurse -Force
    Write-Host "  ✓ $Description ($RelPath)" -ForegroundColor Green
}

# ─── 시작 ──────────────────────────────────────────────
Write-Host ""
Write-Host "하네스 세팅" -ForegroundColor White
Write-Host "  소스: $SourceDir"
Write-Host "  대상: $TargetDir"
if ($DryRun) { Write-Host "  모드: DRY RUN (실제 복사 안 함)" -ForegroundColor Yellow }
Write-Host ""

# 대상 디렉토리 생성
if (-not $DryRun -and -not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
}

# ─── 복사 ──────────────────────────────────────────────
Write-Host "복사 중..." -ForegroundColor White

# 에이전트 정의
Copy-HarnessDir ".claude\agents"  "에이전트 정의"

# 스킬
Copy-HarnessDir ".claude\skills"  "스킬"

# settings.json (훅 포함)
$settingsSrc  = Join-Path $SourceDir ".claude\settings.json"
$settingsDest = Join-Path $TargetDir ".claude\settings.json"
if (Test-Path $settingsSrc) {
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path (Split-Path $settingsDest) | Out-Null
        Copy-Item $settingsSrc $settingsDest -Force
        Write-Host "  ✓ Claude 설정 (.claude/settings.json)" -ForegroundColor Green
    } else {
        Write-Host "  [DRY RUN] .claude/settings.json" -ForegroundColor Gray
    }
}

# docs/rules
Copy-HarnessDir "docs\rules"      "규칙 파일"

# .specify (templates, scripts — memory는 프로젝트별 작성)
Copy-HarnessDir ".specify\templates"                ".specify 템플릿"
Copy-HarnessDir ".specify\scripts"                  ".specify 스크립트"
Copy-HarnessDir ".specify\integrations"             ".specify 통합"

# .specify 설정 파일
foreach ($file in @("init-options.json", "integration.json")) {
    $src  = Join-Path $SourceDir ".specify\$file"
    $dest = Join-Path $TargetDir ".specify\$file"
    if (Test-Path $src) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
            Copy-Item $src $dest -Force
        }
        Write-Host "  ✓ .specify/$file" -ForegroundColor Green
    }
}

# constitution.md 템플릿 (비어있는 버전)
$constSrc  = Join-Path $SourceDir ".specify\memory\constitution.md"
$constDest = Join-Path $TargetDir ".specify\memory\constitution.md"
if (Test-Path $constSrc) {
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path (Split-Path $constDest) | Out-Null
        if (-not (Test-Path $constDest)) {
            Copy-Item $constSrc $constDest
            Write-Host "  ✓ .specify/memory/constitution.md (템플릿)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ constitution.md 이미 존재 — 스킵" -ForegroundColor Yellow
        }
    }
}

# CLAUDE.md
$claudeSrc  = Join-Path $SourceDir "CLAUDE.md"
$claudeDest = Join-Path $TargetDir "CLAUDE.md"
if (-not $DryRun) {
    if (-not (Test-Path $claudeDest)) {
        Copy-Item $claudeSrc $claudeDest
        Write-Host "  ✓ CLAUDE.md" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ CLAUDE.md 이미 존재 — 스킵 (수동 병합 필요)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [DRY RUN] CLAUDE.md" -ForegroundColor Gray
}

# ─── 완료 안내 ──────────────────────────────────────────
Write-Host ""
Write-Host "완료." -ForegroundColor Green
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor White
Write-Host "  1. CLAUDE.md  — 프로젝트명 및 기술 스택 업데이트"
Write-Host "  2. .specify\memory\constitution.md  — 프로젝트 핵심 원칙 작성"
Write-Host "  3. docs\rules\01-project-structure.md  — 실제 기술 스택 확정"
Write-Host "  4. (선택) docs\rules\03-ai-agent-guidelines.md  — 프로젝트별 스킬 목록 정리"
Write-Host ""
