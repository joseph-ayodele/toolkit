# Toolkit — PowerShell component installer (Windows).
#
# Installs the Toolkit PowerShell profile (aliases, functions, prompt
# wiring) and links it into $PROFILE via a single managed block. This
# is also the update command — re-running it refreshes Toolkit-owned
# files in place without touching unrelated $PROFILE content.
#
# Usage:
#   irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/powershell/install.ps1 | iex
#   .\terminal\powershell\install.ps1   (from a local clone)
#
# Environment:
#   TOOLKIT_OWNER, TOOLKIT_REPO, TOOLKIT_REF   override the source repo/ref.
#   TOOLKIT_HOME                               override the install root (default: ~/.config/toolkit).

$ErrorActionPreference = "Stop"

$TOOLKIT_OWNER = if ($env:TOOLKIT_OWNER) { $env:TOOLKIT_OWNER } else { "joseph-ayodele" }
$TOOLKIT_REPO  = if ($env:TOOLKIT_REPO)  { $env:TOOLKIT_REPO }  else { "toolkit" }
$TOOLKIT_REF   = if ($env:TOOLKIT_REF)   { $env:TOOLKIT_REF }   else { "main" }
$RAW_BASE = "https://raw.githubusercontent.com/$TOOLKIT_OWNER/$TOOLKIT_REPO/$TOOLKIT_REF"
$ComponentPath = "terminal/powershell"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { "" }

function Get-ToolkitFile {
    param([string]$Relative, [string]$Dest)
    New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
    $local = if ($ScriptDir) { Join-Path $ScriptDir $Relative } else { "" }
    if ($ScriptDir -and (Test-Path $local)) {
        Copy-Item $local $Dest -Force
    } else {
        $tmp = New-TemporaryFile
        Invoke-RestMethod "$RAW_BASE/$ComponentPath/$Relative" -OutFile $tmp
        Move-Item $tmp.FullName $Dest -Force
    }
}

$ToolkitHome = if ($env:TOOLKIT_HOME) { $env:TOOLKIT_HOME } else { Join-Path $HOME ".config/toolkit" }
$InstallDir = Join-Path $ToolkitHome "terminal/powershell"

Write-Host "==> Installing Toolkit PowerShell profile"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Get-ToolkitFile -Relative "toolkit.ps1"   -Dest (Join-Path $InstallDir "toolkit.ps1")
Get-ToolkitFile -Relative "aliases.ps1"   -Dest (Join-Path $InstallDir "aliases.ps1")
Get-ToolkitFile -Relative "functions.ps1" -Dest (Join-Path $InstallDir "functions.ps1")

Write-Host "==> Wiring `$PROFILE"

$ProfilePath = $PROFILE.CurrentUserAllHosts
$ProfileDir = Split-Path $ProfilePath
New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
if (-not (Test-Path $ProfilePath)) {
    New-Item -ItemType File -Force -Path $ProfilePath | Out-Null
}

$MarkerStart = "# >>> toolkit:terminal >>>"
$MarkerEnd   = "# <<< toolkit:terminal <<<"
$content = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
if ($null -eq $content) { $content = "" }

if ($content -notmatch [regex]::Escape($MarkerStart)) {
    Copy-Item $ProfilePath "$ProfilePath.toolkit-backup" -Force
    Write-Host "    backed up existing profile to $ProfilePath.toolkit-backup"
}

$pattern = "(?s)" + [regex]::Escape($MarkerStart) + ".*?" + [regex]::Escape($MarkerEnd) + "\r?\n?"
$stripped = [regex]::Replace($content, $pattern, "")

$block = @"
$MarkerStart
if (Test-Path "`$HOME/.config/toolkit/terminal/powershell/toolkit.ps1") { . "`$HOME/.config/toolkit/terminal/powershell/toolkit.ps1" }
$MarkerEnd
"@

$newContent = $stripped.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
Set-Content -Path $ProfilePath -Value $newContent -NoNewline

Write-Host "==> PowerShell component installed."
Write-Host "    restart PowerShell or run: . `$PROFILE"
