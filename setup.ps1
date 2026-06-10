# setup.ps1 - Apply harness to a new project
#
# Usage:
#   .\setup.ps1 -TargetDir "C:\path\to\project"
#   .\setup.ps1 -TargetDir "../my-project" -DryRun
#   .\setup.ps1 -TargetDir "../my-project" -Opencode
#     ↳ Full opencode adaptation:
#       - .claude/agents   -> .opencode/agents   (복수 유지 + frontmatter: keep name, drop color, add mode: subagent, map model->KTDS Qwen, drop tools array line)
#       - .claude/skills   -> .opencode/skills   (kept as its own folder; SKILL.md preserved)
#       - .claude/commands -> .opencode/commands (복수 유지)
#       - .claude/rules    -> .opencode/rules    (복수 유지)
#       - .claude/settings.json: opencode 옵션 시 미복사 (hook 은 plugin 으로 대체)
#       - Content references rewritten with same prefix-only mapping (.claude -> .opencode)
#       - Agent(subagent_type=..., description=X, prompt=Y) -> opencode task tool 호출 텍스트 자동 변환
#       - AskUserQuestion -> STOP(텍스트 응답 대기) 자동 변환
#       - .opencode/plugins/harness-rules.js 배치 (opencode 옵션일 때만 — system 규칙 주입 plugin)
#       - opencode 공식 표준 + devai fork 모두 복수형 (agents, skills, commands, rules, plugins) 사용

param(
    [Parameter(Mandatory=$true, HelpMessage="Target project directory")]
    [string]$TargetDir,

    [switch]$DryRun,
    [switch]$Opencode
)

# PS 5.1 콘솔 출력 인코딩을 UTF-8 로 고정 (한글 mojibake 방지).
# 이 스크립트는 UTF-8 (BOM) 으로 저장되어야 하며, 한글 메시지·치환 텍스트가
# 시스템 로케일(CP949 등)로 잘못 출력/기록되지 않도록 한다.
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

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

    # opencode 공식 표준: 모든 디렉터리 복수형 유지 (agents, skills, commands, rules, plugins).
    # 단수형은 backward compat 일 뿐이며 devai fork 는 복수형만 안정적으로 인식.
    # 따라서 디렉터리명은 .claude 그대로 두고 prefix 만 .opencode 로 변경.
    $mapped = $Path -replace '\.claude([\\/])', '.opencode$1'
    # bare ".claude" (디렉터리 구분자 없이 끝나는 경우) 도 처리
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

    # Agent(...) -> opencode/devai `task(...)` 호출로 변환.
    # devai task 시그니처: task(subagent_type="<name>", load_skills=[...], description="...", prompt="...")
    #   - subagent_type: prompt 안의 .../agents/<name>.md 에서 실제 agent 이름 추출
    #     (devai 는 general-purpose 가 아니라 실제 등록된 agent 이름을 요구)
    #   - load_skills: agent 별 기본 skill 자동 주입 ($AgentSkillMap)
    # Triple-quote ("""...""") 양식 먼저 (더 구체적), 그 다음 단일 quote 양식.
    $agentPatternTriple = '(?s)Agent\(\s*subagent_type="[^"]*",\s*description="([^"]+)",\s*prompt="""([\s\S]+?)"""\s*\)'
    $agentPatternSingle = '(?s)Agent\(\s*subagent_type="[^"]*",\s*description="([^"]+)",\s*prompt="([^"]+)"\s*\)'

    # agent 이름 -> load_skills 기본값 (devai skill id 는 .opencode/skills/<id>/ 디렉터리명).
    # 핵심 SDD 워크플로 agent 만 정적 매핑. 나머지는 빈 배열 (prompt 의 skill 참조 지시로 보완).
    $AgentSkillMap = @{
        'planner'     = '"speckit-specify", "speckit-plan", "speckit-tasks"'
        'implementer' = '"speckit-implement"'
    }

    $taskEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
        param($m)
        $desc = $m.Groups[1].Value
        $prm  = $m.Groups[2].Value
        $name = 'general-purpose'
        $nm = [regex]::Match($prm, 'agents[\\/]([\w-]+)\.md')
        if ($nm.Success) { $name = $nm.Groups[1].Value }
        $skills = ''
        if ($AgentSkillMap.ContainsKey($name)) { $skills = $AgentSkillMap[$name] }
        "task(`r`n  subagent_type=`"$name`",`r`n  load_skills=[$skills],`r`n  description=`"$desc`",`r`n  prompt=`"$prm`"`r`n)"
    }
    $reSingleline = [System.Text.RegularExpressions.RegexOptions]::Singleline

    foreach ($f in $files) {
        if ($TextExtensions -notcontains $f.Extension.ToLower()) { continue }

        $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)

        $needsRewrite = ($content -match '\.claude') -or `
                        ($content -match 'Agent\(\s*subagent_type') -or `
                        ($content -match 'AskUserQuestion')
        if (-not $needsRewrite) { continue }

        $new = $content

        # 1) 디렉터리 경로 매핑 (.claude -> .opencode, 복수형 그대로 유지).
        #    opencode 공식 표준 + devai fork 둘 다 복수형 (agents, skills, commands, rules, plugins) 안정 인식.
        $new = $new -replace '\.claude([\\/])', '.opencode$1'
        # bare ".claude" (끝/구분자 없음) 도 처리
        $new = $new -replace '\.claude',        '.opencode'

        # 2) Agent(...) -> task(...) 변환 (subagent_type 추출 + load_skills 주입).
        #    경로 변환(.opencode/agents/<name>.md) 후이므로 evaluator 가 이름 추출 가능.
        $new = [regex]::Replace($new, $agentPatternTriple, $taskEvaluator, $reSingleline)
        $new = [regex]::Replace($new, $agentPatternSingle, $taskEvaluator, $reSingleline)

        # 3) AskUserQuestion -> STOP+텍스트 fallback (opencode 등가 도구 없음)
        $new = $new -replace '`AskUserQuestion`', 'STOP(텍스트로 사용자에게 옵션 제시 후 응답 대기)'
        $new = $new -replace 'AskUserQuestion',   'STOP(텍스트로 사용자에게 옵션 제시 후 응답 대기)'

        [System.IO.File]::WriteAllText($f.FullName, $new, $utf8NoBom)
    }
}

