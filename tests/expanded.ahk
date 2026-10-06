#Requires AutoHotkey v2.0

TestExpanded() {
    TestDateHelpers()
    TestIdentifiersAndText()
    TestCatalogue()
    TestSnippetLoading()
    TestSnippetLimits()
    TestPickerState()
    AssertEqual(SettingsWith([]).Keys["Picker"], "", "Picker disabled by default")
    AssertEqual(SettingsWith([["Hotkeys", "Picker", "!^Space"]]).Keys["Picker"], "^!Space", "Picker mapping normalised")
    AssertValueError(() => SettingsWith([["Hotkeys", "Picker", "Ins"]]), "Picker alias conflict rejected")
    AssertValueError(() => SettingsWith([["Hotkeys", "Pickre", "^!Space"]]), "Misspelt hotkey command rejected")
    legacyPath := A_Temp "\au-hotkeys-legacy-" ProcessExist() ".ini"
    FileCopy(A_ScriptDir "\..\config.example.ini", legacyPath)
    try {
        IniDelete(legacyPath, "Hotkeys", "Picker")
        AssertEqual(ReadSettings(legacyPath).Keys["Picker"], "", "Original config remains supported")
    } finally FileDelete(legacyPath)
}

TestDateHelpers() {
    AssertEqual(FinancialYearStart(1900), "01/07/1899", "Earliest selected year start")
    AssertEqual(FinancialYearStart(2026), "01/07/2025", "FY start")
    AssertEqual(FinancialYearRange(2026), "01/07/2025 to 30/06/2026", "FY range")
    starts := ["01/07/2025", "01/10/2025", "01/01/2026", "01/04/2026"]
    for quarterIndex, expected in starts {
        AssertEqual(QuarterStart(2026, quarterIndex), expected, "Quarter start " quarterIndex)
        AssertEqual(QuarterRange(2026, quarterIndex), expected " to " QuarterEnd(2026, quarterIndex), "Quarter range " quarterIndex)
    }
    AssertValueError(() => QuarterStart(2026, 0), "Invalid start quarter")
    AssertValueError(() => QuarterStart(2026, 1.5), "Fractional start quarter")
    AssertEqual(IsoDate("20240229000000"), "2024-02-29", "ISO date")
    AssertEqual(FileDate("20240229000000"), "20240229", "Filename date")
    for vector in [[1900, 28], [2000, 29], [2023, 28], [2024, 29], [2100, 28], [2400, 29]]
        AssertEqual(DaysInMonth(vector[1], 2), vector[2], "Gregorian February " vector[1])
    lengths := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    for month, expected in lengths
        AssertEqual(DaysInMonth(2023, month), expected, "Calendar month " month)
    AssertEqual(MonthEnd(9999, 12), "31/12/9999", "Month end avoids overflowing year 9999")
    AssertEqual(MonthRange(2024, 2), "01/02/2024 to 29/02/2024", "Leap month range")
    AssertEqual(MonthFromDate("2024-02-03", "Label"), "February 2024", "Explicit input month label")
    AssertEqual(MonthFromDate("03/02/2024", "Start"), "01/02/2024", "Explicit input month start")
    AssertEqual(MonthFromDate("20240203", "End"), "29/02/2024", "Explicit input month end")
    for inputDate in ["29/02/2024", "2024-02-29", "20240229", " `r`n29/02/2024`t "] {
        AssertEqual(ConvertDate(inputDate, "AU"), "29/02/2024", "Strict date to AU")
        AssertEqual(ConvertDate(inputDate, "ISO"), "2024-02-29", "Strict date to ISO")
        AssertEqual(ConvertDate(inputDate, "File"), "20240229", "Strict date to file")
    }
    for invalidDate in ["29/02/2023", "29/02/1900", "31/04/2026", "2026-2-3", "3/02/2026", "03/02/26", "03/13/2026", "00/01/2026", "2026-01-02T00:00:00", "01/02/2026`n02/02/2026", "1599-01-01", "20260001", ""]
        AssertValueError(ParseStrictDate.Bind(invalidDate), "Malformed date rejected")
    AssertValueError(() => ParseStrictDate(RepeatText(" ", 65)), "Date length cap")
    AssertValueError(() => DaysInMonth(2026, 0), "Month zero rejected")
    AssertValueError(() => DaysInMonth(2026, 13), "Month 13 rejected")
    AssertValueError(() => DaysInMonth(2026, 2.5), "Fractional month rejected")
    AssertValueError(() => CalendarDate(2026, 1, 1, "Other"), "Unknown output date style")
}

