#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_LineFile%\..\picker.ahk

if A_LineFile = A_ScriptFullPath {
    try StartHotkeys()
    catch Error as startupFailure {
        MsgBox(startupFailure.Message, "AU accounting hotkeys", 16)
        ExitApp(1)
    }
}

StartHotkeys() {
    configPath := A_ScriptDir "\config.ini"
    if !FileExist(configPath)
        FileCopy(A_ScriptDir "\config.example.ini", configPath)
    settings := ReadSettings(configPath)
    RegisterHotkeys(settings)
    A_IconTip := "AU accounting hotkeys`nFY " FinancialYearLabel(settings.Year)
        . " | Q" settings.Quarter " ends " QuarterEnd(settings.Year, settings.Quarter)
    A_TrayMenu.Add("Open settings", (*) => Run('notepad.exe "' configPath '"'))
}

ReadSettings(path) {
    if !FileExist(path)
        throw ValueError("Settings file does not exist: " path)
    year := IniRead(path, "Period", "FinancialYearEnding", "2026")
    quarter := IniRead(path, "Period", "Quarter", "4")
    ValidateYear(year)
    if !RegExMatch(quarter, "^[1-4]$")
        throw ValueError("Quarter must be 1, 2, 3 or 4.")

    applications := []
    applicationList := Trim(IniRead(path, "Scope", "Applications", ""))
    for name in StrSplit(applicationList, ",") {
        name := Trim(name)
        if name = "" {
            if applicationList != ""
                throw ValueError("Applications must not contain empty entries.")
            continue
        }
        if !RegExMatch(name, "i)^[\w .-]+\.exe$")
            throw ValueError("Applications must be executable names, such as EXCEL.EXE.")
        applications.Push(name)
    }

    keys := Map()
    used := Map()
    used.CaseSense := "Off"
    defaults := Map()
    defaults.CaseSense := "Off"
    defaults.Set("YearEnd", "Insert", "Today", "^!d", "QuarterEnd", "^!q", "FinancialYear", "^!y", "Picker", "")
    for line in StrSplit(IniRead(path, "Hotkeys", , ""), "`n", "`r") {
        if !InStr(line, "=")
            continue
        configured := Trim(SubStr(line, 1, InStr(line, "=") - 1))
        if !defaults.Has(configured)
            throw ValueError("Unknown hotkey command: " configured)
    }
    for command, defaultKey in defaults {
        key := Trim(IniRead(path, "Hotkeys", command, defaultKey))
        if key != "" {
            key := NormaliseHotkey(key)
            if used.Has(key)
                throw ValueError("Hotkey " key " is assigned to both " used[key] " and " command ".")
            used[key] := command
        }
        keys[command] := key
    }
    return {Year: Integer(year), Quarter: Integer(quarter), Applications: applications, Keys: keys}
}

NormaliseHotkey(key) {
    if !RegExMatch(key, "^([#!+^]*)([A-Za-z0-9]+)$", &parts)
        throw ValueError("Use a single key with optional Ctrl (^), Alt (!), Shift (+) or Win (#) modifiers.")
    name := GetKeyName(parts[2])
    if name = ""
        throw ValueError("Unknown key: " parts[2])
    modifiers := ""
    for symbol in ["^", "!", "+", "#"] {
        if StrLen(parts[1]) - StrLen(StrReplace(parts[1], symbol)) > 1
            throw ValueError("Repeated hotkey modifier: " symbol)
        if InStr(parts[1], symbol)
            modifiers .= symbol
    }
    return modifiers name
}

RegisterHotkeys(settings, openPicker := ShowPicker) {
    commands := Map(
        "YearEnd", (*) => SendText(FinancialYearEnd(settings.Year)),
        "Today", (*) => SendText(AustralianDate()),
        "QuarterEnd", (*) => SendText(QuarterEnd(settings.Year, settings.Quarter)),
        "FinancialYear", (*) => SendText(FinancialYearLabel(settings.Year)),
        "Picker", (*) => openPicker.Call(settings)
    )
    HotIf((*) => IsAllowedApplication(settings.Applications))
    try {
        for command, key in settings.Keys {
            if key != ""
                Hotkey(key, commands[command], "On")
        }
    } finally HotIf()
}

IsAllowedApplication(applications) {
    if CommandPicker.ActiveHwnd && WinActive("ahk_id " CommandPicker.ActiveHwnd)
        return false
    if applications.Length = 0
        return true
    for name in applications {
        if WinActive("ahk_exe " name)
            return true
    }
    return false
}
