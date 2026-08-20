# Toolkit — terminal component orchestrator (Windows).
#
# Installs Oh My Posh + theme and the PowerShell profile (aliases,
# functions, prompt wiring). This is also the update command —
# re-running it refreshes Toolkit-owned files in place without
# touching unrelated profile content.
#
# Usage:
#   irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/install.ps1 | iex
#   .\terminal\install.ps1   (from a local clone)
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
    Write-Host "==> terminal/$Component"
    $local = if ($ScriptDir) { Join-Path $ScriptDir "$Component/install.ps1" } else { "" }
    if ($ScriptDir -and (Test-Path $local)) {
        & $local
    } else {
        Invoke-RestMethod "$RAW_BASE/terminal/$Component/install.ps1" | Invoke-Expression
    }
}

Invoke-ToolkitComponent "oh-my-posh"
Invoke-ToolkitComponent "powershell"

Write-Host "==> Terminal environment installed. Restart PowerShell to see changes."
