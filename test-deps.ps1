# Fake python to exercise deps.ps1 the way install.ps1 actually calls it: under
# $ErrorActionPreference = 'Stop'. On Windows PowerShell, assigning a native
# command's output to a variable under 'Stop' turns an expected nonzero-exit
# probe (faster_whisper/pyannote.audio, not installed on a fresh machine) into
# a terminating error even with stderr redirected to $null. That previously
# made install.ps1 abort before it could report ffmpeg/faster-whisper-xxl
# status or finish writing stubs - on every fresh machine, since the
# --diarize packages are optional and normally not preinstalled.
$deps = Join-Path $PSScriptRoot 'deps.ps1'

function python {
    if ($args[0] -eq '-c') {
        # Mimic a real Python ImportError: multi-line stderr, exit 1.
        [Console]::Error.WriteLine('Traceback (most recent call last):')
        [Console]::Error.WriteLine("ModuleNotFoundError: No module named 'faster_whisper'")
        $global:LASTEXITCODE = 1
        return
    }
    '3.12.10'
    $global:LASTEXITCODE = 0
}

function Assert($condition, [string]$message) { if (-not $condition) { throw $message } }

$ErrorActionPreference = 'Stop'
$threw = $false
try {
    & $deps *> $null
} catch {
    $threw = $true
}
Assert (-not $threw) 'deps.ps1 must not abort under a Stop caller when the optional --diarize package probes report "not installed yet".'

$global:LASTEXITCODE = 0
Write-Host 'PASS: transcribe dependency check tests'
