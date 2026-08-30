# Toolkit — Claude skills component installer (Windows).
#
# Installs the Toolkit's vendored Claude Code skills into
# ~/.claude/skills/, where Claude Code picks them up automatically
# (each loads as <name>@skills-dir). This is also the update command
# — re-running it replaces each Toolkit-owned skill directory in
# place, dropping files that upstream removed, and never touches
# skills Toolkit does not own.
#
# A skill directory is considered Toolkit-owned once it contains a
# .toolkit-managed marker. A pre-existing directory without that
# marker is backed up to <name>.toolkit-backup before it is replaced.
#
# Usage:
#   irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/claude/skills/install.ps1 | iex
#   .\claude\skills\install.ps1                 (from a local clone; installs every skill)
#   .\claude\skills\install.ps1 visual-plan     (install/update a single skill)
#
# Environment:
#   TOOLKIT_OWNER, TOOLKIT_REPO, TOOLKIT_REF   override the source repo/ref.
#   CLAUDE_CONFIG_DIR                          override Claude's config dir (default: ~/.claude).

param([string[]]$Skill)

$ErrorActionPreference = "Stop"

$TOOLKIT_OWNER = if ($env:TOOLKIT_OWNER) { $env:TOOLKIT_OWNER } else { "joseph-ayodele" }
$TOOLKIT_REPO  = if ($env:TOOLKIT_REPO)  { $env:TOOLKIT_REPO }  else { "toolkit" }
$TOOLKIT_REF   = if ($env:TOOLKIT_REF)   { $env:TOOLKIT_REF }   else { "main" }
$RAW_BASE = "https://raw.githubusercontent.com/$TOOLKIT_OWNER/$TOOLKIT_REPO/$TOOLKIT_REF"
$ComponentPath = "claude/skills"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { "" }

$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$SkillsDir = Join-Path $ClaudeDir "skills"

$Marker = ".toolkit-managed"

# Every skill Toolkit vendors, and the files each one owns. Keep these
# lists in sync with the directories in this component — the remote
# (irm | iex) path has no directory listing to walk, so the manifest is
# what tells it which files to fetch.
$SkillManifest = [ordered]@{
    "visual-plan" = @(
        "SKILL.md",
        "README.md",
        "LICENSE.upstream",
        "references/canvas.md",
        "references/connection.md",
        "references/document-quality.md",
        "references/exemplar.md",
        "references/local-files.md",
        "references/wireframe.md"
    )
    "visual-recap" = @(
        "SKILL.md",
        "README.md",
        "LICENSE.upstream",
        "references/connection.md",
        "references/local-files.md",
        "references/wireframe.md"
    )
    "stop-slop" = @(
        "SKILL.md",
        "README.md",
        "LICENSE.upstream",
        "LICENSE.upstream.unslop",
        "references/examples.md",
        "references/phrases.md",
        "references/structures.md",
        "references/epistemics.md",
        "references/style-profile-template.md"
    )
}

# Alternate names for a vendored skill above: same files, fetched from the
# canonical source dir, installed under the alias's own directory name with
# the SKILL.md `name:` field swapped to match. Add an entry here to give
# any skill above another install name — no other changes needed.
# unslop -> stop-slop: stop-slop now includes unslop's epistemics level and
# style-profile template, merged in from upstream.
$SkillAliases = @{ "unslop" = "stop-slop" }
function Get-AliasSource {
    param([string]$Name)
    if ($SkillAliases.ContainsKey($Name)) { $SkillAliases[$Name] } else { $Name }
}
$InstallableSkills = @($SkillManifest.Keys) + @($SkillAliases.Keys)

function Get-ToolkitFile {
    param([string]$Relative, [string]$Dest)
    New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
    $localPath = if ($ScriptDir) { Join-Path $ScriptDir $Relative } else { "" }
    if ($ScriptDir -and (Test-Path $localPath)) {
        Copy-Item $localPath $Dest -Force
    } else {
        $tmp = New-TemporaryFile
        Invoke-RestMethod "$RAW_BASE/$ComponentPath/$Relative" -OutFile $tmp
        Move-Item $tmp.FullName $Dest -Force
    }
}

function Install-ToolkitSkill {
    param([string]$Name)

    $source = Get-AliasSource $Name
    if (-not $SkillManifest.Contains($source)) {
        throw "unknown skill '$Name'. Known skills: $($InstallableSkills -join ', ')"
    }

    $dest     = Join-Path $SkillsDir $Name
    $staging  = Join-Path $SkillsDir ".$Name.toolkit-staging"
    $backup   = "$dest.toolkit-backup"

    $existing = Get-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType) {
        throw "$dest is a $($existing.LinkType), presumably managed by something else. Refusing to replace it; remove it by hand and re-run."
    }

    if ($existing -and -not (Test-Path (Join-Path $dest $Marker))) {
        if (Test-Path $backup) {
            Write-Host "    replacing unmanaged $Name (backup already exists at $Name.toolkit-backup)"
        } else {
            Copy-Item $dest $backup -Recurse -Force
            Write-Host "    backed up existing $Name to $Name.toolkit-backup"
        }
    }

    # Stage the whole skill first, so a failed download can never leave a
    # half-written skill directory behind where Claude Code would read it.
    if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $staging | Out-Null

    foreach ($relative in $SkillManifest[$source]) {
        try {
            Get-ToolkitFile -Relative "$source/$relative" -Dest (Join-Path $staging $relative)
        } catch {
            Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
            throw "failed to fetch $Name/$relative; leaving the installed copy untouched. ($_)"
        }
    }

    $skillDoc = Join-Path $staging "SKILL.md"
    if (-not (Test-Path $skillDoc) -or (Get-Item $skillDoc).Length -eq 0) {
        Remove-Item $staging -Recurse -Force
        throw "$Name/SKILL.md came back empty; leaving the installed copy untouched."
    }

    if ($source -ne $Name) {
        (Get-Content $skillDoc) -replace '^name: .*', "name: $Name" | Set-Content $skillDoc -Encoding utf8
    }

    @(
        "# Installed by Toolkit — https://github.com/$TOOLKIT_OWNER/$TOOLKIT_REPO",
        "# Source: $ComponentPath/$Name",
        "# Edits here are overwritten on the next run; change the skill in the repo instead."
    ) | Set-Content -Path (Join-Path $staging $Marker) -Encoding utf8

    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Move-Item $staging $dest
    Write-Host "    installed $Name -> $dest"
}

$targets = if ($Skill) { $Skill } else { @($SkillManifest.Keys) }

# Validate every requested name before touching the filesystem, so a
# typo in one argument can't leave a partial install behind.
foreach ($name in $targets) {
    if ($InstallableSkills -notcontains $name) {
        throw "unknown skill '$name'. Known skills: $($InstallableSkills -join ', ')"
    }
}

Write-Host "==> Installing Toolkit Claude skills"

New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
foreach ($name in $targets) {
    Install-ToolkitSkill -Name $name
}

Write-Host "==> Claude skills component installed."
Write-Host "    restart Claude Code to pick them up: $($targets -join ', ')"
