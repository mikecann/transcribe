# Remove only transcribe. Keep shared PATH entries, binaries, models and menu roots.
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Run uninstall.ps1 on Windows.' }
. (Join-Path $PSScriptRoot 'install-lib.ps1')
$stub = 'C:\dev\tools\transcribe.bat'
if (Test-Path -LiteralPath $stub) {
    $expectedCall = 'call "' + $PSScriptRoot + '\transcribe.bat" %*'
    if (-not (Get-Content -LiteralPath $stub -Raw).Contains($expectedCall)) {
        Write-Warning 'The installed launcher points at another clone. Run its uninstaller instead.'
        return
    }
    Remove-Item -LiteralPath $stub -Force
}
$bashStub = 'C:\dev\tools\transcribe'
if (Test-Path -LiteralPath $bashStub) {
    if ((Get-Content -LiteralPath $bashStub -Raw).Contains("# transcribe clone: $PSScriptRoot")) {
        Remove-Item -LiteralPath $bashStub -Force
    }
}
foreach ($ext in $VideoExtensions) {
    Remove-TranscribeVerbs "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools"
}
$filmIco = Join-Path $env:LOCALAPPDATA 'transcribe\icons\transcribe.ico'
if (Test-Path -LiteralPath $filmIco) { Remove-Item -LiteralPath $filmIco -Force }
# mikes-tools.ico may still be referenced by a shared root, so keep it.
Write-Host 'Removed transcribe launchers and Explorer verbs. Shared tools and settings are untouched.' -ForegroundColor Green
