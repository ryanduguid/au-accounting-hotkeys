# Security checks and release verification

The Windows Check workflow tests the AutoHotkey helpers, input limits, settings,
snippet handling and picker boundaries on x64 and x86. The interactive checks
described in the README still require a Windows desktop.

The Workflow security workflow runs CodeQL's Actions analysis with the extended
security queries and zizmor on pull requests, main-branch pushes and a weekly
schedule. These tools analyse GitHub Actions workflows. They do not analyse
AutoHotkey source or replace its tests. Results appear in the repository's
Security tab.

Report suspected vulnerabilities using the repository's Security policy. Do not
include client records, clipboard contents, personal settings or credentials in
a public issue.

## Tagged releases

The release workflow runs when a maintainer pushes a tag such as `v1.0.0`. It
accepts only `vMAJOR.MINOR.PATCH` tags whose commit is on main's history. It runs
the same x64/x86 library tests and workflow security scans before packaging the
tagged commit. The archive contains tracked source, examples, documentation,
licence and attribution, with no AutoHotkey runtime or compiled executable.
Pull requests exercise the tests, security scans and archive packaging too,
producing an unsigned preview named for the tested commit. They cannot run the
publishing job.

Packaging has read-only repository access. A separate publishing job verifies
the downloaded archive's SHA-256 checksum and creates a GitHub build provenance
attestation. It uploads the ZIP, `SHA256SUMS` and a `.sigstore.json` verification
bundle to a draft release, then publishes it after the uploads succeed. The
publishing job does not check out or execute project source.

This workflow prepares future releases; its presence does not mean a release
has already been published. It does not create tags or overwrite existing
releases. If an upload fails, inspect the draft before attempting a new run.

## Verify a download

For an actual published tag, replace `v1.0.0` below with that exact tag. Download
its ZIP, `SHA256SUMS` and `.sigstore.json` bundle from this repository's Releases
page, keeping them in the same directory. Check the ZIP hash first:

```powershell
Get-FileHash .\au-accounting-hotkeys-v1.0.0.zip -Algorithm SHA256
Get-Content .\SHA256SUMS
```

The displayed ZIP hash must match the corresponding entry in `SHA256SUMS`.
A matching unsigned checksum alone does not establish who published the file.
Use a current GitHub CLI to verify the signed provenance, repository, workflow
and source tag:

```powershell
gh attestation verify .\au-accounting-hotkeys-v1.0.0.zip `
  --bundle .\au-accounting-hotkeys-v1.0.0.sigstore.json `
  --repo ryanduguid/au-accounting-hotkeys `
  --signer-workflow ryanduguid/au-accounting-hotkeys/.github/workflows/release.yml `
  --source-ref refs/tags/v1.0.0
```

Stop if verification fails. A valid attestation identifies the build's source
and workflow; it does not establish that the source is free of defects or that
an accounting result is correct.

## Scorecard limits

Scorecard inspects the default branch and recent project history. Workflow SAST
can improve its SAST result after merge. Signed-release credit needs an actual
published release with its verification bundle. The source ZIP is not a
package-registry publication, and this project has no Scorecard-recognised
AutoHotkey fuzzing integration.

Project age, contributor diversity and independent reviews cannot be created
by configuration files. Best Practices certification requires a separate,
evidence-backed application. The current Scorecard workflow token cannot read
classic branch-protection settings; this is an inconclusive result, not proof
that main is unprotected. Resolving that visibility requires a maintainer's
decision about repository rules or token permissions.