TestIdentifiersAndText() {
    AssertEqual(FormatABN("51824753556"), "51 824 753 556", "ABN Lookup worked example")
    AssertEqual(ABNChecksumPasses("51 824 753 556"), true, "Published ABN checksum")
    AssertEqual(ABNChecksumPasses("10 000 000 000"), true, "Fabricated ABN pass vector")
    AssertEqual(ABNChecksumPasses("10 000 000 001"), false, "Fabricated ABN fail vector")
    AssertEqual(ABNChecksumPasses("00000090000"), false, "Leading-zero ABN format policy")
    AssertEqual(FormatACN("004085616"), "004 085 616", "ASIC leading-zero worked example")
    AssertEqual(ACNChecksumPasses("004 085 616"), true, "Published ACN checksum")
    AssertEqual(ACNChecksumPasses("001234564"), true, "Fabricated ACN pass vector")
    AssertEqual(ACNChecksumPasses("001234565"), false, "Fabricated ACN fail vector")
    AssertEqual(ACNChecksumPasses("000250000"), true, "ACN zero check digit")
    AssertEqual(ACNChecksumPasses("words"), false, "Malformed checksum input returns false")
    for badIdentifier in ["ABN 51824753556", "51-824-753-556", "51824753556`n", "51824753556`t", "5182475355", "51 824 753 556 1"]
        AssertValueError(FormatABN.Bind(badIdentifier), "Bad ABN input rejected")
    AssertValueError(() => FormatACN("004-085-616"), "Bad ACN input rejected")
    AssertEqual(IdentifierReport("10000000000", "ABN"), "ABN 10 000 000 000`nFormat/checksum: passes`nRegistry/existence/status: not checked", "Checksum scope wording")
    AssertEqual(InStr(IdentifierReport("001234565", "ACN"), "fails") > 0, true, "Failed checksum reported")
    AssertEqual(TrimLines("  first `r`n`tsecond`t`rthird "), "first`nsecond`nthird", "Trim line ends")
    AssertEqual(CollapseHorizontalWhitespace(" first`t `tvalue `r`n next  row "), "first value`nnext row", "Collapse horizontal spaces")
    AssertEqual(SingleLine(" first `r`n`tsecond " Chr(0xA0) "value"), "first second value", "Single-line whitespace")
    AssertEqual(NormaliseLineEndings("one`r`ntwo`rthree`nfour"), "one`ntwo`nthree`nfour", "Mixed line endings")
    AssertEqual(UniqueLines("One`nTwo`nOne`none`n `nTwo"), "One`nTwo`none", "Exact-case deduplication")
    AssertEqual(SortedLines("beta`nalpha`n"), "alpha`nbeta", "Sorted non-empty lines")
    AssertEqual(CSVRow('alpha`nb,eta`nq"uote'), 'alpha,"b,eta","q""uote"', "CSV field quoting")
    AssertEqual(TSVRow("alpha`n beta `n"), "alpha`tbeta", "Lines become TSV row")
    AssertValueError(() => TSVRow("alpha`tvalue`nbeta"), "Existing TSV cells rejected")
    AssertEqual(PrepareFilenameText('June: TB / draft?.xlsx '), "June_ TB _ draft_.xlsx", "Filename punctuation")
    for device in ["CON", "nul.txt", "COM1.csv", "LPT9", "COM" Chr(0xB9) ".txt", "LPT" Chr(0xB3)] {
        prepared := PrepareFilenameText(device)
        AssertEqual(prepared, "_" device, "Windows reserved name")
        AssertEqual(PrepareFilenameText(prepared), prepared, "Filename preparation idempotent")
    }
    AssertEqual(PrepareFilenameText("  Name... "), "Name", "Trailing filename dots removed")
    AssertValueError(() => PrepareFilenameText("..."), "Empty filename result rejected")
    AssertValueError(() => PrepareFilenameText(RepeatText("a", 201)), "Filename length limit")
    AssertEqual(StrLen(CheckedText(RepeatText("a", 32768))), 32768, "Input exactly at limit")
    AssertValueError(() => CheckedText(RepeatText("a", 32769)), "Oversize input rejected")
    AssertValueError(() => CheckedText("a" Chr(0) "b"), "NUL input rejected")
    AssertValueError(() => CheckedText("a" Chr(8)), "Backspace input rejected")
    for formulaIndex, formula in ["=1+1", " @SUM(A1:A2)", "a`t+2", "label`r`n - item", Chr(0xA0) "=A1", CSVRow("=1+1,2`nx")]
        AssertEqual(LooksLikeFormula(formula), true, "Formula-like cell recognised " formulaIndex)
    AssertEqual(LooksLikeFormula("ordinary = prose"), false, "Ordinary prose avoids formula warning")
}

