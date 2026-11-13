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
    defaults := SettingDefaults()
    CheckSettingNames(path, defaults)
    year := IniRead(path, "Period", "FinancialYearEnding", defaults["Period"]["FinancialYearEnding"])
    quarter := IniRead(path, "Period", "Quarter", defaults["Period"]["Quarter"])
    ValidateYear(year)
    if !RegExMatch(quarter, "^[1-4]\z")
        throw ValueError("Quarter must be 1, 2, 3 or 4.")

    applications := []
    applicationList := Trim(IniRead(path, "Scope", "Applications", defaults["Scope"]["Applications"]))
    for name in StrSplit(applicationList, ",") {
        name := Trim(name)
        if name = "" {
            if applicationList != ""
                throw ValueError("Applications must not contain empty entries.")
            continue
        }
        if !RegExMatch(name, "i)^[\w .-]+\.exe\z")
            throw ValueError("Applications must be executable names, such as EXCEL.EXE.")
        applications.Push(name)
    }

    keys := Map()
    used := Map()
    used.CaseSense := "Off"
    for command, defaultKey in defaults["Hotkeys"] {
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

; Each section and setting the script reads, with its default. config.example.ini lists exactly these.
SettingDefaults() {
    sections := Map()
    sections.CaseSense := "Off"
    for section, pairs in Map(
        "Period", ["FinancialYearEnding", "2026", "Quarter", "4"],
        "Scope", ["Applications", ""],
        "Hotkeys", ["YearEnd", "Insert", "Today", "^!d", "QuarterEnd", "^!q", "FinancialYear", "^!y", "Picker", ""]
    ) {
        values := Map()
        values.CaseSense := "Off"
        values.Set(pairs*)
        sections[section] := values
    }
    return sections
}

; IniRead returns the first match and falls back to the default for a missing name, so a
; misspelt or repeated section or setting would otherwise change the period or scope silently.
CheckSettingNames(path, defaults) {
    sections := Map()
    sections.CaseSense := "Off"
    for section in StrSplit(IniRead(path, , , ""), "`n", "`r") {
        if section = ""
            continue
        if !defaults.Has(section)
            throw ValueError("Unknown settings section: [" section "]")
        if sections.Has(section)
            throw ValueError("Repeated settings section: [" section "]")
        sections[section] := true
        names := Map()
        names.CaseSense := "Off"
        for line in StrSplit(IniRead(path, section, , ""), "`n", "`r") {
            if Trim(line) = ""
                continue
            if !InStr(line, "=")
                throw ValueError("Setting in [" section "] has no '=': " Trim(line))
            name := Trim(SubStr(line, 1, InStr(line, "=") - 1))
            if !defaults[section].Has(name)
                throw ValueError("Unknown " section " setting: " name)
            if names.Has(name)
                throw ValueError("Repeated " section " setting: " name)
            names[name] := true
        }
    }
}

NormaliseHotkey(key) {
    if !RegExMatch(key, "^([#!+^]*)([A-Za-z0-9]+)\z", &parts)
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

RegisterHotkeys(settings) {
    RegisterHotkeysCore(settings, ShowPicker)
}

RegisterHotkeysCore(settings, openPicker) {
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
    if CommandPicker.ActiveHwnd {
        active := WinActive("A")
        ; Dialogs owned by the picker, such as the formula confirmation, count as the picker.
        if active && (active = CommandPicker.ActiveHwnd || DllCall("GetWindow", "Ptr", active, "UInt", 4, "Ptr") = CommandPicker.ActiveHwnd)
            return false
    }
    if applications.Length = 0
        return true
    for name in applications {
        if WinActive("ahk_exe " name)
            return true
    }
    return false
}
