# setup.ps1 - Apply harness to a new project
#
# Usage:
#   .\setup.ps1 -TargetDir "C:\path\to\project"
#   .\setup.ps1 -TargetDir "../my-project" -DryRun
#   .\setup.ps1 -TargetDir "../my-project" -Opencode   # rename .claude -> .opencode and rewrite contents

param(
    [Parameter(Mandatory=$true, HelpMessage="Target project directory")]
    [string]$TargetDir,

    [switch]$DryRun,
    [switch]$Opencode
)

$SourceDir = $PSScriptRoot

# PS 5.1 compatible: no ?. or ?? operators
$resolved = Resolve-Path -Path $TargetDir -ErrorAction SilentlyContinue
if ($resolved) {
    $TargetDir = $resolved.Path
}

# Extensions treated as text for in-file `.claude` -> `.opencode` rewriting.
$TextExtensions = @('.md', '.json', '.ps1', '.sh', '.toml', '.yaml', '.yml', '.txt')

function Convert-PathForOpencode {
    param([string]$Path)
    if ($Opencode) {
        return $Path -replace '\.claude', '.opencode'
    }
    return $Path
}

function Convert-ContentForOpencode {
    param([string]$DestPath)

    if (-not $Opencode -or -not (Test-Path $DestPath)) { return }

    if (Test-Path -Path $DestPath -PathType Container) {
        $files = Get-ChildItem -Path $DestPath -Recurse -File
    } else {
        $files = @(Get-Item -Path $DestPath)
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    foreach ($f in $files) {
        if ($TextExtensions -notcontains $f.Extension.ToLower()) { continue }

        $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        if ($content -match '\.claude') {
            $newContent = $content -replace '\.claude', '.opencode'
            [System.IO.File]::WriteAllText($f.FullName, $newContent, $utf8NoBom)
        }
    }
}

function Copy-HarnessDir {
    param([string]$RelPath, [string]$Description)
    $source  = Join-Path $SourceDir $RelPath
    $destRel = Convert-PathForOpencode $RelPath
    $dest    = Join-Path $TargetDir $destRel

    if (-not (Test-Path $source)) {
        Write-Host "  [SKIP] Source not found: $RelPath" -ForegroundColor Yellow
        return
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] $RelPath -> $destRel" -ForegroundColor Gray
        return
    }

    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -Path "$source\*" -Destination $dest -Recurse -Force
    Convert-ContentForOpencode $dest
    Write-Host "  [OK] $Description ($destRel)" -ForegroundColor Green
}

# --- Start ---
Write-Host ""
Write-Host "Harness Setup" -ForegroundColor White
Write-Host "  Source: $SourceDir"
Write-Host "  Target: $TargetDir"
if ($DryRun)   { Write-Host "  Mode: DRY RUN (no actual copy)" -ForegroundColor Yellow }
if ($Opencode) { Write-Host "  Mode: OPENCODE (.claude -> .opencode rename + content rewrite)" -ForegroundColor Cyan }
Write-Host ""

# Create target dir
if (-not $DryRun -and -not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
}

# --- Copy ---
Write-Host "Copying..." -ForegroundColor White

# Agents
Copy-HarnessDir ".claude\agents"  "Agent definitions"

# Skills
Copy-HarnessDir ".claude\skills"  "Skills"

# settings.json (hooks)
$settingsSrc     = Join-Path $SourceDir ".claude\settings.json"
$settingsDestRel = Convert-PathForOpencode ".claude\settings.json"
$settingsDest    = Join-Path $TargetDir $settingsDestRel
if (Test-Path $settingsSrc) {
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path (Split-Path $settingsDest) | Out-Null
        Copy-Item $settingsSrc $settingsDest -Force
        Convert-ContentForOpencode $settingsDest
        Write-Host "  [OK] settings ($settingsDestRel)" -ForegroundColor Green
    } else {
        Write-Host "  [DRY RUN] $settingsDestRel" -ForegroundColor Gray
    }
}

# docs/rules
Copy-HarnessDir "docs\rules"      "Rule files"

# .specify (templates, scripts - memory is per-project)
Copy-HarnessDir ".specify\templates"                ".specify templates"
Copy-HarnessDir ".specify\scripts"                  ".specify scripts"
Copy-HarnessDir ".specify\integrations"             ".specify integrations"

# .specify config files
foreach ($file in @("init-options.json", "integration.json")) {
    $src  = Join-Path $SourceDir ".specify\$file"
    $dest = Join-Path $TargetDir ".specify\$file"
    if (Test-Path $src) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
            Copy-Item $src $dest -Force
            Convert-ContentForOpencode $dest
        }
        Write-Host "  [OK] .specify/$file" -ForegroundColor Green
    }
}

# constitution.md template (empty version)
$constSrc  = Join-Path $SourceDir ".specify\memory\constitution.md"
$constDest = Join-Path $TargetDir ".specify\memory\constitution.md"
if (Test-Path $constSrc) {
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path (Split-Path $constDest) | Out-Null
        if (-not (Test-Path $constDest)) {
            Copy-Item $constSrc $constDest
            Convert-ContentForOpencode $constDest
            Write-Host "  [OK] .specify/memory/constitution.md (template)" -ForegroundColor Green
        } else {
            Write-Host "  [SKIP] constitution.md already exists" -ForegroundColor Yellow
        }
    }
}

# CLAUDE.md  (file name kept even in opencode mode; only contents rewritten)
$claudeSrc  = Join-Path $SourceDir "CLAUDE.md"
$claudeDest = Join-Path $TargetDir "CLAUDE.md"
if (-not $DryRun) {
    if (-not (Test-Path $claudeDest)) {
        Copy-Item $claudeSrc $claudeDest
        Convert-ContentForOpencode $claudeDest
        Write-Host "  [OK] CLAUDE.md" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] CLAUDE.md already exists (manual merge needed)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [DRY RUN] CLAUDE.md" -ForegroundColor Gray
}

# --- Done ---
Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
$agentsDir = if ($Opencode) { ".opencode" } else { ".claude" }
Write-Host "  1. CLAUDE.md  - update project name and tech stack"
Write-Host "  2. .specify\memory\constitution.md  - write project core principles"
Write-Host "  3. docs\rules\01-project-structure.md  - finalize actual tech stack"
Write-Host "  4. (optional) docs\rules\03-ai-agent-guidelines.md  - list project skills"
if ($Opencode) {
    Write-Host ""
    Write-Host "  Opencode mode: harness copied to '$agentsDir\' instead of '.claude\'." -ForegroundColor Cyan
    Write-Host "  Review the copied files and finalize any remaining tool/agent translations manually." -ForegroundColor Cyan
}
Write-Host ""
