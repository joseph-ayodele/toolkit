# Toolkit — Oh My Posh component installer (Windows).
#
# Installs the oh-my-posh binary (via winget, if missing) and the
# Toolkit's Catppuccin Latte theme to
# $HOME/.config/toolkit/terminal/oh-my-posh/, then checks PowerShell
# profiles and wires prompt init via a managed block — unless it's
# already wired (by this script, by the fuller terminal/powershell
# component, or by hand). Safe to rerun: it skips the binary install
# if already present and always refreshes the theme file.
#
# Usage:
#   irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/oh-my-posh/install.ps1 | iex
#   .\terminal\oh-my-posh\install.ps1   (from a local clone)
#
# Environment:
#   TOOLKIT_OWNER, TOOLKIT_REPO, TOOLKIT_REF   override the source repo/ref.
#   TOOLKIT_HOME                               override the install root (default: ~/.config/toolkit).

$ErrorActionPreference = "Stop"

$TOOLKIT_OWNER = if ($env:TOOLKIT_OWNER) { $env:TOOLKIT_OWNER } else { "joseph-ayodele" }
$TOOLKIT_REPO  = if ($env:TOOLKIT_REPO)  { $env:TOOLKIT_REPO }  else { "toolkit" }
$TOOLKIT_REF   = if ($env:TOOLKIT_REF)   { $env:TOOLKIT_REF }   else { "main" }
$RAW_BASE = "https://raw.githubusercontent.com/$TOOLKIT_OWNER/$TOOLKIT_REPO/$TOOLKIT_REF"
$ComponentPath = "terminal/oh-my-posh"

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
$InstallDir = Join-Path $ToolkitHome "terminal/oh-my-posh"

Write-Host "==> Installing Oh My Posh"

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Host "    oh-my-posh already installed"
} elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "    installing oh-my-posh via winget..."
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements
} else {
    Write-Warning "winget not found. Install oh-my-posh manually: https://ohmyposh.dev/docs/installation/windows"
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Get-ToolkitFile -Relative "config.omp.json" -Dest (Join-Path $InstallDir "config.omp.json")
Write-Host "    theme installed: $InstallDir\config.omp.json"

$MarkerStart = "# >>> toolkit:oh-my-posh >>>"
$MarkerEnd   = "# <<< toolkit:oh-my-posh <<<"
$TerminalMarkerStart = "# >>> toolkit:terminal >>>"

$candidateProfiles = @()
if ($PROFILE) {
    if ($PROFILE.CurrentUserAllHosts)     { $candidateProfiles += $PROFILE.CurrentUserAllHosts }
    if ($PROFILE.CurrentUserCurrentHost) { $candidateProfiles += $PROFILE.CurrentUserCurrentHost }
    if ($PROFILE.AllUsersAllHosts)        { $candidateProfiles += $PROFILE.AllUsersAllHosts }
    if ($PROFILE.AllUsersCurrentHost)    { $candidateProfiles += $PROFILE.AllUsersCurrentHost }
}
$candidateProfiles += (Join-Path $HOME "Documents\PowerShell\profile.ps1")
$candidateProfiles += (Join-Path $HOME "Documents\PowerShell\Microsoft.PowerShell_profile.ps1")
$candidateProfiles += (Join-Path $HOME "Documents\WindowsPowerShell\profile.ps1")
$candidateProfiles += (Join-Path $HOME "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
$candidateProfiles += (Join-Path $HOME ".config/powershell/profile.ps1")
$candidateProfiles += (Join-Path $HOME ".config/powershell/Microsoft.PowerShell_profile.ps1")

$candidateProfiles = $candidateProfiles | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$alreadyWiredFile = $null
$alreadyWiredReason = $null
$ompBlockFile = $null

$ompPattern = "(?s)" + [regex]::Escape($MarkerStart) + ".*?" + [regex]::Escape($MarkerEnd) + "\r?\n?"

foreach ($prof in $candidateProfiles) {
    $content = Get-Content -Path $prof -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { continue }

    if ($content -match [regex]::Escape($TerminalMarkerStart)) {
        $alreadyWiredFile = $prof
        $alreadyWiredReason = "toolkit:terminal"
        break
    }

    if ($content -match [regex]::Escape($MarkerStart)) {
        $ompBlockFile = $prof
    }

    $stripped = [regex]::Replace($content, $ompPattern, "")
    if ($stripped -match "oh-my-posh\s+init") {
        $alreadyWiredFile = $prof
        $alreadyWiredReason = "manual"
        break
    }
}

if ($alreadyWiredFile) {
    if ($alreadyWiredReason -eq "toolkit:terminal") {
        Write-Host "    oh-my-posh already wired via toolkit:terminal in $alreadyWiredFile"
    } else {
        Write-Host "    oh-my-posh already wired manually in $alreadyWiredFile"
    }
} else {
    $targetProfile = if ($ompBlockFile) {
        $ompBlockFile
    } elseif ($PROFILE -and $PROFILE.CurrentUserAllHosts) {
        $PROFILE.CurrentUserAllHosts
    } elseif ($PROFILE) {
        $PROFILE.ToString()
    } else {
        Join-Path $HOME "Documents\PowerShell\profile.ps1"
    }

    $profileDir = Split-Path $targetProfile
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    if (-not (Test-Path $targetProfile)) {
        New-Item -ItemType File -Force -Path $targetProfile | Out-Null
    }

    $content = Get-Content -Path $targetProfile -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { $content = "" }

    if (-not (Test-Path "$targetProfile.toolkit-backup") -and (Test-Path $targetProfile) -and ((Get-Item $targetProfile).Length -gt 0)) {
        Copy-Item $targetProfile "$targetProfile.toolkit-backup" -Force
        Write-Host "    backed up existing profile to $targetProfile.toolkit-backup"
    }

    Write-Host "==> Wiring `$PROFILE"

    $stripped = [regex]::Replace($content, $ompPattern, "")

    $block = @"
$MarkerStart
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "`$HOME/.config/toolkit/terminal/oh-my-posh/config.omp.json" | Invoke-Expression
}
$MarkerEnd
"@

    $newContent = if ($stripped.Trim()) { $stripped.TrimEnd() + "`r`n`r`n" + $block + "`r`n" } else { $block + "`r`n" }
    Set-Content -Path $targetProfile -Value $newContent -NoNewline
    Write-Host "    prompt init wired in $targetProfile"
}

Write-Host "==> Oh My Posh component installed."
Write-Host "    restart PowerShell or run: . `$PROFILE"
