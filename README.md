<p align="center">
  <picture>
    <source media="(max-width: 600px) and (prefers-color-scheme: light)" srcset=".github/assets/banner-phone-light.svg">
    <source media="(max-width: 600px)" srcset=".github/assets/banner-phone.svg">
    <source media="(prefers-color-scheme: light)" srcset=".github/assets/banner-light.svg">
    <img src=".github/assets/banner.svg" width="100%" alt="AU Hotkeys. Windows shortcuts for Australian accountants. Pixel art of a keyboard beside the AU Hotkeys wordmark in slab-serif block letters.">
  </picture>
</p>

<div align="center">

[![check](https://github.com/ryanduguid/au-accounting-hotkeys/actions/workflows/check.yml/badge.svg?branch=main)](https://github.com/ryanduguid/au-accounting-hotkeys/actions/workflows/check.yml)
[![OpenSSF Scorecard](https://raw.githubusercontent.com/ryanduguid/.github/badges/ryanduguid/au-accounting-hotkeys.svg)](https://scorecard.dev/viewer/?uri=github.com/ryanduguid/au-accounting-hotkeys)
[![SLSA build provenance](.github/assets/badges/slsa.svg)](https://github.com/ryanduguid/au-accounting-hotkeys/attestations) [![Latest release](https://img.shields.io/github/v/release/ryanduguid/au-accounting-hotkeys?style=flat&label=release&labelColor=000000&color=66023C)](https://github.com/ryanduguid/au-accounting-hotkeys/releases/latest) [![AutoHotkey: v2](.github/assets/badges/autohotkey.svg)](https://www.autohotkey.com/)
[![licence: Apache-2.0](.github/assets/badges/licence.svg)](LICENSE)

[Start](#start) · [Default shortcuts](#default-shortcuts) · [Enable the command picker](#enable-the-command-picker) · [Command library](#command-library) · [Configure](#configure) · [Customise snippets](#customise-snippets) · [Check changes](#check-changes) · [Licence](#licence)

</div>

Type Australian workpaper dates and use a searchable library of period labels, draft snippets and text transformations on Windows with AutoHotkey v2.

## Start

1. Install [AutoHotkey v2](https://www.autohotkey.com/) on Windows, or run `winget install --id AutoHotkey.AutoHotkey --exact` in a terminal.
2. From the [latest release](https://github.com/ryanduguid/au-accounting-hotkeys/releases/latest), download `au-accounting-hotkeys-v1.2.0.zip` and `SHA256SUMS` into one folder. In PowerShell in that folder, check that the 2 hashes shown match, then extract the zip:

   ```powershell
   (Get-FileHash .\au-accounting-hotkeys-v1.2.0.zip -Algorithm SHA256).Hash.ToLower()
   Get-Content .\SHA256SUMS
   Expand-Archive .\au-accounting-hotkeys-v1.2.0.zip -DestinationPath .
   ```

3. Double-click `accounting-hotkeys.ahk` in the extracted `au-accounting-hotkeys` folder.
4. Open a blank text document and press **Insert**. It types `30/06/2026`.

The release is the checked route. [Verify a download](docs/security.md#verify-a-download) also checks its signed provenance. To use a feature on `main` before the next release, download `main` instead with **Code**, then **Download ZIP**; that download has no published checksum. [CHANGELOG.md](CHANGELOG.md) lists what is unreleased.

The first run copies `config.example.ini` to `config.ini`. The default shortcuts work in all applications whilst the script runs, and Insert replaces the key's usual action. Check the selected year and quarter before using them in a workpaper.

Right-click the AutoHotkey tray icon and select **Suspend Hotkeys** to suspend the shortcuts, or **Exit** to stop the script. The script starts only when you run it.

## Default shortcuts

| Shortcut | Types | Example settings |
| --- | --- | --- |
| Insert | Selected financial-year end | `30/06/2026` |
| Ctrl + Alt + D | Today's date in `dd/MM/yyyy` format | Uses the computer's local date |
| Ctrl + Alt + Q | Selected quarter end | `30/06/2026` for Q4 |
| Ctrl + Alt + Y | Selected financial-year label | `2025-26` |

Dates and labels assume a 30 June financial-year end. They are period labels, not lodgement deadlines. The selected year stays fixed until you change it, so earlier workpapers retain their chosen dates.

## Enable the command picker

Open settings from the tray menu and add this under `[Hotkeys]`:

```ini
Picker=^!Space
```

Save and select **Reload Script**. Press **Ctrl + Alt + Space** in an allowed application. `Picker` is disabled by default so the original 4 shortcuts work without enabling clipboard actions.

1. Search by command name, category, identifier or snippet text, for example `quarter end`, `ABN` or `bank`. All words must match, ignoring case. If nothing matches, a word of 4 or more characters may also match with one typo, or 2 for words of 8 or more, closest first. Snippet text is searched before date tokens are expanded.
2. Select a command with the arrow keys or mouse. Generated dates and snippets show a preview immediately.
3. For an input command, type into **Input text** or choose **Load clipboard and preview**. Opening and searching the picker do not read the clipboard.
4. Review the preview, then choose **Copy result**. Copy uses that exact result, even if the clipboard changes afterwards.
5. Paste into the intended destination yourself. Copy replaces the clipboard; the picker does not type into another window.

Use Tab to move between controls and Escape to close. Changing commands clears the previous input. The 4 typing shortcuts are suppressed whilst the picker or one of its dialogs is active.

Output whose cells begin with `=`, `+`, `-` or `@` triggers a confirmation before copying. This is a warning, not a guarantee about spreadsheet interpretation. Format destination cells as Text when dates or leading-zero identifiers must remain exact. Clipboard history, synchronisation and remote-desktop policies may retain copied text; follow your firm's policy.

## Format cells in Excel

Six opt-in shortcuts format the selected cells in Excel: accounting number formats with negatives in brackets, amounts in thousands, percentages, a date-format cycle starting with `dd/mm/yyyy`, blue inputs and black formulas, and Center Across Selection. Five more change values and formulas: toggle the sign, divide or multiply by 1,000, and copy formulas to paste them elsewhere exactly as written. Seven more each take one key: a font colour cycle of blue inputs, green links to other sheets and black formulas, autofit column width and row height, indent in and out, and add or remove a decimal place. A precedent panel lists the cells the active cell's formula uses, on any sheet or open workbook, and goes to each as you move through the list. Each is off until you give it a key under `[Hotkeys]`, for example:

```ini
ExcelAccounting=^+!a
ExcelColourCode=^+!c
ExcelPrecedents=^+!p
```

They work only in Excel. Ctrl + Z undoes the indent and decimal shortcuts, which run Excel's own commands; Excel cannot undo the others, though the sign and scale shortcuts reverse with a second press or the opposite shortcut and the precedent panel changes nothing. See the [command catalogue](docs/commands.md#excel-formatting-shortcuts) for every format and change.

## Command library

The picker includes 66 built-in commands and 12 draft snippets:

- Copy financial-year and quarter starts, ends, ranges, ISO dates and filename labels.
- List the selected year's month ends.
- Convert one explicit Australian, ISO or compact date, find its month boundaries or its financial year and quarter, or count the days between 2 dates.
- Add days or months to a date, work out a due date from payment terms, move a due date off a weekend or public holiday and age an overdue amount.
- Turn 2 times on one day into decimal hours.
- Clean, format and total pasted amounts, and work out 10% GST on GST-inclusive or GST-exclusive amounts.
- Get the divide-by-9 and half-amount hints for a reconciliation difference.
- Format ABNs and ACNs without losing leading zeros, format an ABN only once its checksum passes, and report their format/checksum result.
- Trim, normalise, number, sort and deduplicate text, or turn lines into a CSV row, a tab-separated row or a quoted list.
- Prepare a filename component as text, without renaming a file.
- Start records requests, reconciliation workpapers, journal support notes and review queries from editable drafts.

See the [command catalogue](docs/commands.md) for every command, input rule and example. [Sources and related projects](docs/resources.md) records the inspected repositories, licences and official references.

ABN and ACN reports do not check registration, identity, active status or GST registration. GST commands assume each line is wholly taxable at 10%; they do not decide whether a supply is taxable, GST-free or input taxed. The snippets contain fields to complete and do not establish that a procedure has been performed or a conclusion reached.

## Configure

Select **Open settings** from the tray menu, or edit `config.ini` directly:

```ini
[Period]
FinancialYearEnding=2026
Quarter=4

[Scope]
Applications=

[Holidays]
State=

[Hotkeys]
YearEnd=Insert
Today=^!d
QuarterEnd=^!q
FinancialYear=^!y
Picker=
ExcelAccounting=
ExcelThousands=
ExcelPercent=
ExcelDates=
ExcelColourCode=
ExcelCentreAcross=
ExcelToggleSign=
ExcelDivide1000=
ExcelMultiply1000=
ExcelCopyFormulas=
ExcelPasteFormulas=
```

Save the file and select **Reload Script** from the tray menu. The tray tooltip shows the selected financial year and quarter.

`FinancialYearEnding` accepts a 4-digit year from 1900 to 9999. For a year ending in 2026:

| Quarter | End date |
| --- | --- |
| 1 | `30/09/2025` |
| 2 | `31/12/2025` |
| 3 | `31/03/2026` |
| 4 | `30/06/2026` |

Leave `Applications` blank for all applications. To enable shortcuts only in Excel and Word, set:

```ini
[Scope]
Applications=EXCEL.EXE,WINWORD.EXE
```

Before using `BusinessDueDate`, set `State` under `[Holidays]` to `ATO`, which counts a holiday for the whole of any State or Territory, or to one of `ACT`, `NSW`, `NT`, `QLD`, `SA`, `TAS`, `VIC` or `WA`. Its holiday list covers 1 July 2026 to 30 June 2027. It counts every day in the ATO's tables; see the [command catalogue](docs/commands.md#date-arithmetic).

Hotkeys accept a single named key, such as `Insert` or `F6`, with optional modifiers: `^` for Ctrl, `!` for Alt, `+` for Shift and `#` for Windows. For example, `YearEnd=^!e` uses Ctrl + Alt + E. Leave a hotkey value blank to disable that command. Duplicate mappings, unknown or repeated sections and settings, and invalid values stop startup with an error message. The recognised hotkey keys are `YearEnd`, `Today`, `QuarterEnd`, `FinancialYear`, `Picker` and the 19 [Excel shortcuts](#format-cells-in-excel); additional commands are available through the picker.

`config.ini` is ignored by Git so your settings remain local. Keyboard layouts and application shortcuts can differ; test your mappings in the applications you use.

Configuration examples: [Excel and Word](examples/excel-word.ini), or [picker only with a historical period](examples/picker-only.ini). Copy the chosen example to `config.ini` after reviewing its scope and mappings. See [troubleshooting](docs/troubleshooting.md) if shortcuts do not respond.

## Customise snippets

Bundled drafts live in `snippets`. To keep your own wording local, create a `snippets.local` directory beside the script and put UTF-8 `.txt` files in it. Start with [Custom-snippet.txt](examples/Custom-snippet.txt). Filenames become labels and must start with an ASCII letter or digit. Remaining characters may be ASCII letters, digits, spaces, underscores or hyphens, with at most 80 characters in total. Labels are compared case-insensitively; use a unique label across both folders.

To add a snippet without leaving the picker, choose **Add snippet**, type a trigger and the text, and choose **Save**. The picker appends it to `snippets.local\Added.ahk` as an AutoHotkey hotstring that types the text literally, escaping backticks, colons, semicolons, tabs, line breaks and spaces at either end, then reloads and selects it. The trigger becomes the label, so it follows the hotstring rules below; a trigger already used by another snippet, ignoring case, is refused, as is text containing `{{` or `}}`. If the picker would then fail to load the new snippet or one it already loads, for example because a limit below would be passed, the save is undone and the reason shown. For date tokens or fields, add a `.txt` file instead.

The picker takes a fresh snapshot when it opens. It loads only top-level `.txt` and `.ahk` files, rejects Windows reparse points such as symbolic links and junctions, and writes only when you save a snippet through **Add snippet**. NTFS hard links are not detected. Invalid files are excluded with a visible explanation, whilst the original shortcuts remain available.

Supported date tokens are `{{TODAY_AU}}`, `{{TODAY_ISO}}`, `{{FILE_DATE}}`, `{{FY_START}}`, `{{FY_END}}`, `{{FY_LABEL}}`, `{{FY_RANGE}}`, `{{Q_START}}`, `{{Q_END}}`, `{{Q_RANGE}}` and `{{Q_NUMBER}}`. `{{TODAY_AU+14}}` is 14 calendar days after today, and `{{DUE_AU+14}}` is that date moved off a weekend or public holiday as `BusinessDueDate` does, so it needs `State` under `[Holidays]` and a result inside its holiday list. Either takes 1 to 999 days. Token names are case sensitive. Unknown or incomplete tokens are errors; replacement happens once. AutoHotkey-looking text stays text.

A field such as `{{ASK:Client name}}` asks for text when you choose the snippet. The picker previews the draft with `[Client name]` in place of each field and lists the fields; type one answer per line, in that order, and the preview shows the completed text to copy. A label used twice asks once. A snippet may ask for up to 10 fields. Labels start with an ASCII letter or digit, have up to 40 ASCII letters, digits, spaces, underscores or hyphens and are case sensitive. Each answer has 1 to 200 characters on one line; spaces and tabs around it are removed, and the rest is inserted once, so a token in an answer stays text.

A choice field such as `{{PICK:Basis|Cash|Accruals}}` offers 2 to 10 choices separated by `|`. The preview shows `[Basis: Cash / Accruals]`, and its answer line must match one choice exactly, including case; any other answer leaves nothing to copy. Each choice has 1 to 100 characters, no spaces at either end, no control characters and no `|`, `{` or `}`, and a choice may not repeat. A choice field counts towards the 10 fields, and a label used twice must repeat the same choices.

To use AutoHotkey hotstrings you already have, put the `.ahk` file that defines them in `snippets.local`; it can keep running from there. The picker reads each `:options:abbreviation::replacement` line, and each continuation section under one, as a snippet labelled with its abbreviation. It never runs the file and loads only replacements that type literal text. It lists by line number, and does not load, entries with the `X` option or a function body, continuation sections with options, text before a continuation section or a second section after it, replacements containing `{{` or `}}`, and replacements that use key syntax such as `{Enter}`, `^`, `!`, `+` or `#` without the `T` or `R` option. A `#Hotstring` line that sets options other than `EndChars` or `NoMouse` excludes the whole file. Each abbreviation must have 1 to 40 ASCII letters, digits or symbols without spaces, and be unique across both folders, including abbreviations repeated under `#HotIf`. Hotstrings created or changed with the `Hotstring` function are not read.

Each snippet accepts up to 16,384 characters and 100 tokens, and an `.ahk` file up to 65,536 bytes. A folder containing more than 100 `.txt` and `.ahk` files is excluded; the library considers at most 100 files across both folders and loads at most 1,000 snippets, with at most 262,144 characters of accepted snippet text. Each `.ahk` file lists at most 10 problems. General input and output accept up to 32,768 characters; dates and identifiers accept up to 64. These counts use UTF-16 code units. Oversize results are rejected without truncation. See the catalogue for command-specific limits, and [troubleshooting](docs/troubleshooting.md) for how clipboard size is checked.

## Use the date helpers in another script

Include `dates.ahk` or another helper file to use its functions without starting shortcuts or reading the clipboard. [Library helpers](docs/library.md) shows the include pattern and lists the date, identifier, text and snippet APIs.

Related tools: [Accounting Excel Toolkit](https://github.com/ryanduguid/accounting-review-pipeline/tree/main/adapters/accounting-excel-toolkit) provides Power Query and VBA utilities; [Ozzit](https://github.com/ryanduguid/Ozzit) provides native Excel modelling functions.

## Check changes

[CONTRIBUTING.md](CONTRIBUTING.md) gives the 2 PowerShell commands, `& .\tests\run.ps1` and the same with `-UI`. The first command checks date boundaries, identifier algorithms, configuration, text transformations, snippet loading, limits and picker state using a fake clipboard. It also checks production boundaries against positive controls. The second opens fabricated windows, types through all 4 shortcuts, operates the native picker controls and checks application scope. It requires an interactive Windows desktop and closes its test windows afterwards. Neither command reads or writes your clipboard.

GitHub Actions runs the first command with checksum-verified AutoHotkey 2.0.31 runtimes for x64 and x86. The interactive checks must be run locally. The Excel shortcuts are tested against stand-ins for Excel's object model, not Excel itself. These checks do not establish compatibility with individual accounting applications, Excel cell interpretation, alternate keyboard layouts, remote desktops or firm clipboard policies.

CodeQL, actionlint and zizmor check the GitHub Actions workflows. For each tagged release, the release workflow runs the library and workflow security checks before packaging the source with signed build provenance. See [security checks and release verification](docs/security.md) for their coverage, release requirements and download verification commands. For a firm's IT review, [what the script reads, types and stores](docs/it-review.md) lists each behaviour with a way to check it in the source.

## Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md) for the checks and information to include with a change. [CHANGELOG.md](CHANGELOG.md) records what has changed.

## Licence

Ryan Duguid's original work is licensed under the [Apache License, Version 2.0](LICENSE). When redistributing this work or a derivative, preserve the applicable attribution notices in [NOTICE](NOTICE) as required by section 4(d). Versions released before this change keep the licence they were released with.

---

<p align="center"><sub><kbd>F</kbd> to pay respects is not bound by default.<br>Reusing this code? See <a href="NOTICE">NOTICE</a> for attribution. AI agents: see <a href="https://github.com/ryanduguid/au-accounting-hotkeys/blob/main/AGENTS.md#reusing-this-code">AGENTS.md</a>.<br>Made in Newcastle, Australia by <a href="https://duguid.com.au/">Ryan Duguid</a>.</sub></p>
