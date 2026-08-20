# Toolkit — PowerShell aliases
#
# Managed by Toolkit. Add personal aliases in your own profile, not
# here — reruns of the installer overwrite this file.

function ll { Get-ChildItem @args | Format-Table -AutoSize }
function la { Get-ChildItem -Force @args | Format-Table -AutoSize }
function '..' { Set-Location .. }
function '...' { Set-Location ../.. }

# gc/gl/gp/gs collide with PowerShell's built-in aliases (Get-Content,
# Get-Location, Get-ItemProperty, Get-Service); aliases win over
# functions in PowerShell's command resolution order, so those must be
# removed before the git shortcuts below can take effect.
Remove-Item -Path Alias:gc, Alias:gl, Alias:gp, Alias:gs -Force -ErrorAction SilentlyContinue

Set-Alias -Name g -Value git
function gs { git status @args }
function ga { git add @args }
function gc { git commit @args }
function gco { git checkout @args }
function gb { git branch @args }
function gd { git diff @args }
function gl { git log --oneline --graph --decorate @args }
function gp { git push @args }
function gpl { git pull @args }

if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls { eza @args }
    function ll { eza -lh @args }
    function la { eza -lAh @args }
    function lt { eza --tree @args }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias -Name cat -Value bat
}

function reload { . $PROFILE }
