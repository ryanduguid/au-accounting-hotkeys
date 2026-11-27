# Copyright 2026 Ryan Duguid
# SPDX-License-Identifier: Apache-2.0

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# The README's Start steps name the release zip; it must be the version CITATION.cff declares,
# and CITATION.cff's license-url must match that tag, as release.yml checks.
$citation = Get-Content -LiteralPath (Join-Path $root 'CITATION.cff') -Raw
if ($citation -notmatch '(?m)^version:\s*[''"]?(\d+\.\d+\.\d+)[''"]?\s*$') { throw 'CITATION.cff declares no version.' }
$version = $Matches[1]
$expectedLicenseUrl = "https://github.com/ryanduguid/au-accounting-hotkeys/blob/v$version/LICENSE"
if ($citation -notmatch '(?m)^license-url:\s*[''"]?([^\s''"]+)[''"]?\s*$' -or $Matches[1] -cne $expectedLicenseUrl) {
    throw "CITATION.cff license-url must be $expectedLicenseUrl."
}
$expected = 'au-accounting-hotkeys-v' + $version + '.zip'
$readme = Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw
$names = @([regex]::Matches($readme, 'au-accounting-hotkeys-v[^\s`]*\.zip') | ForEach-Object Value)
if ($names.Count -eq 0) { throw ('README.md does not name ' + $expected + '.') }
$wrong = @($names | Where-Object { $_ -cne $expected } | Sort-Object -Unique)
if ($wrong.Count -gt 0) { throw ('README.md names ' + ($wrong -join ', ') + '; CITATION.cff declares ' + $expected + '.') }

# docs/security.md's 'Verify a download' commands must verify that same release, from this
# repository's release workflow, so they can be pasted as they stand.
$security = Get-Content -LiteralPath (Join-Path $root 'docs/security.md') -Raw
if ($security -notmatch '(?ms)^## Verify a download\r?\n(.*?)(?=^## )') { throw 'docs/security.md has no Verify a download section.' }
$verify = $Matches[1]
$tags = @([regex]::Matches($verify, '\bv\d+\.\d+\.\d+\b') | ForEach-Object Value | Sort-Object -Unique)
if ($tags.Count -ne 1 -or $tags[0] -cne "v$version") {
    throw ('docs/security.md verifies ' + ($tags -join ', ') + '; CITATION.cff declares v' + $version + '.')
}
foreach ($required in @(
        ('.\' + $expected), ('.\au-accounting-hotkeys-v' + $version + '.sigstore.json'),
        '--repo ryanduguid/au-accounting-hotkeys',
        '--signer-workflow ryanduguid/au-accounting-hotkeys/.github/workflows/release.yml',
        ('--source-ref refs/tags/v' + $version))) {
    if (-not $verify.Contains($required)) { throw ('docs/security.md Verify a download lacks ' + $required + '.') }
}
if (-not (Test-Path -LiteralPath (Join-Path $root '.github/workflows/release.yml') -PathType Leaf)) {
    throw 'docs/security.md names .github/workflows/release.yml, which does not exist.'
}
