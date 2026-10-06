# AU accounting hotkeys

Type workpaper dates and period labels into Windows applications with configurable AutoHotkey v2 shortcuts for Australian accountants.

[![Check](https://github.com/ryanduguid/au-accounting-hotkeys/actions/workflows/check.yml/badge.svg)](https://github.com/ryanduguid/au-accounting-hotkeys/actions/workflows/check.yml)

## Start

1. Install [AutoHotkey v2](https://www.autohotkey.com/) on Windows.
2. Download this repository using **Code**, then **Download ZIP**, and extract it.
3. Double-click `accounting-hotkeys.ahk`.
4. Open a blank text document and press **Insert**. It types `30/06/2026`.

The first run copies `config.example.ini` to `config.ini`. The default shortcuts work in all applications while the script runs, and Insert replaces the key's usual action. Check the selected year and quarter before using them in a workpaper.

Right-click the AutoHotkey tray icon and select **Suspend Hotkeys** to suspend the shortcuts, or **Exit** to stop the script. The script starts only when you run it.

## Default shortcuts

| Shortcut | Types | Example settings |
| --- | --- | --- |
| Insert | Selected financial-year end | `30/06/2026` |
| Ctrl + Alt + D | Today's date in `dd/MM/yyyy` format | Uses the computer's local date |
| Ctrl + Alt + Q | Selected quarter end | `30/06/2026` for Q4 |
| Ctrl + Alt + Y | Selected financial-year label | `2025-26` |

Dates and labels assume a 30 June financial-year end. They are period labels, not lodgement deadlines. The selected year stays fixed until you change it, so earlier workpapers retain their chosen dates.

## Configure

Select **Open settings** from the tray menu, or edit `config.ini` directly:

```ini
[Period]
FinancialYearEnding=2026
Quarter=4

[Scope]
Applications=

[Hotkeys]
YearEnd=Insert
Today=^!d
QuarterEnd=^!q
FinancialYear=^!y
```

Save the file and select **Reload Script** from the tray menu. The tray tooltip shows the selected financial year and quarter.

`FinancialYearEnding` accepts a four-digit year from 1900 to 9999. For a year ending in 2026:

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

Hotkeys accept a single named key, such as `Insert` or `F6`, with optional modifiers: `^` for Ctrl, `!` for Alt, `+` for Shift and `#` for Windows. For example, `YearEnd=^!e` uses Ctrl + Alt + E. Leave a hotkey value blank to disable that command. Duplicate mappings and invalid settings stop startup with an error message.

`config.ini` is ignored by Git so your settings remain local. Keyboard layouts and application shortcuts can differ; test your mappings in the applications you use.

## Use the date helpers in another script

Include `dates.ahk` to use its functions without registering hotkeys:

```ahk
#Requires AutoHotkey v2.0
#Include C:\path\to\au-accounting-hotkeys\dates.ahk

MsgBox(FinancialYearEnd(2026))       ; 30/06/2026
MsgBox(QuarterEnd(2026, 1))          ; 30/09/2025
MsgBox(FinancialYearLabel(2026))     ; 2025-26
MsgBox(AustralianDate())            ; Today's local date
```

Related tools: [Accounting Excel Toolkit](https://github.com/ryanduguid/accounting-review-pipeline/tree/main/adapters/accounting-excel-toolkit) provides Power Query and VBA utilities; [Ozzit](https://github.com/ryanduguid/Ozzit) provides native Excel modelling functions.

## Check changes

From the repository root, run these PowerShell commands with AutoHotkey v2 installed:

```powershell
& .\tests\run.ps1
& .\tests\run.ps1 -UI
```

For a portable or differently located runtime, pass `-AutoHotkey 'C:\path\to\AutoHotkey64.exe'`.

The first command checks date boundaries, historical years, configuration validation, disabled commands and duplicate mappings. The second also opens a temporary fabricated text window, types through all four shortcuts and checks application scope. It requires an interactive Windows desktop and closes its test window afterwards.

GitHub Actions runs the first command with a checksum-verified AutoHotkey 2.0.29 runtime. The interactive checks must be run locally. These checks do not establish compatibility with every accounting application or keyboard layout.

## Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md) for the checks and information to include with a change.

MIT licensed. See [LICENSE](LICENSE).