TestSnippetLimits() {
    directory := A_Temp "\au-hotkeys-snippet-limits-" ProcessExist()
    context := {Year: 2026, Quarter: 4, Timestamp: "20240229000000"}
    DirCreate(directory)
    created := []
    try {
        Loop 17 {
            path := directory "\" Format("{:03}", A_Index) ".txt"
            FileAppend(RepeatText("a", 16384), path, "UTF-8-RAW")
            created.Push(path)
        }
        loaded := LoadSnippets([directory], context)
        AssertEqual(loaded.Items.Length, 16, "Aggregate snippet limit accepted exactly")
        AssertEqual(loaded.Errors.Length, 1, "Aggregate overflow excluded visibly")
        for path in created
            FileDelete(path)
        created := []
        Loop 101 {
            path := directory "\" Format("{:03}", A_Index) ".txt"
            FileAppend("small", path, "UTF-8-RAW")
            created.Push(path)
        }
        loaded := LoadSnippets([directory], context)
        AssertEqual(loaded.Items.Length, 0, "Oversize snippet directory excluded")
        AssertEqual(loaded.Errors.Length, 1, "Directory count overflow reported")
    } finally {
        for path in created {
            if FileExist(path)
                FileDelete(path)
        }
        DirDelete(directory)
    }
}

