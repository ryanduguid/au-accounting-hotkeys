# Library helpers

Include the helper file you need in an AutoHotkey v2 script. These modules define functions without registering shortcuts, opening the picker or accessing the clipboard.

```ahk
#Requires AutoHotkey v2.0
#Include C:\path\to\au-accounting-hotkeys\identifiers.ahk
#Include C:\path\to\au-accounting-hotkeys\snippets.ahk

MsgBox(MonthRange(2024, 2))
MsgBox(ConvertDate("29/02/2024", "ISO"))
MsgBox(FormatACN("001234564"))
MsgBox(ABNChecksumPasses("10000000000"))
context := {Year: 2026, Quarter: 4, Timestamp: "20261006120000"}
MsgBox(ExpandSnippet("FY {{FY_LABEL}} ends {{FY_END}}", context))
```

## Date API

| Function | Contract |
| --- | --- |
| `FinancialYearEnd(year)` | `30/06/yyyy`; selected ending year 1900 to 9999. |
| `FinancialYearStart(year)` | `01/07/` of the preceding calendar year. |
| `FinancialYearLabel(year)` | Label such as `2025-26`; century boundaries use the ending year's final two digits. |
| `FinancialYearRange(year)` | Start and end separated by ` to `. |
| `QuarterStart(year, quarter)` | Start of fiscal quarter 1 to 4 in the selected ending year. |
| `QuarterEnd(year, quarter)` | End of the selected fiscal quarter. |
| `QuarterRange(year, quarter)` | Quarter start and end separated by ` to `. |
| `AustralianDate(timestamp := "")` | AutoHotkey timestamp to `dd/MM/yyyy`; blank uses the local clock. |
| `IsoDate(timestamp := "")` | AutoHotkey timestamp to `yyyy-MM-dd`. |
| `FileDate(timestamp := "")` | AutoHotkey timestamp to `yyyyMMdd`. |
| `DaysInMonth(year, month)` | Gregorian month length; calendar years 1601 to 9999. |
| `CalendarDate(year, month, day, style := "AU")` | Validates a calendar date and returns AU, ISO or File format. |
| `ParseStrictDate(text)` | Returns `{Year, Month, Day}` from one supported input date. |
| `ConvertDate(text, style := "ISO")` | Converts one supported date to AU, ISO or File format. |
| `MonthStart(year, month)`, `MonthEnd(year, month)` | Calendar month boundaries in Australian format. |
| `MonthRange(year, month)`, `MonthLabel(year, month)` | Calendar range or English month label. |
| `MonthFromDate(text, part)` | Part is Start, End, Range or Label. |

## Identifier and text API

`FormatABN(text)` and `FormatACN(text)` return spaced digits or throw `ValueError` for malformed input. `ABNChecksumPasses(text)` and `ACNChecksumPasses(text)` return false for malformed input or a failed check. Preserve identifiers as strings, especially ACNs with leading zeros. `IdentifierReport(text, kind)` accepts ABN or ACN and states the registry limitation.

`text.ahk` exposes `CheckedText`, `NormaliseLineEndings`, `TrimLines`, `CollapseHorizontalWhitespace`, `SingleLine`, `UniqueLines`, `SortedLines`, `CSVRow`, `TSVRow`, `PrepareFilenameText` and `LooksLikeFormula`. Their output contracts are in the [catalogue](commands.md#text-and-filenames). `CheckedText` applies the fixed character and control-character limits. Transformation helpers do not read or write files.

## Snippet API

`ExpandSnippet(body, context)` expands the documented token whitelist once. Context contains the selected ending `Year`, fiscal `Quarter` and explicit `Timestamp`. It returns text or throws `ValueError`. Unknown and malformed tokens fail; AutoHotkey source, environment references and key syntax remain literal text.

`LoadSnippets(directories, context)` returns `{Items, Errors}`. Each item contains `Name` and `Body`; errors describe excluded files. Production calls it with the two fixed snippet folders. It reads top-level UTF-8 `.txt` files, snapshots their contents and enforces the limits in the README. It does not write files or watch folders.

## Commands and tests

`BuiltinCommands()` returns the fixed registry. `ProduceCommand(command, context, input := "")` validates input/output limits around a producer. `FilterCommands(commands, query)` performs literal search. User snippets supply text bodies; callbacks are defined only in repository source.

The picker accepts injected reader, writer and formula-confirmation callbacks. The tests use `FakeClipboard`, so loading, copying, refusing a formula and preserving a preview can be verified without accessing the system clipboard. Keep production clipboard access in `clipboard.ahk`.
