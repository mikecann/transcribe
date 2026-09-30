# Shared only by this repo's installer, uninstaller and helper tests.
$VideoExtensions = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.webm', '.m4v', '.mpg', '.mpeg', '.ts', '.mts', '.m2ts', '.flv', '.f4v')

function Write-BatStub {
    param([string]$Content, [string]$ToolsDir, [string]$RepoDir)
    # ASCII is required for CMD. Fail clearly instead of silently mangling a path.
    if ($Content -match '[^\x00-\x7F]' -or $RepoDir -match '[^\x00-\x7F]') {
        throw 'Clone transcribe to a path containing only ASCII characters for the Windows launcher.'
    }
    Set-Content -LiteralPath (Join-Path $ToolsDir 'transcribe.bat') -Value $Content -Encoding ASCII
    $bashContent = @'
#!/usr/bin/env bash
# transcribe clone: __REPO_DIR__
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/transcribe.bat" "$@"
'@.Replace('__REPO_DIR__', $RepoDir)
    Set-Content -LiteralPath (Join-Path $ToolsDir 'transcribe') -Value $bashContent -Encoding ASCII
}

# PNG-in-ICO preserves alpha transparency, unlike GetHicon/Icon.FromHandle.
function ConvertTo-Ico($pngPath, $icoPath) {
    $pngBytes = [System.IO.File]::ReadAllBytes($pngPath)
    $stream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]16); $writer.Write([byte]16); $writer.Write([byte]0)
        $writer.Write([byte]0); $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

function Set-MikesToolsRoot($rootKey, $icon) {
    # Other repos share this key. Leave an existing root and its children intact.
    if (-not (Test-Path -LiteralPath $rootKey)) {
        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -LiteralPath $rootKey -Name 'MUIVerb' -Value "Mike's Tools"
        Set-ItemProperty -LiteralPath $rootKey -Name 'SubCommands' -Value ''
        Set-ItemProperty -LiteralPath $rootKey -Name 'Icon' -Value $icon
    }
}

function Add-MikesVerb($rootKey, $verbName, $label, $icon, $command) {
    $verbKey = "$rootKey\shell\$verbName"
    $cmdKey = "$verbKey\command"
    if (-not (Test-Path -LiteralPath $cmdKey)) {
        New-Item -Path $cmdKey -Force | Out-Null
    }
    Set-ItemProperty -LiteralPath $verbKey -Name 'MUIVerb' -Value $label
    Set-ItemProperty -LiteralPath $verbKey -Name 'Icon' -Value $icon
    Set-ItemProperty -LiteralPath $cmdKey -Name '(Default)' -Value $command
}

function Remove-TranscribeVerbs($rootKey) {
    foreach ($verb in @('Transcribe', 'TranscribeSpeakers')) {
        $verbKey = "$rootKey\shell\$verb"
        if (Test-Path -LiteralPath $verbKey) {
            Remove-Item -LiteralPath $verbKey -Recurse -Force
        }
    }
}
