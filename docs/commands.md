# Command catalogue

Commands copy reviewed text through the picker. The four default date hotkeys also type their results directly. Examples below use a financial year ending in 2026, Q4 and, for current-date commands, a fixed example clock of 6 October 2026.

Search uses literal, case-insensitive terms across the identifier, label and category. Every term must match. Search accepts up to 128 UTF-16 code units. Selecting an input command clears previously loaded text; it requires a new explicit load or manual input.

## Selected financial year and quarter

| Identifier | Result | Example |
| --- | --- | --- |
| `YearEnd` | Financial-year end | `30/06/2026` |
| `YearStart` | Financial-year start | `01/07/2025` |
| `YearRange` | Financial-year range | `01/07/2025 to 30/06/2026` |
| `FinancialYear` | Financial-year label | `2025-26` |
| `FYHeading` | Workpaper heading | `For the year ended 30/06/2026` |
| `FYFileLabel` | Filename label | `FY2026_20260630` |
| `YearEndISO` | ISO end date | `2026-06-30` |
| `YearStartISO` | ISO start date | `2025-07-01` |
| `YearEndFile` | Compact end date | `20260630` |
| `PreviousYearEnd` | Previous year end | `30/06/2025` |
| `QuarterEnd` | Selected quarter end | `30/06/2026` |
| `QuarterStart` | Selected quarter start | `01/04/2026` |
| `QuarterRange` | Selected quarter range | `01/04/2026 to 30/06/2026` |
| `QuarterLabel` | FY and quarter label | `FY 2025-26 Q4` |
| `QuarterHeading` | Workpaper heading | `For the quarter ended 30/06/2026` |
| `QuarterEndISO` | ISO quarter end | `2026-06-30` |
| `QuarterEndFile` | Compact quarter end | `20260630` |

Q1 covers July to September, Q2 October to December, Q3 January to March and Q4 April to June. These are date labels for a 30 June financial year. They do not calculate lodgement dates or support substituted accounting periods.

## Computer's local date

| Identifier | Example |
| --- | --- |
| `Today` | `06/10/2026` |
| `TodayISO` | `2026-10-06` |
| `TodayFile` | `20261006` |
| `Yesterday` | `05/10/2026` |
| `Tomorrow` | `07/10/2026` |

The picker captures the date when producing a preview. Copy uses the stored result, including across midnight. There is no business-day or public-holiday adjustment.

## One input date

Accepts exactly `dd/MM/yyyy`, `yyyy-MM-dd` or `yyyyMMdd`, with a calendar year from 1601 to 9999. Leading and trailing spaces, tabs or line endings are removed. Two-digit years, non-padded dates, times, impossible calendar dates and multiple values are rejected. The entire input has a 64-character limit.

| Identifier | Input | Output |
| --- | --- | --- |
| `DateAU` | `2024-02-29` | `29/02/2024` |
| `DateISO` | `29/02/2024` | `2024-02-29` |
| `DateFile` | `29/02/2024` | `20240229` |
| `MonthStart` | `29/02/2024` | `01/02/2024` |
| `MonthEnd` | `01/02/2024` | `29/02/2024` |
| `MonthRange` | `29/02/2024` | `01/02/2024 to 29/02/2024` |
| `MonthLabel` | `29/02/2024` | `February 2024` |

Month commands use the input date's calendar month. They do not infer an accounting month from the selected quarter.

## Identifiers

Accepts digits and ordinary spaces only, up to 64 characters. There must be exactly 11 ABN digits or 9 ACN digits after removing spaces. Formatting preserves all digits; it does not correct a failed checksum. The ABN check additionally rejects a leading-zero number under the library's format policy.

| Identifier | Input | Result |
| --- | --- | --- |
| `ABNFormat` | `10000000000` | `10 000 000 000` |
| `ABNCheck` | `10000000000` | Format/checksum report |
| `ACNFormat` | `001234564` | `001 234 564` |
| `ACNCheck` | `001234565` | Format/checksum failure report |

These are fabricated checksum vectors, with no registration claim. Reports always state `Registry/existence/status: not checked`. They cannot establish identity, registration, active status or GST status. See the [primary sources](resources.md).

## Text and filenames

Input and output are limited to 32,768 UTF-16 code units. NUL, backspace, DEL and unsupported ASCII control characters are rejected. Tabs and line endings are accepted where the command allows them. Commands reject an empty transformed result.

| Identifier | Behaviour |
| --- | --- |
| `TrimText` | Removes surrounding spaces, tabs, line endings and non-breaking spaces. |
| `TrimLines` | Trims spaces, tabs and non-breaking spaces at each line's ends; preserves blank lines. |
| `CollapseSpaces` | Trims each line and collapses repeated horizontal whitespace; preserves line boundaries. |
| `SingleLine` | Collapses whitespace and joins text into one trimmed line. |
| `LineEndings` | Converts CRLF and CR to LF. |
| `UniqueLines` | Trims lines, discards blank lines and keeps the first exact-case occurrence. |
| `SortLines` | Trims lines, discards blank lines and sorts case sensitively; preserves duplicates. |
| `Uppercase` | Converts text to uppercase. |
| `Lowercase` | Converts text to lowercase. |
| `CSVRow` | Trims non-empty lines into a comma-separated row; quotes fields containing commas or quotes and doubles embedded quotes. |
| `TSVRow` | Trims non-empty lines into a tab-separated row; rejects input lines that already contain tabs. |
| `Filename` | Joins text into one line, replaces forbidden punctuation with underscores, removes trailing spaces/full stops and prefixes reserved Windows device names with an underscore. Limits the result to 200 characters. |

CSV and TSV output can contain formula-like cells. Copying requires confirmation when detected; the library preserves the preview and does not silently prefix values. Import or paste using the destination application's appropriate text settings.

Filename preparation returns one component as text. It does not inspect paths, create files or guarantee that a name meets every application's naming policy.

## Draft snippets

The 12 bundled drafts cover year-end and quarter records requests, bank reconciliation, receivables, payables, GST, payroll, fixed assets, loans, journal support, transaction queries and a review-query register. Each contains fields to complete. Review the selected period, wording and evidence before using it.

See [custom snippets](../README.md#customise-snippets) for the token list, local folder and limits. Snippets have no script or plug-in execution facility.
