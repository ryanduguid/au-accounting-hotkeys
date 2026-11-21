# For a firm's IT reviewer

This page states what the script reads, types and stores, and how to check each statement in the source. It covers the `.ahk` files in this repository's root, not the AutoHotkey runtime, which is a separate product you install from [autohotkey.com](https://www.autohotkey.com/) or with `winget install --id AutoHotkey.AutoHotkey --exact`.

## What runs

- Plain-text AutoHotkey v2 source. There is no compiled executable, installer, service, scheduled task or startup entry; the script runs only when someone opens `accounting-hotkeys.ahk` and stops when they choose **Exit** from its tray menu.
- It makes no network connection. No source file calls `Download` or a network API. Only the Excel formatting shortcuts use COM, and only to reach the active Excel window's own object (`excel.ahk`).
- It calls 4 Windows functions directly: `MultiByteToWideChar` to decode snippet files as UTF-8 (`snippets.ahk`), `GetWindow` to tell whether a dialog belongs to the picker (`accounting-hotkeys.ahk`), and `CLSIDFromString` and `AccessibleObjectFromWindow` to reach the active Excel window (`excel.ahk`).
- It starts one other program: **Open settings** in its tray menu opens `config.ini` in Notepad.

## What it reads

- `config.ini` beside the script, for the selected financial year, quarter, allowed applications and shortcut keys (`ReadSettings`).
- The executable name of the active window, to apply the `[Scope] Applications` list (`IsAllowedApplication`).
- The computer's local date, for the Today shortcut and date commands.
- When the picker opens, top-level `.txt` and `.ahk` files in `snippets` and `snippets.local` beside the script: at most 100 files, each at most 65,536 bytes. It reads hotstrings from an `.ahk` file as text and never runs it. It refuses linked folders and files (`LoadSnippets`).
- The clipboard, only in 2 cases: when the user chooses **Load clipboard and preview**, and straight after **Copy result**, to confirm that the clipboard holds the preview (`clipboard.ahk`). Opening and searching the picker do not read it.

## What it types

Only the 4 shortcuts type, and only into the active window: the selected financial-year end, today's date, the selected quarter end and the financial-year label (`RegisterHotkeysCore`). Each types a date or label the script computes; none types clipboard or snippet text. The picker never types: its result goes to the clipboard, and the user pastes it.

## What it changes in Excel

The 6 Excel formatting shortcuts are off until a key is set for each in `config.ini`. When one is pressed whilst `EXCEL.EXE` is active, it sets the number format, font colour or horizontal alignment of the selected cells in the active workbook window (`ExcelCommands`, `ActiveExcelSelection`). They change no cell values, formulas or other workbooks, and Excel cannot undo them.

## What it stores

- On the first run, it copies `config.example.ini` to `config.ini` beside the script. It never writes to `config.ini` afterwards; users edit it themselves.
- **Add snippet** in the picker, when the user chooses **Save**, appends one line to `snippets.local\Added.ahk` beside the script, creating the folder and file if needed. It refuses a linked folder or file; NTFS hard links are not detected. If the picker would then fail to load the new snippet or one it loaded before, it truncates the file to its earlier length, or deletes a file it created (`AddHotstringSnippet`).
- **Copy result** in the picker replaces the clipboard with the previewed text. Windows clipboard history, clipboard synchronisation and remote-desktop clipboard sharing may keep that text, under the firm's own settings.
- Nothing else: no log, registry entry, temporary file or telemetry.

AutoHotkey itself keeps the last 40 keyboard and mouse events in memory and shows them in its main window (tray menu **Open**, then **View** > **Key history and script info**). Whether that list includes physical keystrokes depends on whether AutoHotkey installs its keyboard hook for the configured shortcuts. The script does not change this default and does not read, save or send the list.

## Check it yourself

From the extracted folder, list the file writes, clipboard access, typing calls, program starts and direct Windows calls in the source:

```powershell
Select-String -Path .\*.ahk -Pattern 'Download|ComObj|DllCall|\bRun(Wait)?\(|Reg(Write|Delete)|File(Append|Copy|Delete|Move|CreateShortcut)|Ini(Write|Delete)|DirCreate|A_Clipboard|SendText' |
    ForEach-Object { '{0}:{1}: {2}' -f $_.Filename, $_.LineNumber, $_.Line.Trim() }
```

On 22 November 2026 this prints 19 lines: one `FileCopy` and one `Run` (Notepad) in `accounting-hotkeys.ahk`, one `DirCreate`, one `FileAppend` and one `FileDelete` in `picker.ahk` for **Add snippet**, the 4 `SendText` shortcuts, 3 `A_Clipboard` lines in `clipboard.ahk`, 5 `DllCall` lines (`GetWindow`, `CLSIDFromString` and `AccessibleObjectFromWindow` once each, `MultiByteToWideChar` twice) and one `ComObjFromPtr` and one `ComObjType` in `excel.ahk`.

`tests\check-boundaries.ps1` needs only PowerShell. It fails if any root `.ahk` file other than `clipboard.ahk` touches the clipboard, if any file other than `accounting-hotkeys.ahk` types, clicks, pastes or sends window messages, or if that file does so other than with `SendText`, if the snippet loader writes a file, or if any file other than `excel.ahk` uses COM or that file does other than wrap the Excel window and check its selection. Positive controls in the same script show that each rule catches what it claims to. Run it with:

```powershell
& .\tests\check-boundaries.ps1
```

The Check workflow runs it, with the AutoHotkey test suite, on every pull request and push to `main`. See [security checks and release verification](security.md) for the workflows and for verifying a release download.

## Not covered here

This page describes the source, not your environment. Endpoint protection, clipboard policies, remote desktops and keyboard layouts are outside what the tests check. The [README](../README.md#check-changes) lists what the tests do not establish.
