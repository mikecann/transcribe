# Model-free helper checks, including preservation of another tool's registry verb.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'install-lib.ps1')
function Assert($condition, $message) { if (-not $condition) { throw $message } }
$testDir = Join-Path ([IO.Path]::GetTempPath()) ('transcribe-install-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $testDir | Out-Null
try {
    $content = "@echo off`ncall `"C:\my clone\transcribe.bat`" %*"
    Write-BatStub -ToolsDir $testDir -RepoDir 'C:\my clone' -Content $content
    $bytes = [IO.File]::ReadAllBytes((Join-Path $testDir 'transcribe.bat'))
    Assert (-not ($bytes | Where-Object { $_ -gt 127 })) 'Batch stub must be ASCII.'
    Assert ((Get-Content (Join-Path $testDir 'transcribe.bat') -Raw).Contains($content)) 'Stub must preserve quoted clone paths and arguments.'
    Assert ((Get-Content (Join-Path $testDir 'transcribe') -Raw).Contains('exec "$SCRIPT_DIR/transcribe.bat" "$@"')) 'Git Bash wrapper must forward arguments.'
    $ico = Join-Path $testDir 'film.ico'
    $png = Join-Path $PSScriptRoot 'icons/film.png'
    ConvertTo-Ico $png $ico
    $icoBytes = [IO.File]::ReadAllBytes($ico)
    $pngBytes = [IO.File]::ReadAllBytes($png)
    Assert ([BitConverter]::ToUInt16($icoBytes, 2) -eq 1) 'ICO must have icon type.'
    Assert ([BitConverter]::ToUInt32($icoBytes, 18) -eq 22) 'ICO PNG offset must be 22.'
    Assert ($icoBytes.Length -eq $pngBytes.Length + 22) 'ICO must preserve complete PNG data.'

    if ($env:OS -eq 'Windows_NT') {
        # A unique registry branch never touches the user's real context menus.
        $root = 'HKCU:\Software\transcribe-installer-test-' + [guid]::NewGuid()
        try {
            Set-MikesToolsRoot $root $ico
            Add-MikesVerb $root 'OtherTool' 'Other tool' $ico 'other-command'
            Set-MikesToolsRoot $root $ico
            Assert (Test-Path "$root\shell\OtherTool\command") 'Reinstall must preserve other tools.'
            Add-MikesVerb $root 'Transcribe' 'Transcribe Video' $ico 'transcribe-command'
            Add-MikesVerb $root 'TranscribeSpeakers' 'Transcribe with Speakers' $ico 'speaker-command'
            Remove-TranscribeVerbs $root
            Assert (Test-Path "$root\shell\OtherTool\command") 'Uninstall must preserve other tools.'
            Assert (Test-Path $root) 'Uninstall must preserve the shared root.'
            Assert (-not (Test-Path "$root\shell\Transcribe")) 'Uninstall must remove Transcribe.'
            Assert (-not (Test-Path "$root\shell\TranscribeSpeakers")) 'Uninstall must remove TranscribeSpeakers.'
            Remove-TranscribeVerbs $root
        } finally {
            if (Test-Path $root) { Remove-Item $root -Recurse -Force }
        }
    } else {
        Write-Host 'Registry checks require Windows; stub and icon checks ran here.'
    }
    Write-Host 'Installer helper checks passed.'
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