TestCatalogue() {
    context := {Year: 2026, Quarter: 1, Timestamp: "20240229000000"}
    identifiers := Map()
    for entry in BuiltinCommands() {
        AssertEqual(identifiers.Has(entry.Id), false, "Unique command identifier")
        identifiers[entry.Id] := true
        sample := entry.Category = "Identifiers" ? (InStr(entry.Id, "ABN") ? "10000000000" : "001234564")
            : entry.Category = "Input dates" ? "2024-02-29" : " alpha `n beta "
        output := ProduceCommand(entry, context, sample)
        AssertEqual(output != "", true, "Every built-in producer runs")
    }
    AssertEqual(FilterCommands(BuiltinCommands(), "QUARTER end").Length, 3, "Search uses case-insensitive terms")
    AssertEqual(FilterCommands(BuiltinCommands(), ".*[()").Length, 0, "Search is literal")
    AssertValueError(() => FilterCommands(BuiltinCommands(), RepeatText("x", 129)), "Search length cap")
    expanded := ExpandSnippet("{{FY_LABEL}} | {{Q_RANGE}} | {{TODAY_ISO}} | {{FILE_DATE}}", context)
    AssertEqual(expanded, "2025-26 | 01/07/2025 to 30/09/2025 | 2024-02-29 | 20240229", "Fixed context token expansion")
    for tokenName, tokenValue in SnippetTokens(context)
        AssertEqual(ExpandSnippet("{{" tokenName "}}", context), tokenValue, "Every token supported")
    literalBody := 'Run("calc.exe") #Include example.ahk %A_Clipboard% {Enter} ^c'
    AssertEqual(ExpandSnippet(literalBody, context), literalBody, "Script-looking snippet remains text")
    for badBody in ["{{UNKNOWN}}", "{{today_au}}", "{{FY_END}", "FY_END}}", "{{}}", "{{{{FY_END}}"]
        AssertValueError(ExpandSnippet.Bind(badBody, context), "Bad token rejected")
    AssertValueError(() => ExpandSnippet(RepeatText("{{FY_END}}", 101), context), "Token count limit")
    AssertEqual(StrLen(ExpandSnippet(RepeatText("a", 16384), context)), 16384, "Snippet at character limit")
    AssertValueError(() => ExpandSnippet(RepeatText("a", 16385), context), "Snippet over character limit")
    catalogue := LoadCommandCatalogue({Year: 2026, Quarter: 4}, A_ScriptDir "\..")
    AssertEqual(catalogue.Errors.Length, 0, "Bundled snippets load without errors")
    AssertEqual(catalogue.Commands.Length, 57, "Built-ins and bundled snippets discovered")
}

TestSnippetLoading() {
    directory := A_Temp "\au-hotkeys-snippets-" ProcessExist()
    context := {Year: 2026, Quarter: 4, Timestamp: "20240229000000"}
    DirCreate(directory)
    DirCreate(directory "\nested")
    DirCreate(directory "\other")
    paths := [directory "\alpha.txt", directory "\zeta.txt", directory "\bad.txt", directory "\binary.txt", directory "\nul.txt", directory "\ignore.ahk", directory "\nested\hidden.txt", directory "\other\ALPHA.txt"]
    try {
        FileAppend("Unicode " Chr(0xE9) " {{FY_END}}", paths[1], "UTF-8")
        FileAppend("second", paths[2], "UTF-8-RAW")
        FileAppend("{{UNKNOWN}}", paths[3], "UTF-8")
        WriteTestBytes(paths[4], [0xC3, 0x28])
        WriteTestBytes(paths[5], [0x61, 0, 0x62])
        FileAppend("ignored", paths[6], "UTF-8")
        FileAppend("not recursive", paths[7], "UTF-8")
        FileAppend("duplicate", paths[8], "UTF-8")
        FileSetAttrib("+R", paths[1])
        before := FileGetTime(paths[1], "M")
        loaded := LoadSnippets([directory, directory "\other"], context)
        AssertEqual(loaded.Items.Length, 2, "Only valid top-level UTF-8 text loads")
        AssertEqual(loaded.Errors.Length, 4, "Unknown token, malformed UTF-8, NUL and duplicate reported")
        AssertEqual(loaded.Items[1].Name, "alpha", "Deterministic snippet sorting")
        AssertEqual(loaded.Items[1].Body, "Unicode " Chr(0xE9) " {{FY_END}}", "BOM removed; Unicode preserved")
        AssertEqual(FileGetTime(paths[1], "M"), before, "Loader preserves modified timestamp")
        AssertEqual(InStr(FileGetAttrib(paths[1]), "R") > 0, true, "Loader preserves read-only attribute")
        AssertEqual(ReadUtf8Snippet(paths[1]), loaded.Items[1].Body, "Read-only source unchanged")
        AssertEqual(LoadSnippets([directory "\missing"], context).Items.Length, 0, "Missing snippet directory yields none")
        AssertEqual(DirExist(directory "\missing"), "", "Missing directory was not created")
    } finally {
        FileSetAttrib("-R", paths[1])
        for path in paths {
            if FileExist(path)
                FileDelete(path)
        }
        DirDelete(directory "\nested")
        DirDelete(directory "\other")
        DirDelete(directory)
    }
}

