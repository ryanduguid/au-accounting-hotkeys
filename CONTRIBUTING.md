# Contribute

Add shortcuts that solve a repeated accounting task, and include a fabricated example of the expected text or action.

Describe the task, its inputs and its expected result in your pull request. Document any application or keyboard-layout requirement. Keep firm paths and personal settings in the ignored `config.ini`; examples and tests must use fabricated data.

Before submitting a change, run from the repository root:

```powershell
& .\tests\run.ps1
& .\tests\run.ps1 -UI
```

Pass `-AutoHotkey 'C:\path\to\AutoHotkey64.exe'` if your runtime is elsewhere. The interactive command opens and closes a temporary test window. State any checks you could not run.

Add tests for new date or configuration behaviour. Include historical periods and invalid inputs where they affect the command. Keep new shortcuts configurable and check for conflicts with existing mappings.

Add new picker commands to `BuiltinCommands()` in `commands.ahk`, with a fixed producer and explicit input limit. Keep input and output validation in `ProduceCommand`. Update the command catalogue and test an expected result, invalid input and the relevant limits. Add snippets as UTF-8 text with whitelisted date tokens; they must contain fields to complete wherever evidence or a judgement is required.

Keep clipboard reads and writes in `clipboard.ahk`. Opening, searching and selecting must not read the clipboard. Copy must use the stored preview. Test with the fake adapter, including formula confirmation and stale input. Preserve the copy-only picker boundary and the original four typing shortcuts. `tests/check-boundaries.ps1` checks these source boundaries against positive controls.

Run checks for both supported architectures when available. CI covers x64 and x86; the interactive tests need a Windows desktop. State which accounting applications and keyboard layouts you tested, and which remain unverified. Third-party code requires a compatible licence and attribution; record resources used in `docs/resources.md`.
