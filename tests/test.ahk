#Requires AutoHotkey v2.0
#Warn All, StdOut
#Include %A_ScriptDir%\..\accounting-hotkeys.ahk
#Include %A_ScriptDir%\expanded.ahk
#SingleInstance Off

checks := 0
try {
    AssertEqual(FinancialYearEnd(2026), "30/06/2026", "Selected year end")
    AssertEqual(FinancialYearEnd(2023), "30/06/2023", "Historical year end")
    AssertEqual(FinancialYearLabel(2026), "2025-26", "Financial-year label")
    AssertEqual(FinancialYearLabel(2100), "2099-00", "Century boundary")
    AssertEqual(QuarterEnd(2026, 1), "30/09/2025", "Q1 belongs to previous calendar year")
    AssertEqual(QuarterEnd(2026, 2), "31/12/2025", "Q2 belongs to previous calendar year")
    AssertEqual(QuarterEnd(2026, 3), "31/03/2026", "Q3 belongs to ending calendar year")
    AssertEqual(QuarterEnd(2026, 4), "30/06/2026", "Q4 equals year end")
    AssertEqual(AustralianDate("20240229000000"), "29/02/2024", "Leap-day formatting")
    AssertEqual(AustralianDate("20260102000000"), "02/01/2026", "Day before month")
    AssertValueError(() => FinancialYearEnd(2026.5), "Fractional year rejected")
    AssertValueError(() => FinancialYearEnd("2026x"), "Malformed year rejected")
    AssertValueError(() => FinancialYearEnd(1899), "Unsupported year rejected")
    AssertValueError(() => QuarterEnd(2026, 0), "Quarter zero rejected")
    AssertValueError(() => QuarterEnd(2026, 5), "Quarter five rejected")
    AssertValueError(() => QuarterEnd(2026, 1.5), "Fractional quarter rejected")

    exampleSettings := ReadSettings(A_ScriptDir "\..\config.example.ini")
    AssertEqual(exampleSettings.Year, 2026, "Example ending year")
    AssertEqual(exampleSettings.Quarter, 4, "Example quarter")
    AssertEqual(exampleSettings.Keys["YearEnd"], "Insert", "Insert mapping")
    AssertEqual(exampleSettings.Applications.Length, 0, "Default global scope")
    AssertEqual(SettingsWith([["Hotkeys", "YearEnd", ""]]).Keys["YearEnd"], "", "Blank disables shortcut")
    AssertEqual(SettingsWith([["Period", "FinancialYearEnding", "2022"]]).Year, 2022, "Historical configuration")
    scoped := SettingsWith([["Scope", "Applications", " EXCEL.EXE, WINWORD.EXE "]])
    AssertEqual(scoped.Applications.Length, 2, "Application list parsed")
    AssertEqual(scoped.Applications[2], "WINWORD.EXE", "Application whitespace removed")
    AssertEqual(NormaliseHotkey("!^d"), NormaliseHotkey("^!D"), "Modifier order and key case normalised")
    AssertEqual(NormaliseHotkey("Ins"), "Insert", "Key aliases normalised")
    AssertValueError(() => SettingsWith([["Period", "FinancialYearEnding", "2026.5"]]), "Invalid configured year")
    AssertValueError(() => SettingsWith([["Period", "Quarter", "0"]]), "Invalid configured quarter")
    AssertValueError(() => SettingsWith([["Scope", "Applications", "*.exe"]]), "Invalid application name")
    AssertValueError(() => SettingsWith([["Scope", "Applications", ","]]), "Empty application entries rejected")
    AssertValueError(() => SettingsWith([["Scope", "Applications", "EXCEL.EXE,"]]), "Trailing application comma rejected")
    AssertValueError(() => SettingsWith([["Hotkeys", "YearEnd", "!^d"]]), "Duplicate modifier ordering rejected")
    AssertValueError(() => SettingsWith([["Hotkeys", "Today", "Ins"]]), "Duplicate key aliases rejected")
    AssertValueError(() => NormaliseHotkey("^^d"), "Repeated modifiers rejected")
    AssertValueError(() => NormaliseHotkey("NoSuchKey123"), "Unknown key rejected")
    AssertValueError(() => NormaliseHotkey("Insert & d"), "Unsupported key combinations rejected")

    TestExpanded()
    if A_Args.Length > 0 && A_Args[1] = "--ui" {
        TestKeyboardInput()
        TestPickerKeyboard()
        TestPickerHotkeyScope()
        TestPickerManualLimits()
        TestPickerTargetBoundary()
    }
    FileAppend("PASS: " checks " checks`n", "*")
    ExitApp(0)
} catch Error as testFailure {
    FileAppend("FAIL: " testFailure.Message "`n" testFailure.Stack "`n", "**")
    ExitApp(1)
}

AssertEqual(actual, expected, description) {
    global checks
    if Type(actual) !== Type(expected) || actual !== expected
        throw Error(description ": expected '" expected "', got '" actual "'.")
    checks += 1
}

AssertValueError(callback, description) {
    global checks
    try callback()
    catch ValueError {
        checks += 1
        return
    }
    throw Error(description ": expected ValueError.")
}

SettingsWith(changes) {
    static sequence := 0
    sequence += 1
    path := A_Temp "\au-accounting-hotkeys-" ProcessExist() "-" sequence ".ini"
    FileCopy(A_ScriptDir "\..\config.example.ini", path)
    try {
        for change in changes
            IniWrite(change[3], path, change[1], change[2])
        return ReadSettings(path)
    } finally FileDelete(path)
}

TestKeyboardInput() {
    settings := ReadSettings(A_ScriptDir "\..\config.example.ini")
    SplitPath(A_AhkPath, &executable)
    settings.Applications := [executable]
    RegisterHotkeys(settings)
    window := Gui(, "AU accounting hotkeys: fabricated input test")
    field := window.AddEdit("w420")
    try {
        window.Show()
        field.Focus()
        if !WinWaitActive("ahk_id " window.Hwnd, , 3)
            throw Error("Synthetic test window could not receive focus.")
        SendLevel(1)
        for testCase in [
            ["{Insert}", "30/06/2026"],
            ["^!q", "30/06/2026"],
            ["^!y", "2025-26"],
            ["^!d", FormatTime(, "dd/MM/yyyy")]
        ] {
            field.Value := ""
            if !WinActive("ahk_id " window.Hwnd)
                throw Error("Synthetic test window lost focus.")
            SendEvent(testCase[1])
            deadline := A_TickCount + 2000
            while field.Value != testCase[2] && A_TickCount < deadline
                Sleep(10)
            AssertEqual(field.Value, testCase[2], "Keyboard input " testCase[1])
        }
        settings.Applications := ["au-accounting-hotkeys-no-such-app.exe"]
        field.Value := ""
        SendEvent("{Insert}")
        Sleep(200)
        AssertEqual(field.Value, "", "Shortcut inactive outside allowed applications")
    } finally window.Destroy()
}
