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
| `FYMonthEnds` | The 12 month ends, one per line | `31/07/2025` to `30/06/2026` |
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

The picker captures the date when producing a preview. Copy uses the stored result, including across midnight. These commands make no business-day or public-holiday adjustment.

## One input date

The date parser accepts exactly `dd/MM/yyyy`, `yyyy-MM-dd` or `yyyyMMdd`, with a calendar year from 1601 to 9999. Leading and trailing spaces, tabs or line endings are removed. Two-digit years, non-padded dates, times, impossible calendar dates and multiple values are rejected. The entire input has a 64-character limit.

`PeriodOfDate` accepts dates from 1 July 1899 to 30 June 9999, inclusive. Its derived financial-year ending year must be from 1900 to 9999.

| Identifier | Input | Output |
| --- | --- | --- |
| `DateAU` | `2024-02-29` | `29/02/2024` |
| `DateISO` | `29/02/2024` | `2024-02-29` |
| `DateFile` | `29/02/2024` | `20240229` |
| `MonthStart` | `29/02/2024` | `01/02/2024` |
| `MonthEnd` | `01/02/2024` | `29/02/2024` |
| `MonthRange` | `29/02/2024` | `01/02/2024 to 29/02/2024` |
| `MonthLabel` | `29/02/2024` | `February 2024` |
| `PeriodOfDate` | `15/08/2025` | `FY 2025-26 Q1` |
| `DaysBetween` | `01/07/2025 to 30/06/2026` | `364` |

Month commands use the input date's calendar month. They do not infer an accounting month from the selected quarter. `PeriodOfDate` uses the same 30 June financial year and quarters as the selected-period commands.

`DaysBetween` takes two dates, either on separate lines or joined by `to`, so a copied `YearRange` or `QuarterRange` result works as input. It returns the second date minus the first: the same date gives `0`, and an earlier second date gives a negative number. Add 1 when you need to count both end dates. Input is limited to 200 characters.

## Date arithmetic

These commands use the same date parser and return an Australian date or a label. They do no legal date reasoning: none of them moves a date for a weekend or public holiday unless the command says so.

| Identifier | Input | Output |
| --- | --- | --- |
| `DateOffset` | `31/01/2024 + 1 month` | `29/02/2024` |
| `DateOffset` | `01/03/2024 - 1 day` | `29/02/2024` |
| `DueDate` | `15/01/2026 net 30` | `14/02/2026` |
| `DueDate` | `15/01/2026 30 days after month end` | `02/03/2026` |
| `DueDate` | `15/01/2026 20th of next month` | `20/02/2026` |
| `BusinessDueDate` | `25/12/2026` | `29/12/2026` |
| `AgeingBucket` | `30/04/2026 to 30/06/2026` | `61 to 90 days overdue` |

`DateOffset` takes a date, `+` or `-`, a whole number of up to 5 digits and `days` or `months` (`day` and `month` also work). A month offset keeps the day of the month; when the target month is shorter, the result is that month's last day, as Excel's `EDATE` does. Add 12 months for a year. Input is limited to 64 characters.

`DueDate` takes an invoice date, an optional comma and one of these terms, on the same line or the next, with up to 4 digits for a day count:

- `net N` or `N days`: N days after the invoice date.
- `N days after month end`: N days after the last day of the invoice's month.
- `Nth of next month` (or `of the following month`): that day of the month after the invoice's month. An ordinal suffix is optional but must match its number, so `1nd` is rejected. A month without that day is rejected rather than moved.

Shorthand such as `30 days EOM` is rejected because suppliers read it in more than one way; write the terms out. The due date is not moved off a weekend or public holiday. Input is limited to 100 characters.

`BusinessDueDate` returns the input date when it is a business day, and otherwise the first business day after it. A business day is not a Saturday, Sunday or public holiday. Set `State` under `[Holidays]` in `config.ini` first:

- `ATO` counts a public holiday for the whole of any State or Territory, as the ATO does for lodgment and payment due dates, so `25/09/2026` (the Friday before the AFL Grand Final, Victoria only) gives `28/09/2026`.
- `ACT`, `NSW`, `NT`, `QLD`, `SA`, `TAS`, `VIC` or `WA` counts only that State's or Territory's holidays, so the same date stays `25/09/2026` for `NSW`.

