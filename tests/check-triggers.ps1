# Copyright 2026 Ryan Duguid
# SPDX-License-Identifier: Apache-2.0

param([switch]$Quiet)

$ErrorActionPreference = 'Stop'

# Fails on 2 hotstring collisions in the .ahk files this repository ships under
# snippets and examples (https://www.autohotkey.com/docs/v2/Hotstrings.htm):
# - A duplicate abbreviation. A repeat that differs only by case, or that also
#   differs by the C or ? options, is a hotstring variant, and only the one
#   defined earliest fires when both are eligible. The picker refuses a repeat
#   ignoring case, so any repeat is an error here.
# - An immediate (*) abbreviation that is a prefix of a later one. It fires as
#   soon as its last character is typed, so the later, longer abbreviation can
#   never complete.
# An abbreviation without * waits for an ending character, so a shorter one
# before a longer one does not collide.

function ConvertTo-Triggers([string]$Source) {
    $order = 0
    foreach ($line in ($Source -split "\r?\n")) {
        $match = [regex]::Match($line, '^:([^:]*):((?:[^`:]|`.|:(?!:))+?)::')
        if (-not $match.Success) { continue }
        $order++
        $options = $match.Groups[1].Value
        [pscustomobject]@{
            Order     = $order
            Name      = $match.Groups[2].Value
            Immediate = $options -match '(?i)\*(?!0)'
            Sensitive = $options -match '(?i)C(?!0)'
        }
    }
}

function Find-TriggerCollisions([string]$Source) {
    $triggers = @(ConvertTo-Triggers $Source)
    for ($later = 1; $later -lt $triggers.Count; $later++) {
        for ($earlier = 0; $earlier -lt $later; $earlier++) {
            $first = $triggers[$earlier]; $second = $triggers[$later]
            if ($first.Name -ieq $second.Name) {
                'duplicate abbreviation ' + $second.Name + ' (entry ' + $second.Order + ' repeats entry ' + $first.Order + ')'
            } elseif ($first.Immediate -and $second.Name.Length -gt $first.Name.Length) {
                $comparison = if ($first.Sensitive) { 'Ordinal' } else { 'OrdinalIgnoreCase' }
                if ($second.Name.StartsWith($first.Name, [StringComparison]::$comparison)) {
                    'immediate abbreviation ' + $first.Name + ' (entry ' + $first.Order + ') fires before ' + $second.Name + ' (entry ' + $second.Order + ') can complete'
                }
            }
        }
    }
}

# Positive controls show that each rule rejects what it claims to.
$bad = @(
    ":*:btw::by the way`n:*:btw::back to work",
    ":T:fye::30/06`n:T:FYE::30/06",
    ":*:gst::GST`n::gst::GST again",
    ":*:ab::x`n:*:abc::y",
    ":*:ab::x`n::ABC::y",
    ":*C:ab::x`n:T:abc::y"
)
foreach ($source in $bad) {
    if (@(Find-TriggerCollisions $source).Count -eq 0) { throw ('Trigger positive control failed: ' + $source) }
}
$good = @(
    ":T:ab::x`n:T:abc::y",
    ":*:abc::x`n:*:ab::y",
    ":*:ab::x`n:T:b::y",
    ":*C:ab::x`n:T:ABC::y",
    ":*0:ab::x`n:T:abc::y"
)
foreach ($source in $good) {
    if (@(Find-TriggerCollisions $source).Count -ne 0) { throw ('Trigger negative control failed: ' + $source) }
}

$root = Split-Path -Parent $PSScriptRoot
$files = @(foreach ($folder in 'snippets', 'examples') {
    $path = Join-Path $root $folder
    if (Test-Path -LiteralPath $path) { Get-ChildItem -LiteralPath $path -Filter '*.ahk' -File }
})
foreach ($file in $files) {
    $collisions = @(Find-TriggerCollisions (Get-Content -LiteralPath $file.FullName -Raw))
    if ($collisions.Count -gt 0) { throw ($file.Name + ': ' + ($collisions -join '; ')) }
}
if (-not $Quiet) { Write-Output ('Hotstring triggers checked in ' + $files.Count + ' files; positive controls verified') }
