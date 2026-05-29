# setup.ps1 - Apply harness to a new project
#
# Usage:
#   .\setup.ps1 -TargetDir "C:\path\to\project"
#   .\setup.ps1 -TargetDir "../my-project" -DryRun
#   .\setup.ps1 -TargetDir "../my-project" -Opencode
#     ↳ Full opencode adaptation:
#       - .claude/agents   -> .opencode/agent   (singular + frontmatter cleanup: drop name, add mode: subagent)
#       - .claude/skills   -> .opencode/command (semantic; SKILL.md -> <skill-name>.md)
#       - .claude/commands -> .opencode/command (merged)
#       - .claude/rules    -> .opencode/rule    (singular)
#       - .claude/settings.json -> .opencode/settings.json
#       - Content references rewritten with same path mapping
#       - Skill/Agent tool call sites in markdown bodies require manual review (not auto-converted)

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
    if (-not $Opencode) { return $Path }

    $mapped = $Path
    # settings.json -> .opencode/settings.json
    $mapped = $mapped -replace '\.claude[\\/]+settings\.json', '.opencode\settings.json'
    # agents -> agent (singular)
    $mapped = $mapped -replace '\.claude[\\/]+agents', '.opencode\agent'
    # skills -> command (semantic mapping)
    $mapped = $mapped -replace '\.claude[\\/]+skills', '.opencode\command'
    # commands -> command (merged with skills)
    $mapped = $mapped -replace '\.claude[\\/]+commands', '.opencode\command'
    # rules -> rule (singular)
    $mapped = $mapped -replace '\.claude[\\/]+rules', '.opencode\rule'
    # fallback for any other .claude reference (e.g., bare ".claude" or .claude/foo)
    $mapped = $mapped -replace '\.claude', '.opencode'
    return $mapped
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
        if ($content -notmatch '\.claude') { continue }

        $new = $content
        # Priority-ordered: directory-aware mappings first, fallback last
        $new = $new -replace '\.claude([\\/])agents',   '.opencode$1agent'
        $new = $new -replace '\.claude([\\/])skills',   '.opencode$1command'
        $new = $new -replace '\.claude([\\/])commands', '.opencode$1command'
        $new = $new -replace '\.claude([\\/])rules',    '.opencode$1rule'
        # fallback (bare .claude or .claude/<other>)
        $new = $new -replace '\.claude',                '.opencode'

        [System.IO.File]::WriteAllText($f.FullName, $new, $utf8NoBom)
    }
}

function Convert-AgentFrontmatter {
    # Cleanup agent .md frontmatter for opencode:
    #   - remove `name:` line (filename takes over in opencode)
    #   - add `mode: subagent` after `description:` if missing
    param([string]$AgentDir)
    if (-not $Opencode -or -not (Test-Path $AgentDir)) { return }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    Get-ChildItem -Path $AgentDir -Recurse -Filter "*.md" -File | ForEach-Object {
        $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $modified = $false

        # Only operate on files with frontmatter block
        if ($content -notmatch '(?s)^---\r?\n.*?\r?\n---\r?\n') { return }

        # Remove `name:` line
        if ($content -match '(?m)^name:\s*[^\r\n]+\r?\n') {
            $content = $content -replace '(?m)^name:\s*[^\r\n]+\r?\n', ''
            $modified = $true
        }

        # Add `mode: subagent` after first `description:` if not present anywhere
        if ($content -notmatch '(?m)^mode:\s*\S') {
            if ($content -match '(?m)^description:[^\r\n]+\r?\n') {
                $content = $content -replace '(?m)^(description:[^\r\n]+\r?\n)', "`$1mode: subagent`r`n"
                $modified = $true
            }
        }

        if ($modified) {
            [System.IO.File]::WriteAllText($_.FullName, $content, $utf8NoBom)
        }
    }
}