The holidays are the ATO's published tables for 1 July 2026 to 30 June 2027, and the command refuses a date outside that range rather than skipping weekends only. Following the reasoning in [au-fpa-pack's holiday list](https://github.com/ryanduguid/au-fpa-pack/blob/main/pyfpa/au/data/public_holidays.yaml), it counts only days that are public holidays for the whole of a State or Territory. It leaves out King's Birthday (WA) on 28 September 2026 and Melbourne Cup on 3 November 2026, which some regions replace with another day, and Christmas Eve and New Year's Eve, which are holidays from the evening only. The ATO's table moves those 4 days; this command does not, so its date can fall before the ATO's published date. Holiday dates can change during the year; check a result that matters against the official list. Input is limited to 64 characters.

`AgeingBucket` takes the due date and the as-at date, in the same form as `DaysBetween`, and counts days past due: `Current` (on or before the due date), `1 to 30 days overdue`, `31 to 60 days overdue`, `61 to 90 days overdue` or `Over 90 days overdue`. These are 30-day steps from the due date; reports that age by calendar month or from the invoice date can place an amount differently. Input is limited to 200 characters.

## Times

| Identifier | Input | Output |
| --- | --- | --- |
| `DurationHours` | `09:00 to 17:20` | `8.33` |
| `DurationHours` | `09:00 to 17:20 round up 6` | `8.40` |
| `DurationHours` | `09:00 to 17:07 round nearest 15` | `8.00` |

`DurationHours` takes a start and an end time in 24-hour form, from `0:00` to `23:59`, either on separate lines (blank lines between are ignored) or joined by `to` or `-`, and returns decimal hours to 2 places, rounded to the nearest hundredth. The end may be `24:00`. The end must be later than the start: an earlier or equal end time is rejected rather than read as overnight, so split an overnight period at `24:00`. Optional rounding applies to the minutes before conversion: `round up N` rounds up to a multiple of N minutes and `round nearest N` rounds to the nearest multiple, with an exact half rounded up; N is from 1 to 60. Check any rounding against the employment terms or billing policy that applies. Input is limited to 64 characters.

## Identifiers

Accepts digits and ordinary spaces only, up to 64 characters. There must be exactly 11 ABN digits or 9 ACN digits after removing spaces. Formatting preserves all digits; it does not correct a failed checksum. The ABN check additionally rejects a leading-zero number under the library's format policy.

| Identifier | Input | Result |
| --- | --- | --- |
| `ABNFormat` | `10000000000` | `10 000 000 000` |
| `ABNCheck` | `10000000000` | Format/checksum report |
| `ACNFormat` | `001234564` | `001 234 564` |
| `ACNCheck` | `001234565` | Format/checksum failure report |

These are fabricated checksum vectors, with no registration claim. Reports always state `Registry/existence/status: not checked`. They cannot establish identity, registration, active status or GST status. See the [primary sources](resources.md).

## Amounts and GST

Each line holds one Australian dollar amount: an optional leading minus or enclosing brackets for a negative, an optional `$`, at most 12 whole-dollar digits written plain (`1234567`) or with comma groups of three (`1,234,567`), and at most 2 decimal places. Spaces, tabs and non-breaking spaces around the amount are ignored. Any other line is rejected with its line number, and nothing is rounded on input. Text containing unsupported control characters is rejected as a whole, as for every command. `CR` and `DR` suffixes are rejected because a credit is negative in a ledger but a deposit on a bank statement; replace them with an explicit sign.

Calculations use whole cents, with no floating point. Per-line commands keep blank lines as blank lines, so a pasted column stays aligned with its rows. Results are limited to 9,999,999,999,999.99, the largest two-decimal amount within the 15 significant digits Excel keeps for numbers.

| Identifier | Input | Output |
| --- | --- | --- |
| `AmountsClean` | `($1,234.50)` | `-1234.50` |
| `AmountsFormat` | `-1234.5` | `-1,234.50` |
| `AmountsTotal` | `1.10`, `$2.20` and `(0.30)` on three lines | `3.00` |
| `DifferenceCheck` | `18.00` | Divide-by-9 and half-amount hints |
| `GSTInInclusive` | `100.00` | `9.09` |
| `ExclusiveFromInclusive` | `100.00` | `90.91` |
| `GSTOnExclusive` | `0.05` | `0.01` |
| `InclusiveFromExclusive` | `0.05` | `0.06` |

GST commands treat each line as one wholly taxable amount at 10%. They do not decide whether a supply is taxable, GST-free or input taxed. GST is rounded to the nearest cent, with half a cent rounded up, as the ATO's [tax invoice guidance](https://www.ato.gov.au/businesses-and-organisations/gst-excise-and-indirect-taxes/gst/tax-invoices) sets out for an invoice with one taxable sale. Negative amounts round half a cent away from zero, so a reversal cancels its original GST exactly; this symmetry is the library's policy, not a stated ATO rule for adjustment notes. The exclusive amount is the inclusive amount minus the rounded GST, so the two always add back to the input. The two directions are not exact inverses: `0.05` GST-inclusive contains `0.00` GST, while `0.05` GST-exclusive attracts `0.01` GST. For an invoice with several taxable sales, apply the ATO's total invoice or taxable sale rule yourself.

`DifferenceCheck` takes one amount, such as an out-of-balance difference, and reports 2 hints. Transposed digits (`54.00` keyed as `45.00`) and a misplaced decimal point (`12.30` keyed as `123.00`) both leave a difference divisible by 9 cents, so a difference that is not divisible by 9 cannot come from one such error alone. An amount posted to the wrong side moves the difference by twice that amount, so half the difference is the amount to look for. These are prompts for where to look: a difference divisible by 9 can have other causes, and the command proves nothing about the ledger. For `18.00` it returns:

```text
Difference: 18.00
Divisible by 9 (18.00 / 9 = 2.00). Transposed digits or a misplaced decimal point can cause this. It is a hint, not a finding.
Half the difference is 9.00. Look for an amount of 9.00 posted to the wrong side.
```

Input is limited to 64 characters.

Negative results begin with a minus sign, so copying them asks for the spreadsheet formula confirmation described below.

## Text and filenames

Input and output are limited to 32,768 UTF-16 code units. NUL, backspace, DEL and unsupported ASCII control characters are rejected. Tabs and line endings are accepted where the command allows them. Commands reject an empty transformed result.

| Identifier | Behaviour |
| --- | --- |
| `TrimText` | Removes surrounding spaces, tabs, line endings and non-breaking spaces. |
| `TrimLines` | Trims spaces, tabs and non-breaking spaces at each line's ends; preserves blank lines. |
| `CollapseSpaces` | Trims each line and collapses repeated horizontal whitespace; preserves line boundaries. |
| `SingleLine` | Collapses whitespace and joins text into one trimmed line. |
| `LineEndings` | Converts CRLF and CR to LF. |
| `RemoveBlankLines` | Removes lines containing only spaces, tabs or non-breaking spaces; keeps other lines exactly. |
| `NumberLines` | Trims lines, discards blank lines and numbers the rest as `1. first`. |
| `UniqueLines` | Trims lines, discards blank lines and keeps the first exact-case occurrence. |
| `SortLines` | Trims lines, discards blank lines and sorts case sensitively; preserves duplicates. |
| `Uppercase` | Converts text to uppercase. |
| `Lowercase` | Converts text to lowercase. |
| `TitleCase` | Capitalises the first letter of each word and lowercases the rest, so `GST` becomes `Gst`. |
| `QuotedList` | Trims non-empty lines into `'first', 'second'`, doubling embedded single quotes. |
| `CSVRow` | Trims non-empty lines into a comma-separated row; quotes fields containing commas or quotes and doubles embedded quotes. |
| `TSVRow` | Trims non-empty lines into a tab-separated row; rejects input lines that already contain tabs. |
| `Filename` | Joins text into one line, replaces forbidden punctuation with underscores, removes trailing spaces/full stops and prefixes reserved Windows device names with an underscore. Limits the result to 200 characters. |

CSV and TSV output can contain formula-like cells. Copying requires confirmation when detected; the library preserves the preview and does not silently prefix values. Import or paste using the destination application's appropriate text settings.

Filename preparation returns one component as text. It does not inspect paths, create files or guarantee that a name meets every application's naming policy.

## Draft snippets

The 12 bundled drafts cover year-end and quarter records requests, bank reconciliation, receivables, payables, GST, payroll, fixed assets, loans, journal support, transaction queries and a review-query register. Each contains fields to complete. Review the selected period, wording and evidence before using it.

See [custom snippets](../README.md#customise-snippets) for the token list, local folder and limits. Snippets have no script or plug-in execution facility.
