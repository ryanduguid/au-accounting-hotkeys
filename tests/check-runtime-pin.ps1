# Copyright 2026 Ryan Duguid
# SPDX-License-Identifier: Apache-2.0

# Fails when winget offers a newer AutoHotkey v2 release than the runtime check.yml pins, or when
# README.md names another version. -WingetVersions replaces the winget-pkgs listing, for tests.
param([string[]]$WingetVersions)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$check = Get-Content -LiteralPath (Join-Path $root '.github/workflows/check.yml') -Raw
$pins = @([regex]::Matches($check, 'releases/download/v(\d+\.\d+\.\d+)/AutoHotkey_(\d+\.\d+\.\d+)\.zip'))
if ($pins.Count -ne 1 -or $pins[0].Groups[1].Value -cne $pins[0].Groups[2].Value) {
    throw 'check.yml must download exactly one AutoHotkey_<version>.zip from its own release tag.'
}
$pin = $pins[0].Groups[1].Value
$readme = Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw
if (-not $readme.Contains("checksum-verified AutoHotkey $pin runtimes")) { throw "README.md must name the pinned AutoHotkey $pin runtime." }

if (-not $PSBoundParameters.ContainsKey('WingetVersions')) {
    $headers = @{ Accept = 'application/vnd.github+json' }
    if ($env:GITHUB_TOKEN) { $headers.Authorization = "Bearer $env:GITHUB_TOKEN" }
    $listing = Invoke-RestMethod -Headers $headers -Uri 'https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/a/AutoHotkey/AutoHotkey'
    $WingetVersions = @($listing | ForEach-Object name)
}
# Only stable v2 releases: winget-pkgs also lists v1.1 releases, which this script cannot run under.
$stable = @($WingetVersions | Where-Object { $_ -match '^2\.\d+\.\d+$' } | ForEach-Object { [version]$_ })
if ($stable.Count -eq 0) { throw 'winget lists no stable AutoHotkey v2 release.' }
$latest = ($stable | Sort-Object -Descending)[0]
if ($latest -gt [version]$pin) {
    throw "winget offers AutoHotkey $latest; check.yml pins $pin. Move the pin, its SHA-256 and README.md together."
}
Write-Output "AutoHotkey pin $pin matches winget's latest v2 release, $latest."
