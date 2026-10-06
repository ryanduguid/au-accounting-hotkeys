param(
    [string]$AutoHotkey = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe',
    [switch]$UI
)

$ErrorActionPreference = 'Stop'
$runDirectory = Join-Path ([IO.Path]::GetTempPath()) ('au-accounting-hotkeys-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $runDirectory | Out-Null
$stdoutPath = Join-Path $runDirectory 'stdout.txt'
$stderrPath = Join-Path $runDirectory 'stderr.txt'
$testPath = Join-Path $PSScriptRoot 'test.ahk'
$arguments = @('/ErrorStdOut', ('"' + $testPath + '"'))
if ($UI) { $arguments += '--ui' }

try {
    $process = Start-Process -FilePath $AutoHotkey -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    if (-not $process.WaitForExit(20000)) {
        Stop-Process -Id $process.Id
        throw 'AutoHotkey tests exceeded 20 seconds.'
    }
    $process.WaitForExit()
    $stdout = Get-Content -LiteralPath $stdoutPath -Raw
    $stderr = Get-Content -LiteralPath $stderrPath -Raw
    if ($stdout) { Write-Output $stdout.TrimEnd() }
    if ($stderr) { Write-Output $stderr.TrimEnd() }
    if ($process.ExitCode -ne 0) { exit $process.ExitCode }
    if ($stderr -or $stdout -notmatch '^PASS: \d+ checks\s*$') {
        throw 'AutoHotkey did not report a successful test run.'
    }
} finally {
    Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $runDirectory -ErrorAction SilentlyContinue
}
