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

$MarkerStart = "# >>> toolkit:terminal >>>"
$MarkerEnd   = "# <<< toolkit:terminal <<<"
$OmpMarkerStart = "# >>> toolkit:oh-my-posh >>>"
$OmpMarkerEnd   = "# <<< toolkit:oh-my-posh <<<"
$ompPattern     = "(?s)" + [regex]::Escape($OmpMarkerStart) + ".*?" + [regex]::Escape($OmpMarkerEnd) + "\r?\n?"

$ProfilePath = if ($PROFILE -and $PROFILE.CurrentUserAllHosts) {
    $PROFILE.CurrentUserAllHosts
} elseif ($PROFILE) {
    $PROFILE.ToString()
} else {
    Join-Path $HOME "Documents\PowerShell\profile.ps1"
}

# Clean up standalone toolkit:oh-my-posh blocks from other profile files
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

foreach ($prof in $candidateProfiles) {
    if ($prof -ne $ProfilePath) {
        $otherContent = Get-Content -Path $prof -Raw -ErrorAction SilentlyContinue
        if ($otherContent -and $otherContent -match [regex]::Escape($OmpMarkerStart)) {
            $cleaned = [regex]::Replace($otherContent, $ompPattern, "")
            Set-Content -Path $prof -Value $cleaned.TrimEnd() -NoNewline
            Write-Host "    removed standalone oh-my-posh block from $prof (now managed via toolkit:terminal)"
        }
    }
}

Write-Host "==> Wiring `$PROFILE"

$ProfileDir = Split-Path $ProfilePath
New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
if (-not (Test-Path $ProfilePath)) {
    New-Item -ItemType File -Force -Path $ProfilePath | Out-Null
}

$content = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
if ($null -eq $content) { $content = "" }

if (-not (Test-Path "$ProfilePath.toolkit-backup") -and (Test-Path $ProfilePath) -and ((Get-Item $ProfilePath).Length -gt 0)) {
    Copy-Item $ProfilePath "$ProfilePath.toolkit-backup" -Force
    Write-Host "    backed up existing profile to $ProfilePath.toolkit-backup"
}

$pattern = "(?s)" + [regex]::Escape($MarkerStart) + ".*?" + [regex]::Escape($MarkerEnd) + "\r?\n?"
$stripped = [regex]::Replace($content, $pattern, "")
$stripped = [regex]::Replace($stripped, $ompPattern, "")

$block = @"
$MarkerStart
if (Test-Path "`$HOME/.config/toolkit/terminal/powershell/toolkit.ps1") { . "`$HOME/.config/toolkit/terminal/powershell/toolkit.ps1" }
$MarkerEnd
"@

$newContent = if ($stripped.Trim()) { $stripped.TrimEnd() + "`r`n`r`n" + $block + "`r`n" } else { $block + "`r`n" }
Set-Content -Path $ProfilePath -Value $newContent -NoNewline

Write-Host "==> PowerShell component installed."
Write-Host "    restart PowerShell or run: . `$PROFILE"
