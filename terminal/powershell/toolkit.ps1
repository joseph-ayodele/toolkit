# Toolkit — PowerShell profile
#
# Managed by Toolkit's terminal/powershell installer. Local
# customizations belong in your own profile, not here — reruns of the
# installer overwrite this file.

$script:ToolkitHome = if ($env:TOOLKIT_HOME) { $env:TOOLKIT_HOME } else { Join-Path $HOME ".config/toolkit" }
$script:ToolkitPowerShellDir = Join-Path $ToolkitHome "terminal/powershell"

# --- History -----------------------------------------------------------------
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -MaximumHistoryCount 50000
    Set-PSReadLineOption -PredictionSource History
}

# --- Prompt (Oh My Posh) --------------------------------------------------------
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config (Join-Path $ToolkitHome "terminal/oh-my-posh/config.omp.json") | Invoke-Expression
}

# --- Aliases & functions ---------------------------------------------------------
$aliasesPath = Join-Path $ToolkitPowerShellDir "aliases.ps1"
$functionsPath = Join-Path $ToolkitPowerShellDir "functions.ps1"
if (Test-Path $aliasesPath) { . $aliasesPath }
if (Test-Path $functionsPath) { . $functionsPath }