# Agent -> KTDS model map for opencode (Claude models unavailable in this fork).
#   Main [KTDS] Qwen3.6-27B-FP8     : dense 27B - deep reasoning/generation
#                                     (architecture, security, TDD strategy, L1 workflow agents).
#   Sub  [KTDS] Qwen3.6-35B-A3B-FP8 : MoE active 3B - fast/light
#                                     (pattern-based language reviewers, loop monitoring, docs).
# Values are pre-quoted so the leading "[" stays a YAML string, not a flow sequence.
$AgentModelMap = @{
    'architect'           = '"ABCLab/[KTDS] Qwen3.6-27B-FP8"'
    'code-architect'      = '"ABCLab/[KTDS] Qwen3.6-27B-FP8"'
    'security-reviewer'   = '"ABCLab/[KTDS] Qwen3.6-27B-FP8"'
    'tdd-guide'           = '"ABCLab/[KTDS] Qwen3.6-27B-FP8"'
    'planner'             = '"ABCLab/[KTDS] Qwen3.6-27B-FP8"'
    'implementer'         = '"ABCLab/[KTDS] Qwen3.6-27B-FP8"'
    'reviewer'            = '"ABCLab/[KTDS] Qwen3.6-27B-FP8"'
    'qa'                  = '"ABCLab/[KTDS] Qwen3.6-27B-FP8"'
    'code-reviewer'       = '"ABCLab/[KTDS] Qwen3.6-35B-A3B-FP8"'
    'python-reviewer'     = '"ABCLab/[KTDS] Qwen3.6-35B-A3B-FP8"'
    'java-reviewer'       = '"ABCLab/[KTDS] Qwen3.6-35B-A3B-FP8"'
    'typescript-reviewer' = '"ABCLab/[KTDS] Qwen3.6-35B-A3B-FP8"'
    'fastapi-reviewer'    = '"ABCLab/[KTDS] Qwen3.6-35B-A3B-FP8"'
    'loop-operator'       = '"ABCLab/[KTDS] Qwen3.6-35B-A3B-FP8"'
    'doc-updater'         = '"ABCLab/[KTDS] Qwen3.6-35B-A3B-FP8"'
}

