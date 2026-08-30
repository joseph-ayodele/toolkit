# Toolkit — repository-level installer (Windows).
#
# Currently orchestrates the terminal and claude categories. Other
# categories (bootstrap, git, editors, dev, cloud, scripts) will be
# wired in here as they land — this script is not required to install
# any one of them; see terminal/install.ps1 or claude/install.ps1 for
# the per-category entrypoints.
#
# Usage:
#   irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/install.ps1 | iex
#   .\install.ps1   (from a local clone)
#
# Environment:
#   TOOLKIT_OWNER, TOOLKIT_REPO, TOOLKIT_REF   override the source repo/ref.

$ErrorActionPreference = "Stop"

$TOOLKIT_OWNER = if ($env:TOOLKIT_OWNER) { $env:TOOLKIT_OWNER } else { "joseph-ayodele" }
$TOOLKIT_REPO  = if ($env:TOOLKIT_REPO)  { $env:TOOLKIT_REPO }  else { "toolkit" }
$TOOLKIT_REF   = if ($env:TOOLKIT_REF)   { $env:TOOLKIT_REF }   else { "main" }
$RAW_BASE = "https://raw.githubusercontent.com/$TOOLKIT_OWNER/$TOOLKIT_REPO/$TOOLKIT_REF"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { "" }

function Invoke-ToolkitCategory {
    param([string]$Category)
    Write-Host "==> $Category"
    $localPath = if ($ScriptDir) { Join-Path $ScriptDir "$Category/install.ps1" } else { "" }
    if ($ScriptDir -and (Test-Path $localPath)) {
        & $localPath
    } else {
        Invoke-RestMethod "$RAW_BASE/$Category/install.ps1" | Invoke-Expression
    }
}

Write-Host "==> Toolkit installer"

Invoke-ToolkitCategory "terminal"
Invoke-ToolkitCategory "claude"
