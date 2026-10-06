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
