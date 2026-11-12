# Changelog

All notable changes to this repository are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions will follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Numbers in brackets are pull requests.

## [Unreleased]

No release has been tagged yet. This section lists everything on `main` since the first commit on 6 October 2026.

### Added

- 4 typing shortcuts: Insert types the selected financial-year end, Ctrl + Alt + D today's date, Ctrl + Alt + Q the selected quarter end and Ctrl + Alt + Y the financial-year label. `config.ini`, copied from `config.example.ini` on the first run, sets the financial year, quarter, shortcut keys and the applications the shortcuts work in.
- A copy-only command picker, off until `Picker=` is set under `[Hotkeys]`. It searches commands by name, category, identifier and snippet text, previews each result and copies only the previewed text, asking first when a cell begins with `=`, `+`, `-` or `@` (#1, #6).
- Financial-year and quarter starts, ends, ranges, ISO dates and filename labels; ABN and ACN formatting with a format and checksum report; text clean-up, numbering, sorting and deduplication; CSV, tab-separated and quoted-list output (#1).
- 12 editable draft snippets for records requests, reconciliation workpapers, journal support notes and review queries, with whitelisted date tokens. Local snippets go in `snippets.local` (#1).
- Amount commands in whole cents: clean, format and total pasted amounts, and work out 10% GST on GST-inclusive or GST-exclusive amounts, rounding exact half cents away from zero (#7).
- Month-end lists, the financial year and quarter of a date, and the days between 2 dates (#7).
- `DateOffset`, `DueDate` and `AgeingBucket` for date arithmetic, payment terms and ageing; `DurationHours` for decimal hours between 2 times on one day; `DifferenceCheck` for divide-by-9 and half-amount hints on an out-of-balance difference (#45).
- `BusinessDueDate` moves a due date off a weekend or public holiday, using the ATO's holiday tables for 1 July 2026 to 30 June 2027 and the `[Holidays] State` setting. It replaces `NextWeekday`, which skipped weekends only.
- Library helpers that another script can include without starting the shortcuts or reading the clipboard. See [library helpers](docs/library.md).
- The [command catalogue](docs/commands.md), with each command's input rules and limits (#20).
- 1,000 reproducible generated-input cases against the native helpers, with fixed seeds (#14).
- Workflow checks: CodeQL and zizmor scan the workflows, and actionlint and shellcheck lint them (#12, #36, #43). A tag-triggered release workflow tests the tagged commit, packages its source and creates signed build provenance for a maintainer to verify and publish (#12, #38).
- OpenSSF Scorecard (#11), Dependabot for pinned actions (#2, #15, #30), a vulnerability reporting policy (#13), `CITATION.cff` and `llms.txt` (#5), and issue forms that refuse taxpayer identifiers and confidential files (#44).
- `winget` install command in the README, and [what the script reads, types and stores](docs/it-review.md) for a firm's IT reviewer.

### Changed

- The licence is the [Ryan Duguid Public Attribution Licence 1.0](LICENSE): FSL-1.1-ALv2 with a public attribution condition (#42). `main` was MIT, then Apache-2.0 (#8), then FSL-1.1-ALv2 (#22); copies made available under an earlier licence keep it. Source files carry copyright and SPDX headers (#41), and `AGENTS.md` asks AI agents to keep the notices when reusing the code (#39, #40).
- The source-boundary check refuses every AutoHotkey input function outside the 4 typing shortcuts, in any call form, and scans every root `.ahk` file (#47).

### Fixed

- The picker reads the clipboard back after a copy and reports 'Copy not confirmed' when another program changed it (#37).

README badges, banners and house style (#3, #9, #10, #17, #18, #19, #21, #23, #26, #27, #28, #29, #33, #34, #35), action updates (#4, #16, #24, #31, #32, #46) and an easter egg (#25) complete the history.
