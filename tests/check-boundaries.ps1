param([switch]$Quiet)

$ErrorActionPreference = 'Stop'

function Find-BoundaryViolations([string]$Name, [string]$Source) {
    if ($Source -match '(?i)\bOnClipboardChange\b|\bClipboardAll\b') { 'Clipboard monitoring or snapshots' }
    if ($Name -ne 'clipboard.ahk' -and $Source -match '\bA_Clipboard\b') { 'Clipboard access outside adapter' }
    if ($Name -ne 'accounting-hotkeys.ahk' -and $Source -match '\b(?:SendText|SendEvent|SendInput|ControlSend|ControlSendText)\s*\(') { 'Typing outside immediate hotkeys' }
    if ($Name -eq 'snippets.ahk' -and $Source -match '\b(?:FileAppend|FileCopy|FileDelete|FileMove|FileSetAttrib|FileSetTime|IniWrite|RawWrite)\s*\(') { 'Snippet loader writes data' }
}

# Positive controls show that each guard rejects the boundary it claims to check.
$vectors = @(
    @('picker.ahk', 'OnClipboardChange(Watch)'),
    @('picker.ahk', 'text := A_Clipboard'),
    @('picker.ahk', 'SendText(text)'),
    @('snippets.ahk', 'handle.RawWrite(bytes)')
)
foreach ($vector in $vectors) {
    if (@(Find-BoundaryViolations $vector[0] $vector[1]).Count -eq 0) { throw 'Boundary positive control failed.' }
}
if (@(Find-BoundaryViolations 'clipboard.ahk' 'A_Clipboard := text').Count -ne 0) { throw 'Clipboard adapter control failed.' }

$root = Split-Path -Parent $PSScriptRoot
$names = @('accounting-hotkeys.ahk', 'dates.ahk', 'text.ahk', 'identifiers.ahk', 'clipboard.ahk', 'snippets.ahk', 'commands.ahk', 'picker.ahk')
foreach ($name in $names) {
    $source = Get-Content -LiteralPath (Join-Path $root $name) -Raw
    $violations = @(Find-BoundaryViolations $name $source)
    if ($violations.Count -gt 0) { throw ($name + ': ' + ($violations -join '; ')) }
}
if (-not $Quiet) { Write-Output 'Production boundaries and positive controls verified' }
