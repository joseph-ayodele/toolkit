# Toolkit — Claude component orchestrator (Windows).
#
# Installs the Claude Code environment: currently the vendored skills
# in claude/skills/. This is also the update command — re-running it
# refreshes every Toolkit-owned skill in place.
#
# Usage:
#   irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/claude/install.ps1 | iex
#   .\claude\install.ps1   (from a local clone)
#
# Environment:
#   TOOLKIT_OWNER, TOOLKIT_REPO, TOOLKIT_REF   override the source repo/ref.

$ErrorActionPreference = "Stop"

$TOOLKIT_OWNER = if ($env:TOOLKIT_OWNER) { $env:TOOLKIT_OWNER } else { "joseph-ayodele" }
$TOOLKIT_REPO  = if ($env:TOOLKIT_REPO)  { $env:TOOLKIT_REPO }  else { "toolkit" }
$TOOLKIT_REF   = if ($env:TOOLKIT_REF)   { $env:TOOLKIT_REF }   else { "main" }
$RAW_BASE = "https://raw.githubusercontent.com/$TOOLKIT_OWNER/$TOOLKIT_REPO/$TOOLKIT_REF"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { "" }

function Invoke-ToolkitComponent {
    param([string]$Component)
    Write-Host "==> claude/$Component"
    $localPath = if ($ScriptDir) { Join-Path $ScriptDir "$Component/install.ps1" } else { "" }
    if ($ScriptDir -and (Test-Path $localPath)) {
        & $localPath
    } else {
        Invoke-RestMethod "$RAW_BASE/claude/$Component/install.ps1" | Invoke-Expression
    }
}

Invoke-ToolkitComponent "skills"

Write-Host "==> Claude environment installed. Restart Claude Code to pick up the skills."
