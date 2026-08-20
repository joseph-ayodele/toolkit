# Toolkit — Oh My Posh component installer (Windows).
#
# Installs the oh-my-posh binary (via winget, if missing) and the
# Toolkit's Catppuccin Latte theme to
# $HOME/.config/toolkit/terminal/oh-my-posh/. Safe to rerun: it skips
# the binary install if already present and always refreshes the
# theme file.
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

Write-Host "==> Oh My Posh component installed."