RepeatText(text, count) {
    result := ""
    Loop count
        result .= text
    return result
}

WriteTestBytes(path, values) {
    bytes := Buffer(values.Length)
    for index, value in values
        NumPut("UChar", value, bytes, index - 1)
    stream := FileOpen(path, "w")
    try stream.RawWrite(bytes)
    finally stream.Close()
}

class FakeClipboard {
    Reads := 0
    Writes := 0
    Confirms := 0
    Value := ""
    Output := ""
    Approved := false
    Opened := 0

    ReadText() {
        this.Reads += 1
        return this.Value
    }

    WriteText(text) {
        this.Writes += 1
        this.Output := text
    }

    Confirm() {
        this.Confirms += 1
        return this.Approved
    }

    OpenPicker(settings) {
        this.Opened += 1
    }
}

NewTestPicker(fake, catalogue := 0) {
    return CommandPicker({Year: 2026, Quarter: 4}, IsObject(catalogue) ? catalogue : BuiltinCommands(), ObjBindMethod(fake, "ReadText"), ObjBindMethod(fake, "WriteText"), ObjBindMethod(fake, "Confirm"))
}

ChooseCommand(picker, id) {
    picker.Search.Value := id
    picker.RefreshList()
    AssertEqual(picker.SelectedId, id, "Command selected " id)
}

TestPickerState() {
    fake := FakeClipboard()
    palette := NewTestPicker(fake)
    try {
        AssertEqual(fake.Reads, 0, "Opening does not read clipboard")
        ChooseCommand(palette, "DateISO")
        AssertEqual(fake.Reads, 0, "Searching and selecting do not read clipboard")
        AssertEqual(palette.CopyButton.Enabled, false, "Input needed before copying")
        fake.Value := "29/02/2024"
        palette.LoadInput()
        AssertEqual(fake.Reads, 1, "Explicit load reads exactly once")
        AssertEqual(palette.Output, "2024-02-29", "Loaded date preview")
        fake.Value := "01/01/2020"
        AssertEqual(palette.CopyResult(), true, "Explicit copy succeeds")
        AssertEqual(fake.Reads, 1, "Copy never rereads input")
        AssertEqual(fake.Writes, 1, "Copy writes exactly once")
        AssertEqual(fake.Output, "2024-02-29", "Copy uses reviewed snapshot")
        ChooseCommand(palette, "TrimLines")
        fake.Value := "alpha`r`nbeta"
        palette.LoadInput()
        palette.CopyResult()
        AssertEqual(fake.Output, palette.Preview.Value, "Multiline copy matches displayed preview")
        writesBeforeInvalid := fake.Writes
        ChooseCommand(palette, "DateAU")
        AssertEqual(palette.Input.Value, "", "New command clears old input")
        AssertEqual(palette.Output, "", "New input command clears old output")
        fake.Value := "29/02/2023"
        palette.LoadInput()
        AssertEqual(palette.CopyResult(), false, "Invalid preview cannot copy")
        AssertEqual(fake.Writes, writesBeforeInvalid, "Invalid preview does not write")
        fake.Value := RepeatText("a", 65)
        palette.LoadInput()
        AssertEqual(palette.CopyButton.Enabled, false, "Per-command cap applied")
        ChooseCommand(palette, "TrimText")
        fake.Value := RepeatText("a", 32768)
        palette.LoadInput()
        AssertEqual(StrLen(palette.Output), 32768, "General input at cap produces preview")
        AssertEqual(palette.Preview.Value, palette.Output, "Preview at cap is complete")
        fake.Value := RepeatText("a", 32769)
        palette.LoadInput()
        AssertEqual(palette.CopyButton.Enabled, false, "General input over cap disables copy")
        fake.Value := "=1+1"
        palette.LoadInput()
        AssertEqual(palette.CopyResult(), false, "Formula copy refused without approval")
        AssertEqual(fake.Confirms, 1, "Formula requires confirmation")
        AssertEqual(fake.Writes, writesBeforeInvalid, "Refused formula not written")
        fake.Approved := true
        AssertEqual(palette.CopyResult(), true, "Formula copy with explicit confirmation")
        AssertEqual(fake.Output, "=1+1", "Confirmed output is exact")
        fake.Value := " `t`r`n"
        palette.LoadInput()
        AssertEqual(palette.CopyButton.Enabled, false, "Empty transformed result disabled")
        ChooseCommand(palette, "YearEnd")
        beforeReads := fake.Reads
        palette.LoadInput()
        AssertEqual(fake.Reads, beforeReads, "Generated command cannot load clipboard")
        AssertEqual(palette.Output, "30/06/2026", "Historical selected period preview")
        palette.Search.Value := ".*[()"
        palette.RefreshList()
        AssertEqual(palette.Output, "", "No-result search clears preview")
        AssertEqual(palette.CopyResult(), false, "No-result search cannot copy")
        palette.Search.Value := RepeatText("x", 129)
        palette.RefreshList()
        AssertEqual(palette.CopyResult(), false, "Oversize search clears result")
    } finally palette.Close()
    custom := [MakeCommand("Huge", "Huge result", "Test", (c, t) => RepeatText("a", 32769))]
    overflowPicker := NewTestPicker(fake, custom)
    try AssertEqual(overflowPicker.CopyButton.Enabled, false, "Oversize output rejected")
    finally overflowPicker.Close()
}