function Convert-AgentFrontmatter {
    # Cleanup agent .md frontmatter for opencode/devai:
    #   - ensure `name:` line (devai fork requires it; keep original or insert filename)
    #   - remove `color:` line (no opencode equivalent)
    #   - add `mode: subagent` after `description:` if missing
    #   - map `model:` to a KTDS Qwen model per $AgentModelMap (insert if absent)
    #   - remove the inline `tools: [..]` array line (opencode wants a record/list, not an array)
    param([string]$AgentDir)
    if (-not $Opencode -or -not (Test-Path $AgentDir)) { return }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    Get-ChildItem -Path $AgentDir -Recurse -Filter "*.md" -File | ForEach-Object {
        $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $modified = $false

        # Only operate on files with frontmatter block
        if ($content -notmatch '(?s)^---\r?\n.*?\r?\n---\r?\n') { return }

        # Ensure `name:` line (devai fork 필수 필드). 원본 name 유지,
        # 없으면 파일명으로 frontmatter 최상단(첫 --- 다음)에 삽입.
        if ($content -notmatch '(?m)^name:\s*\S') {
            $content = $content -replace '^(---\r?\n)', "`$1name: $($_.BaseName)`r`n"
            $modified = $true
        }

        # Remove `color:` line (opencode agent frontmatter has no color field)
        if ($content -match '(?m)^color:\s*[^\r\n]+\r?\n') {
            $content = $content -replace '(?m)^color:\s*[^\r\n]+\r?\n', ''
            $modified = $true
        }

        # Add `mode: subagent` after first `description:` if not present anywhere
        if ($content -notmatch '(?m)^mode:\s*\S') {
            if ($content -match '(?m)^description:[^\r\n]+\r?\n') {
                $content = $content -replace '(?m)^(description:[^\r\n]+\r?\n)', "`$1mode: subagent`r`n"
                $modified = $true
            }
        }

        # Resolve target KTDS model (default to main 27B if filename unmapped)
        $targetModel = $AgentModelMap[$_.BaseName]
        if (-not $targetModel) { $targetModel = '"ABCLab/[KTDS] Qwen3.6-27B-FP8"' }

        # Map existing `model:` line, else insert after `mode: subagent` (or description)
        if ($content -match '(?m)^model:\s*\S') {
            $content = $content -replace '(?m)^model:[^\r\n]*', "model: $targetModel"
            $modified = $true
        } elseif ($content -match '(?m)^mode:\s*subagent\r?\n') {
            $content = $content -replace '(?m)^(mode:\s*subagent\r?\n)', "`$1model: $targetModel`r`n"
            $modified = $true
        } elseif ($content -match '(?m)^description:[^\r\n]+\r?\n') {
            $content = $content -replace '(?m)^(description:[^\r\n]+\r?\n)', "`$1model: $targetModel`r`n"
            $modified = $true
        }

        # Remove the inline `tools: [..]` array line entirely. opencode expects
        # `tools` as a record (e.g. `read: true`), not an array; dropping the line
        # lets the agent inherit the default toolset.
        if ($content -match '(?m)^tools:[ \t]*\[.*?\]\r?\n') {
            $content = $content -replace '(?m)^tools:[ \t]*\[.*?\]\r?\n', ''
            $modified = $true
        }

        if ($modified) {
            [System.IO.File]::WriteAllText($_.FullName, $content, $utf8NoBom)
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
    Write-Host "    .claude/agents   -> .opencode/agents   (복수 유지 + frontmatter: model->KTDS Qwen, mode: subagent, drop tools line)" -ForegroundColor Cyan
    Write-Host "    .claude/skills   -> .opencode/skills   (kept as its own folder; SKILL.md preserved)" -ForegroundColor Cyan
    Write-Host "    .claude/commands -> .opencode/commands (복수 유지)" -ForegroundColor Cyan
    Write-Host "    .claude/rules    -> .opencode/rules    (복수 유지)" -ForegroundColor Cyan
    Write-Host "    .claude/settings.json    미복사 (opencode 는 plugin 사용)" -ForegroundColor Cyan
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
    $agentTarget = Join-Path $TargetDir ".opencode\agents"
    Convert-AgentFrontmatter $agentTarget
    Write-Host "  [OK] Opencode post-process (agent frontmatter)" -ForegroundColor Green
    # opencode 전용 plugin 배치 (opencode 옵션일 때만 생성)
    $pluginSrc = Join-Path $SourceDir ".opencode\plugins"
    if (Test-Path $pluginSrc) {
        $pluginDest = Join-Path $TargetDir ".opencode\plugins"
        New-Item -ItemType Directory -Force -Path $pluginDest | Out-Null
        Copy-Item -Path (Join-Path $pluginSrc "*") -Destination $pluginDest -Recurse -Force
        Write-Host "  [OK] opencode plugin (.opencode/plugins/harness-rules.js)" -ForegroundColor Green
    }
}

# settings.json -> .claude/settings.json (일반 모드 전용)
# opencode 옵션 시엔 settings.json 미사용 (hook 은 plugin 으로 대체) — 복사 skip.
if (-not $Opencode) {
    $settingsSrc = Join-Path $SourceDir ".claude\settings.json"
    if (Test-Path $settingsSrc) {
        $settingsDest    = Join-Path $TargetDir ".claude\settings.json"
        $settingsDestRel = ".claude\settings.json"

        if ($DryRun) {
            Write-Host "  [DRY RUN] $settingsDestRel" -ForegroundColor Gray
        } else {
            New-Item -ItemType Directory -Force -Path (Split-Path $settingsDest) | Out-Null
            Copy-Item $settingsSrc $settingsDest -Force
            Write-Host "  [OK] settings ($settingsDestRel)" -ForegroundColor Green
        }
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

# 루트 단일 파일 (.gitignore, QUICKSTART.md) — 기존 파일 존재 시 스킵
foreach ($file in @(".gitignore", "QUICKSTART.md")) {
    $src  = Join-Path $SourceDir $file
    $dest = Join-Path $TargetDir $file
    if (-not (Test-Path $src)) { continue }
    if ($DryRun) {
        Write-Host "  [DRY RUN] $file" -ForegroundColor Gray
    } elseif (-not (Test-Path $dest)) {
        Copy-Item $src $dest
        Convert-ContentForOpencode $dest
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] $file already exists" -ForegroundColor Yellow
    }
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
    Write-Host "  Opencode mode — auto-converted (no action) + manual review required:" -ForegroundColor Cyan
    Write-Host "    [auto] Agent(subagent_type=..., description=X, prompt=Y) -> 'task' tool 호출 텍스트로 변환 완료" -ForegroundColor Green
    Write-Host "    [auto] AskUserQuestion -> STOP(텍스트 응답 대기) 로 변환 완료" -ForegroundColor Green
    Write-Host "    [auto] .claude/{agents,skills,commands,rules} -> .opencode/{agents,skills,commands,rules} (복수 유지) 경로 변환 완료" -ForegroundColor Green
    Write-Host "    a) /Skill(...) 같은 그 외 Claude Code 전용 도구 호출이 있으면 사내 fork 의 등가 표기로 수동 치환 필요" -ForegroundColor Cyan
    Write-Host "    b) hook 은 .opencode/plugins/harness-rules.js (system 규칙 주입) 가 담당. settings.json 은 opencode 에서 미사용." -ForegroundColor Cyan
    Write-Host "    c) Decide which agent should be 'mode: primary' (default: all subagent). Update one frontmatter." -ForegroundColor Cyan
    Write-Host "    d) Verify .opencode/skills/<skill>/ nested structure (SKILL.md kept) with companion files (scripts/) is supported by your fork." -ForegroundColor Cyan
    Write-Host "    e) .opencode/rules/ 디렉터리는 .claude/rules/ 의 ECC 부속 규칙 보존용. opencode 표준은 AGENTS.md 단일 파일 권장 — 필요 시 변환." -ForegroundColor Cyan
    Write-Host "    f) Agent 'model:' mapped to KTDS Qwen ([KTDS] Qwen3.6-27B-FP8 main / -35B-A3B-FP8 sub) — confirm the model id format your opencode provider expects." -ForegroundColor Cyan
}
Write-Host ""
