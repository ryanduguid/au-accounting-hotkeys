# Copyright 2026 Ryan Duguid
# SPDX-License-Identifier: Apache-2.0

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# The README's Start steps name the release zip; it must be the version CITATION.cff declares.
$citation = Get-Content -LiteralPath (Join-Path $root 'CITATION.cff') -Raw
if ($citation -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)\s*$') { throw 'CITATION.cff declares no version.' }
$expected = 'au-accounting-hotkeys-v' + $Matches[1] + '.zip'
$readme = Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw
$names = @([regex]::Matches($readme, 'au-accounting-hotkeys-v[^\s`]*\.zip') | ForEach-Object Value)
if ($names.Count -eq 0) { throw ('README.md does not name ' + $expected + '.') }
$wrong = @($names | Where-Object { $_ -cne $expected } | Sort-Object -Unique)
if ($wrong.Count -gt 0) { throw ('README.md names ' + ($wrong -join ', ') + '; CITATION.cff declares ' + $expected + '.') }
