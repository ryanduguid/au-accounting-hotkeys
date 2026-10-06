# Troubleshooting

Test shortcuts in a blank document before using them in a workpaper.

## The script does not start

Use AutoHotkey v2. The script requires v2 syntax. If a settings error appears, check the ending year, quarter, application list and hotkey mappings. A duplicate key, unknown command or unsupported key syntax prevents startup. Compare with `config.example.ini`.

The script needs permission to create `config.ini` on its first run. Extract it into a writable folder. Settings and snippets should stay in a folder your firm's policy permits.

## Insert does not type the expected date

Check `[Period] FinancialYearEnding` in `config.ini`, save and choose **Reload Script**. The tray tooltip and picker show the selected period. A script already running keeps its loaded settings until reloaded.

Check whether hotkeys are suspended and whether `[Scope] Applications` includes the active application. Executable names belong in this list, for example `EXCEL.EXE`, with commas between entries. Do not put paths or window titles in it.

An application may already use the shortcut. Remap the command and test again. Some elevated applications do not accept input from a script running at a lower privilege level. Follow the firm's desktop policy before changing privilege levels.

## The picker does not open

Set `Picker=^!Space` under `[Hotkeys]` and reload. It is blank in the default configuration. Test from an application permitted by the scope. A firm policy or another application may reserve that shortcut; choose another mapping.

## Copy is disabled

Select a command and provide its required input. Input commands require manual text or an explicit **Load clipboard and preview** action. Read the status line for malformed dates, identifiers, unsupported control characters, empty results or size limits. The picker rejects oversize text without truncating it.

Changing commands clears previous input. Search with ordinary words; search punctuation is literal.

Clipboard size is validated after Windows supplies the text. The limit bounds accepted processing and output, but not the clipboard provider's initial allocation or transfer. Use a smaller fabricated input when investigating size errors.

## A snippet is missing

Use a top-level UTF-8 `.txt` file in `snippets.local`. The label must start with an ASCII letter or digit and contain at most 80 characters. Remaining characters may be ASCII letters, digits, spaces, underscores or hyphens. Labels are compared case-insensitively across both folders. Reopen the picker after editing it. Nested files, Windows reparse points, invalid UTF-8, malformed tokens and exceeded limits are excluded. NTFS hard links are not detected. The picker lists loading errors.

## Excel changes the pasted result

Dates and identifiers can be interpreted according to cell format and Excel settings. Pre-format destination cells as Text when you need exact text, including leading zeros. Review the formula bar as well as the displayed cell. Formula-like output requires confirmation before copying, but this does not establish safe interpretation in Excel.

Direct date hotkeys type text into the active application; that application determines its interpretation. Native synthetic test windows do not prove Excel compatibility.

## Stop or reset

Right-click the AutoHotkey tray icon and choose **Suspend Hotkeys** or **Exit**. To restore defaults, exit the script, preserve your existing `config.ini` somewhere local if needed, copy `config.example.ini` to `config.ini` and restart. The library installs no startup entry.

When reporting a problem, include the command, fabricated input, expected result, actual result, AutoHotkey version, Windows version and application. Do not include client data, passwords, tax file numbers or bank details.
