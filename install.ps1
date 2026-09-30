# Install from this clone. No administrator privileges or API key required.
param([switch]$SkipDeps)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Run install.ps1 on Windows. On macOS/Linux use bash install.sh.' }

$RepoDir = $PSScriptRoot
$ToolsDir = 'C:\dev\tools'
. (Join-Path $RepoDir 'install-lib.ps1')
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null

Write-BatStub -ToolsDir $ToolsDir -RepoDir $RepoDir -Content @"
@echo off
setlocal
set "EXEDIR=%~dp0"
call "$RepoDir\transcribe.bat" %*
exit /b %errorlevel%
"@

$iconsOut = Join-Path $env:LOCALAPPDATA 'transcribe\icons'
New-Item -ItemType Directory -Path $iconsOut -Force | Out-Null
$filmIco = Join-Path $iconsOut 'transcribe.ico'
$wrenchIco = Join-Path $iconsOut 'mikes-tools.ico'
ConvertTo-Ico (Join-Path $RepoDir 'icons\film.png') $filmIco
ConvertTo-Ico (Join-Path $RepoDir 'icons\wrench.png') $wrenchIco
foreach ($ext in $VideoExtensions) {
    $root = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools"
    Set-MikesToolsRoot $root $wrenchIco
    Add-MikesVerb $root 'Transcribe' 'Transcribe Video' $filmIco 'cmd.exe /k ""C:\dev\tools\transcribe.bat" "%1""'
    Add-MikesVerb $root 'TranscribeSpeakers' 'Transcribe with Speakers' $filmIco 'cmd.exe /k ""C:\dev\tools\transcribe.bat" "%1" --diarize --model large-v3"'
}

$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$onPath = (($machinePath -split ';') + ($userPath -split ';')) |
    Where-Object { $_.TrimEnd('\') -ieq $ToolsDir.TrimEnd('\') }
if (-not $onPath) {
    $answer = Read-Host "Add '$ToolsDir' to your User PATH? [Y/n]"
    if ($answer -eq '' -or $answer -imatch '^y') {
        $newPath = ((@($userPath, $ToolsDir) | Where-Object { $_ }) -join ';')
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host 'Open a new terminal to use transcribe.' -ForegroundColor Yellow
    }
}
if (-not $SkipDeps) { & (Join-Path $RepoDir 'deps.ps1') }
Write-Host 'Installed transcribe and its two Explorer menu entries.' -ForegroundColor Green