TestPickerHotkeyScope() {
    fake := FakeClipboard()
    settings := ReadSettings(A_ScriptDir "\..\config.example.ini")
    SplitPath(A_AhkPath, &executable)
    settings.Applications := [executable]
    settings.Keys["Picker"] := "^!Space"
    RegisterHotkeys(settings, ObjBindMethod(fake, "OpenPicker"))
    host := Gui(, "AU hotkeys: fabricated picker scope test")
    scopeInput := host.AddEdit("w400")
    try {
        host.Show()
        scopeInput.Focus()
        if !WinWaitActive("ahk_id " host.Hwnd, , 3)
            throw Error("Synthetic scope window could not receive focus.")
        SendLevel(1)
        SendEvent("^!{Space}")
        deadline := A_TickCount + 2000
        while fake.Opened = 0 && A_TickCount < deadline
            Sleep(10)
        AssertEqual(fake.Opened, 1, "Picker hotkey opens inside application scope")
        settings.Applications := ["au-accounting-hotkeys-no-such-app.exe"]
        SendEvent("^!{Space}")
        Sleep(100)
        AssertEqual(fake.Opened, 1, "Picker hotkey inactive outside scope")
        AssertEqual(fake.Reads + fake.Writes, 0, "Picker invocation does not access clipboard")
    } finally host.Destroy()
}

TestPickerKeyboard() {
    fake := FakeClipboard()
    palette := NewTestPicker(fake)
    try {
        palette.Show()
        if !WinWaitActive("ahk_id " palette.Window.Hwnd, , 3)
            throw Error("Synthetic picker could not receive focus.")
        palette.Search.Focus()
        SendText("DateISO")
        Sleep(100)
        AssertEqual(palette.SelectedId, "DateISO", "Keyboard search selects input command")
        AssertEqual(fake.Reads, 0, "Keyboard search leaves clipboard alone")
        fake.Value := "29/02/2024"
        ControlSend("{Space}", palette.LoadButton, palette.Window)
        Sleep(100)
        AssertEqual(fake.Reads, 1, "Native load button invokes fake reader")
        AssertEqual(palette.Preview.Value, "2024-02-29", "Native preview text")
        ControlSend("{Space}", palette.CopyButton, palette.Window)
        Sleep(100)
        AssertEqual(fake.Output, "2024-02-29", "Native copy button invokes fake writer")
        AssertEqual(IsAllowedApplication([]), false, "Direct hotkeys suppressed inside picker")
    } finally palette.Close()
}
