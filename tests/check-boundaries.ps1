# Copyright 2026 Ryan Duguid
# SPDX-License-Identifier: LicenseRef-Duguid-Public-Attribution-1.0

param([switch]$Quiet)

$ErrorActionPreference = 'Stop'

# AutoHotkey v2 functions that type, paste, click or send window messages
# (https://www.autohotkey.com/docs/v2/lib/). Only the 4 typing shortcuts in
# accounting-hotkeys.ahk may use one, and only SendText.
$inputFunctions = @(
    'Send', 'SendText', 'SendInput', 'SendPlay', 'SendEvent', 'ControlSend', 'ControlSendText',
    'ControlSetText', 'EditPaste', 'ControlClick', 'Click', 'MouseClick', 'MouseClickDrag', 'MouseMove',
    'PostMessage', 'SendMessage', 'Hotstring'
)

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
    @('snippets.ahk', 'handle.RawWrite(bytes)'),
    @('picker.ahk', 'SendText text'),
    @('picker.ahk', 'typist := SendText'),
    @('accounting-hotkeys.ahk', 'Send(text)'),
    @('picker.ahk', 'DllCall("user32\keybd_event", "UChar", 0x56, "UChar", 0, "UInt", 0, "Ptr", 0)'),
    @('picker.ahk', 'DllCall("SendInput", "UInt", 1, "Ptr", inputs, "Int", size)'),
    @('picker.ahk', ':*:fye::30/06/2026')
)
foreach ($function in $inputFunctions) {
    $vectors += , @('picker.ahk', ($function + '(text)'))
}
foreach ($vector in $vectors) {
    if (@(Find-BoundaryViolations $vector[0] $vector[1]).Count -eq 0) { throw ('Boundary positive control failed: ' + $vector[0] + ': ' + $vector[1]) }
}
if (@(Find-BoundaryViolations 'clipboard.ahk' 'A_Clipboard := text').Count -ne 0) { throw 'Clipboard adapter control failed.' }
if (@(Find-BoundaryViolations 'accounting-hotkeys.ahk' 'SendText(text)').Count -ne 0) { throw 'Typing shortcut control failed.' }
if (@(Find-BoundaryViolations 'picker.ahk' 'button.OnEvent("Click", handler)').Count -ne 0) { throw 'Picker event control failed.' }

$root = Split-Path -Parent $PSScriptRoot
$names = @('accounting-hotkeys.ahk', 'dates.ahk', 'text.ahk', 'identifiers.ahk', 'clipboard.ahk', 'snippets.ahk', 'commands.ahk', 'picker.ahk', 'amounts.ahk')
foreach ($name in $names) {
    $source = Get-Content -LiteralPath (Join-Path $root $name) -Raw
    $violations = @(Find-BoundaryViolations $name $source)
    if ($violations.Count -gt 0) { throw ($name + ': ' + ($violations -join '; ')) }
}
if (-not $Quiet) { Write-Output 'Production boundaries and positive controls verified' }