function Rename-SkillToCommand {
    # opencode has no SKILL.md concept. Rename each <skill>/SKILL.md to <skill>/<skill>.md
    # so opencode discovers the command file. Companion files (scripts/, references/) kept in place.
    param([string]$CommandDir)
    if (-not $Opencode -or -not (Test-Path $CommandDir)) { return }

    Get-ChildItem -Path $CommandDir -Recurse -Filter "SKILL.md" -File | ForEach-Object {
        $parentName = $_.Directory.Name
        $safeName   = $parentName -replace '[^a-zA-Z0-9_\-]', '-'
        $newPath    = Join-Path $_.Directory.FullName "$safeName.md"
        if (-not (Test-Path $newPath)) {
            Move-Item -Path $_.FullName -Destination $newPath -Force
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
if ($Opencode) {
    Write-Host "  Mode: OPENCODE" -ForegroundColor Cyan
    Write-Host "    .claude/agents   -> .opencode/agent     (singular + frontmatter cleanup)" -ForegroundColor Cyan
    Write-Host "    .claude/skills   -> .opencode/command   (semantic; SKILL.md renamed)" -ForegroundColor Cyan
    Write-Host "    .claude/commands -> .opencode/command   (merged)" -ForegroundColor Cyan
    Write-Host "    .claude/rules    -> .opencode/rule" -ForegroundColor Cyan
    Write-Host "    .claude/settings.json -> .opencode/settings.json" -ForegroundColor Cyan
}
Write-Host ""

# Create target dir
if (-not $DryRun -and -not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
}

# --- Copy ---
Write-Host "Copying..." -ForegroundColor White

# Agents (L1 4 + L2 11 = 15)
Copy-HarnessDir ".claude\agents"  "Agent definitions"

# Skills (caveman, speckit-*, harness-*, ecc/, superpowers/)
Copy-HarnessDir ".claude\skills"  "Skills"

# Slash commands (gan-design, multi-*, update-*, /test-coverage 등 10개)
Copy-HarnessDir ".claude\commands"  "Slash commands"

# ECC reference rules (.claude/rules/ecc/)
Copy-HarnessDir ".claude\rules"  "ECC reference rules"

# Opencode-specific post-processing (after directory copies, before settings.json)
if ($Opencode -and -not $DryRun) {
    $agentTarget   = Join-Path $TargetDir ".opencode\agent"
    $commandTarget = Join-Path $TargetDir ".opencode\command"
    Convert-AgentFrontmatter $agentTarget
    Rename-SkillToCommand    $commandTarget
    Write-Host "  [OK] Opencode post-process (agent frontmatter, SKILL.md rename)" -ForegroundColor Green
}

# settings.json -> .claude/settings.json (default) OR .opencode/settings.json (-Opencode)
$settingsSrc = Join-Path $SourceDir ".claude\settings.json"
if (Test-Path $settingsSrc) {
    if ($Opencode) {
        $settingsDest    = Join-Path $TargetDir ".opencode\settings.json"
        $settingsDestRel = ".opencode\settings.json"
    } else {
        $settingsDest    = Join-Path $TargetDir ".claude\settings.json"
        $settingsDestRel = ".claude\settings.json"
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] $settingsDestRel" -ForegroundColor Gray
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path $settingsDest) | Out-Null
        Copy-Item $settingsSrc $settingsDest -Force
        Convert-ContentForOpencode $settingsDest

        Write-Host "  [OK] settings ($settingsDestRel)" -ForegroundColor Green
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
    Write-Host "  Opencode mode — additional manual review required:" -ForegroundColor Cyan
    Write-Host "    a) Skill bodies in .opencode/command/*.md still reference 'Agent(...)' / 'Skill(...)' tool calls." -ForegroundColor Cyan
    Write-Host "       Replace with opencode '@agent-name' / '/command-name' per your fork." -ForegroundColor Cyan
    Write-Host "    b) .opencode/settings.json has hook keys (UserPromptSubmit, etc.) — migrate to opencode event names." -ForegroundColor Cyan
    Write-Host "    c) Decide which agent should be 'mode: primary' (default: all subagent). Update one frontmatter." -ForegroundColor Cyan
    Write-Host "    d) Verify .opencode/command/<skill>/ nested structure with companion files (scripts/) is supported by your fork." -ForegroundColor Cyan
    Write-Host "    e) Check .opencode/rule/ vs your fork's expected rules directory name." -ForegroundColor Cyan
}
Write-Host ""
