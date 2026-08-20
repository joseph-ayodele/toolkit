# Toolkit — PowerShell functions
#
# Managed by Toolkit. Add personal functions in your own profile, not
# here — reruns of the installer overwrite this file.

function mkcd {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location $Path
}

function up {
    param([int]$Levels = 1)
    $path = "."
    for ($i = 0; $i -lt $Levels; $i++) { $path = Join-Path $path ".." }
    Set-Location $path
}

function extract {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Error "extract: '$Path' is not a file"
        return
    }
    $dest = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    switch -Regex ($Path) {
        '\.zip$'      { Expand-Archive -Path $Path -DestinationPath $dest }
        '\.tar\.gz$'  { tar xzf $Path }
        '\.tgz$'      { tar xzf $Path }
        '\.tar$'      { tar xf $Path }
        '\.7z$'       { 7z x $Path }
        default       { Write-Error "extract: unsupported archive type: $Path" }
    }
}

function toolkit-update {
    $owner = if ($env:TOOLKIT_OWNER) { $env:TOOLKIT_OWNER } else { "joseph-ayodele" }
    $repo  = if ($env:TOOLKIT_REPO)  { $env:TOOLKIT_REPO }  else { "toolkit" }
    $ref   = if ($env:TOOLKIT_REF)   { $env:TOOLKIT_REF }   else { "main" }
    Invoke-RestMethod "https://raw.githubusercontent.com/$owner/$repo/$ref/terminal/install.ps1" | Invoke-Expression
}
