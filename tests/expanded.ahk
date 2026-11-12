#Requires AutoHotkey v2.0

TestExpanded() {
    AssertEqual(RegisterHotkeys.MinParams, 1, "Original registration minimum arity")
    AssertEqual(RegisterHotkeys.MaxParams, 1, "Original registration maximum arity")
    AssertComparisonRejects("ABC", "abc", "Case-only assertion mismatch fails")
    AssertComparisonRejects(1, "1", "Type-only assertion mismatch fails")
    TestDateHelpers()
    TestIdentifiersAndText()
    TestAmounts()
    TestWorkpaperArithmetic()
    TestCatalogue()
    TestSnippetSearch()
    TestSnippetFields()
    TestSnippetLoading()
    TestSnippetLabelsAndRecovery()
    TestSnippetLimits()
    TestPickerState()
    TestPickerHolidayState()
    AssertEqual(SettingsWith([]).Keys["Picker"], "", "Picker disabled by default")
    AssertEqual(SettingsWith([["Hotkeys", "Picker", "!^Space"]]).Keys["Picker"], "^!Space", "Picker mapping normalised")
    AssertValueError(() => SettingsWith([["Hotkeys", "Picker", "Ins"]]), "Picker alias conflict rejected")
    AssertValueError(() => SettingsWith([["Period", "FinancialYearEnd", "2027"]]), "Misspelt period setting rejected", "Unknown Period setting: FinancialYearEnd")
    AssertValueError(() => SettingsWith([["Scope", "Application", "EXCEL.EXE"]]), "Misspelt scope setting rejected", "Unknown Scope setting: Application")
    AssertValueError(() => SettingsWith([["Peroid", "FinancialYearEnding", "2027"]]), "Misspelt section rejected", "Unknown settings section: [Peroid]")
    AssertValueError(() => SettingsWith([["Holiday", "State", "VIC"]]), "Misspelt holidays section rejected", "Unknown settings section: [Holiday]")
    AssertValueError(() => SettingsWith([["Holidays", "Sate", "VIC"]]), "Misspelt holidays setting rejected", "Unknown Holidays setting: Sate")
    AssertEqual(ReadSettings(A_ScriptDir "\..\config.example.ini").HolidayState, "", "Shipped [Holidays] section loads")
    AssertValueError(() => SettingsText("[Period]`nFinancialYearEnding=2026`nQuarter=4`nFinancialYearEnding=2027`n"), "Repeated period setting rejected", "Repeated Period setting: FinancialYearEnding")
    AssertValueError(() => SettingsText("[Scope]`nApplications=EXCEL.EXE`napplications=`n"), "Repeated setting in another case rejected", "Repeated Scope setting: applications")
    AssertValueError(() => SettingsText("[Period]`nFinancialYearEnding=2026`n[Scope]`nApplications=`n[Period]`nFinancialYearEnding=2027`n"), "Repeated section rejected", "Repeated settings section: [Period]")
    AssertValueError(() => SettingsWith([["Hotkeys", "Pickre", "^!Space"]]), "Misspelt hotkey command rejected", "Unknown Hotkeys setting: Pickre")
    AssertEqual(SettingsText("[Period]`nFinancialYearEnding=2027`n").Year, 2027, "Partial settings file keeps defaults")
    for section, values in SettingDefaults()
        for name, value in values
            AssertEqual(IniRead(A_ScriptDir "\..\config.example.ini", section, name, "(missing)"), value, "Distributed default " section " " name)
    AssertEqual(ReadSettings(A_ScriptDir "\..\examples\excel-word.ini").Applications.Length, 2, "Excel and Word example loads")
    AssertEqual(ReadSettings(A_ScriptDir "\..\examples\picker-only.ini").Year, 2024, "Picker-only example loads")
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
    AssertValueError(() => FinancialYearEnd("2026`n"), "Trailing year newline rejected as ValueError")
    AssertValueError(() => QuarterStart(2026, "1`n"), "Trailing start-quarter newline rejected")
    AssertValueError(() => QuarterEnd(2026, "1`n"), "Trailing end-quarter newline rejected")
    AssertValueError(() => DaysInMonth("2026`n", 1), "Trailing calendar-year newline rejected")
    AssertValueError(() => DaysInMonth(2026, "1`n"), "Trailing month newline rejected")
    AssertValueError(() => CalendarDate(2026, 1, "1`n"), "Trailing day newline rejected")
    AssertValueError(() => NormaliseHotkey("D`n"), "Trailing hotkey newline rejected")
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
    AssertEqual(FinancialYearMonthEnds(2024), "31/07/2023`n31/08/2023`n30/09/2023`n31/10/2023`n30/11/2023`n31/12/2023`n31/01/2024`n29/02/2024`n31/03/2024`n30/04/2024`n31/05/2024`n30/06/2024", "FY month ends with leap February")
    AssertEqual(InStr(FinancialYearMonthEnds(1900), "28/02/1900") > 0, true, "Century non-leap February month end")
    AssertValueError(() => FinancialYearMonthEnds(1899), "FY month ends year range")
    AssertEqual(DaysBetween("01/07/2025 to 30/06/2026"), "364", "Days across a financial year")
    AssertEqual(DaysBetween(QuarterRange(2026, 1)), "91", "Days in a pasted quarter range")
    AssertEqual(DaysBetween(" 2024-02-28`r`n`r`n20240301 "), "2", "Days across a leap day, one date per line")
    AssertEqual(DaysBetween("01/03/2024 TO 28/02/2024"), "-2", "Earlier second date gives negative days")
    AssertEqual(DaysBetween("31/12/2025 to 31/12/2025"), "0", "Same date gives zero days")
    for badRange in ["2024-02-29", "2024-02-30 to 2024-03-01", "01/01/2024 to 02/01/2024 to 03/01/2024", "01/01/2024 - 02/01/2024", "01/01/2024`n02/01/2024`n03/01/2024"]
        AssertValueError(DaysBetween.Bind(badRange), "Bad day count input rejected")
    AssertValueError(() => DaysBetween(RepeatText(" ", 201)), "Day count length cap")
    periods := [["01/07/2025", "FY 2025-26 Q1"], ["30/09/2025", "FY 2025-26 Q1"], ["01/10/2025", "FY 2025-26 Q2"], ["31/12/2025", "FY 2025-26 Q2"], ["2026-01-01", "FY 2025-26 Q3"], ["31/03/2026", "FY 2025-26 Q3"], ["01/04/2026", "FY 2025-26 Q4"], ["20260630", "FY 2025-26 Q4"], ["30/06/1900", "FY 1899-00 Q4"]]
    for period in periods
        AssertEqual(PeriodOfDate(period[1]), period[2], "Period of " period[1])
    AssertValueError(() => PeriodOfDate("01/07/9999"), "Period beyond supported years rejected")
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
    AssertEqual(RemoveBlankLines(" a `r`n`r`n `t" Chr(0xA0) "`nb"), " a `nb", "Blank lines removed, other lines kept exactly")
    AssertValueError(() => RemoveBlankLines(" `n`t"), "Only blank lines rejected")
    AssertEqual(NumberedLines("alpha`n`n beta "), "1. alpha`n2. beta", "Non-empty lines numbered")
    AssertEqual(QuotedList("O'Brien`n`n Smith "), "'O''Brien', 'Smith'", "Quoted list doubles quotes")
    AssertEqual(PrepareFilenameText('June: TB / draft?.xlsx '), "June_ TB _ draft_.xlsx", "Filename punctuation")
    for device in ["CON", "nul.txt", "COM1.csv", "LPT9", "COM" Chr(0xB9) ".txt", "LPT" Chr(0xB3), "CON .txt", "Aux .tar.gz"] {
        prepared := PrepareFilenameText(device)
        AssertEqual(prepared, "_" device, "Windows reserved name")
        AssertEqual(PrepareFilenameText(prepared), prepared, "Filename preparation idempotent")
    }
    for ordinary in ["CONX .txt", "CON notes.txt", "Console.txt"]
        AssertEqual(PrepareFilenameText(ordinary), ordinary, "Ordinary name beginning with a device name")
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

TestSnippetSearch() {
    body := 'Depreciation schedule {{FY_LABEL}}`nRun("calc.exe") .*[()'
    command := SnippetCommand({Name: "general-note", Body: body})
    catalogue := BuiltinCommands()
    catalogue.Push(command)
    AssertEqual(FilterCommands(catalogue, "DEPRECIATION").Length, 1, "Search finds text absent from snippet label")
    AssertEqual(FilterCommands(catalogue, "general SCHEDULE").Length, 1, "Search combines label and body terms")
    AssertEqual(FilterCommands(catalogue, "schedule missing").Length, 0, "Every body search term must match")
    AssertEqual(FilterCommands(catalogue, ".*[()").Length, 1, "Snippet body search treats metacharacters literally")
    AssertEqual(FilterCommands(catalogue, "{{FY_LABEL}}").Length, 1, "Search reads unexpanded snippet tokens")
    AssertEqual(FilterCommands(catalogue, "QUARTER end").Length, 3, "Built-in search remains available with snippets")
    fake := FakeClipboard()
    palette := NewTestPicker(fake, catalogue)
    try {
        palette.Search.Value := "depreciation"
        palette.RefreshList()
        AssertEqual(palette.SelectedId, "Snippet:general-note", "Body search selects the matching snippet")
        AssertEqual(fake.Reads + fake.Writes, 0, "Body search leaves the clipboard untouched")
        expected := StrReplace(body, "{{FY_LABEL}}", "2025-26")
        AssertEqual(palette.Preview.Value, expected, "Body search previews expanded literal text")
        AssertEqual(palette.CopyResult(), true, "Body search result can be copied explicitly")
        AssertEqual(fake.Output, expected, "Copy preserves the reviewed snippet text")
        AssertEqual(fake.Reads, 0, "Snippet copy does not read the clipboard")
        AssertEqual(fake.Writes, 1, "Explicit snippet copy writes once")
        palette.Search.Value := "missing"
        palette.RefreshList()
        AssertEqual(palette.CopyResult(), false, "Missing body search cannot copy a stale result")
        AssertEqual(fake.Writes, 1, "Missing body search does not write")
    } finally palette.Close()
}

TestSnippetFields() {
    context := {Year: 2026, Quarter: 4, Timestamp: "20240229000000"}
    body := "To {{ASK:Client name}}: records for {{FY_LABEL}} by {{ASK:Due}}. Regards to {{ASK:Client name}}."
    placeholders := "To [Client name]: records for 2025-26 by [Due]. Regards to [Client name]."
    completed := "To Example Pty Ltd: records for 2025-26 by 30/09/2026. Regards to Example Pty Ltd."
    fields := SnippetFields(body)
    AssertEqual(fields.Length, 2, "Repeated field label asks once")
    AssertEqual(fields[1] "|" fields[2], "Client name|Due", "Fields keep first-appearance order")
    AssertEqual(ExpandSnippet(body, context), placeholders, "Unanswered fields expand to placeholders")
    AssertEqual(ExpandSnippet(body, context, " Example Pty Ltd `r`n30/09/2026`n"), completed, "Answers fill every use of a field")
    AssertEqual(ExpandSnippet("{{ASK:Note}}", context, "{{FY_END}} %A_Clipboard%"), "{{FY_END}} %A_Clipboard%", "Answers are inserted once, as text")
    AssertEqual(ExpandSnippet("{{ASK:Note}}", context, RepeatText("a", 200)), RepeatText("a", 200), "200-character answer allowed")
    AssertValueError(() => ExpandSnippet("{{ASK:Note}}", context, RepeatText("a", 201)), "201-character answer refused")
    AssertValueError(() => ExpandSnippet(body, context, "Example Pty Ltd"), "Missing answer refused")
    AssertValueError(() => ExpandSnippet(body, context, "A`nB`nC"), "Extra answer refused")
    AssertValueError(() => ExpandSnippet(body, context, "A`n `n"), "Blank answer refused")
    AssertValueError(() => ExpandSnippet("No fields", context, "x"), "Answers for a snippet without fields refused")
    ten := ""
    Loop 10
        ten .= "{{ASK:F" A_Index "}}"
    AssertEqual(SnippetFields(ten).Length, 10, "Ten fields allowed")
    AssertValueError(() => SnippetFields(ten "{{ASK:F11}}"), "Eleventh field refused")
    AssertEqual(SnippetFields("{{ASK:" RepeatText("a", 40) "}}").Length, 1, "40-character label allowed")
    for badField in ["{{ASK:}}", "{{ASK: Lead}}", "{{ASK:" RepeatText("a", 41) "}}", "{{ASK:Client:name}}", "{{ask:Client}}"]
        AssertValueError(ExpandSnippet.Bind(badField, context), "Bad field rejected: " badField)

    command := SnippetCommand({Name: "field-note", Body: body})
    AssertEqual(command.Input, true, "Snippet with fields takes input")
    AssertEqual(command.MaxInput, 404, "Answer input bounded by field count")
    AssertEqual(SnippetCommand({Name: "plain", Body: "Plain"}).Input, false, "Snippet without fields takes no input")
    catalogue := BuiltinCommands()
    catalogue.Push(command)
    fake := FakeClipboard()
    palette := NewTestPicker(fake, catalogue)
    try {
        ChooseCommand(palette, "Snippet:field-note")
        AssertEqual(palette.Preview.Value, placeholders, "Picker previews fields as placeholders")
        AssertEqual(palette.Status.Text, "Type one answer per line, in this order: Client name, Due.", "Picker lists the fields")
        AssertEqual(palette.CopyResult(), false, "Unanswered fields cannot be copied")
        ChangeTestInput(palette, "Example Pty Ltd`n30/09/2026")
        AssertEqual(palette.Preview.Value, completed, "Picker previews the completed text")
        AssertEqual(palette.CopyResult(), true, "Completed snippet copies")
        AssertEqual(fake.Output, completed, "Copy uses the completed preview")
        AssertEqual(fake.Reads, 0, "Typed answers do not read the clipboard")
    } finally palette.Close()
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

TestAmounts() {
    for parsed in [["1234.56", 123456], ["1,234.56", 123456], ["$1,234.56", 123456], ["-$1,234.56", -123456], ["($1,234.56)", -123456], ["(0.50)", -50], ["-0", 0], ["1.5", 150], [" 7`t" Chr(0xA0), 700], ["999,999,999,999.99", 99999999999999], ["999999999999", 99999999999900], ["0012", 1200]]
        AssertEqual(ParseAmountCents(parsed[1]), parsed[2], "Amount parsed " parsed[1])
    for badAmount in ["1,23.00", "1234,567", "12,34", "0,123", "1.234", ".50", "1.", "--1", "-(1)", "(1", "1)", "$-1", "1 000", "1,234,567,890,123", "1234567890123", "1e3", "0x10", "+1", "AUD 1.00", "1.00 AUD", Chr(0x0661), "", "abc"]
        AssertValueError(ParseAmountCents.Bind(badAmount), "Bad amount rejected " badAmount)
    for suffixed in ["250.00 CR", "250.00dr", "(250)CR", "250.00" Chr(0xA0) "CR"] {
        try {
            ParseAmountCents(suffixed)
            throw Error("CR/DR suffix accepted: " suffixed)
        } catch ValueError as problem
            AssertEqual(InStr(problem.Message, "CR/DR suffix is ambiguous") > 0, true, "CR/DR suffix rejected " suffixed)
    }
    AssertEqual(FormatCents(0), "0.00", "Zero amount")
    AssertEqual(FormatCents(-5), "-0.05", "Negative cents")
    AssertEqual(FormatCents(123456780, true), "1,234,567.80", "Thousands separators")
    AssertEqual(FormatCents(-100000, true), "-1,000.00", "Negative thousands separators")
    AssertEqual(FormatCents(99900, true), "999.00", "No separator below a thousand")
    AssertEqual(FormatCents(999999999999999, true), "9,999,999,999,999.99", "Largest Excel-safe result")
    AssertValueError(() => FormatCents(-1000000000000000), "Result beyond Excel precision rejected")
    for outOfRange in [0x7FFFFFFFFFFFFFFF, -0x7FFFFFFFFFFFFFFF - 1, 1000000000000000, 1.5, "100"] {
        AssertValueError(FormatCents.Bind(outOfRange), "Formatting rejects cents outside the supported range")
        AssertValueError(GSTOnExclusive.Bind(outOfRange), "GST rejects cents outside the supported range")
    }
    for badDivisor in [0, -10, 101, 0x7FFFFFFFFFFFFFFF, 10.0]
        AssertValueError(RoundedShare.Bind(100, badDivisor), "Rounding rejects unsupported divisors")

    ; GST vectors from the plan review, with half cents rounded away from zero.
    for vector in [["0.04", "0.00", "0.04"], ["0.05", "0.01", "0.06"], ["0.15", "0.02", "0.17"], ["-0.04", "0.00", "-0.04"], ["-0.05", "-0.01", "-0.06"], ["-0.15", "-0.02", "-0.17"], ["100.00", "10.00", "110.00"]] {
        AssertEqual(AmountLines(vector[1], GSTOnExclusive), vector[2], "GST on exclusive " vector[1])
        AssertEqual(AmountLines(vector[1], cents => cents + GSTOnExclusive(cents)), vector[3], "Inclusive from exclusive " vector[1])
    }
    for vector in [["1.10", "0.10", "1.00"], ["0.05", "0.00", "0.05"], ["0.06", "0.01", "0.05"], ["100.00", "9.09", "90.91"], ["(100.00)", "-9.09", "-90.91"], ["999,999,999,999.99", "90,909,090,909.09", "909,090,909,090.90"]] {
        AssertEqual(AmountLines(vector[1], GSTInInclusive, true), vector[2], "GST in inclusive " vector[1])
        AssertEqual(AmountLines(vector[1], cents => cents - GSTInInclusive(cents), true), vector[3], "Exclusive from inclusive " vector[1])
    }
    cents := -2000
    while cents <= 2000 {
        for divisor in [10, 11] {
            share := RoundedShare(cents, divisor)
            AssertEqual(RoundedShare(-cents, divisor), -share, "Rounding is symmetric")
            deviation := 2 * (share * divisor - cents)
            if Abs(deviation) > divisor || (Abs(deviation) = divisor && Abs(share * divisor) < Abs(cents))
                throw Error("Nearest-cent rounding failed for " cents " / " divisor)
        }
        cents += 1
    }

    AssertEqual(AmountLines("`n1`n `t`n(2)`n", cents => cents), "`n1.00`n`n-2.00`n", "Blank lines keep rows aligned")
    AssertEqual(AmountLines("1234.5`r`n-1000000", cents => cents, true), "1,234.50`n-1,000,000.00", "Formatted amount lines")
    AssertValueError(() => AmountLines(" `n`t", cents => cents), "Amount lines need an amount")
    try {
        AmountLines("1`n`nfoo", cents => cents)
        throw Error("Bad amount line accepted.")
    } catch ValueError as problem
        AssertEqual(SubStr(problem.Message, 1, 8), "Line 3: ", "Error names the failing line")
    AssertValueError(() => AmountLines(RepeatText("1`n", 16384), cents => cents), "Oversize amount output rejected, not truncated")

    AssertEqual(TotalAmounts("0.10`n0.20"), "0.30", "Total without binary rounding")
    AssertEqual(TotalAmounts("1.10`n`n$2.20`n(0.30)`n"), "3.00", "Total skips blank lines")
    AssertEqual(TotalAmounts(RepeatText("999,999,999,999.99`n", 10)), "9999999999999.90", "Total at Excel precision limit")
    AssertValueError(() => TotalAmounts(RepeatText("999,999,999,999.99`n", 11)), "Total beyond Excel precision rejected")
    AssertValueError(() => TotalAmounts("`n "), "Total needs an amount")
    AssertValueError(() => TotalAmounts("1`n2 CR"), "Total rejects CR/DR")
}

TestWorkpaperArithmetic() {
    AssertEqual(DifferenceCheck("18.00"), "Difference: 18.00`nDivisible by 9 (18.00 / 9 = 2.00). Transposed digits or a misplaced decimal point can cause this. It is a hint, not a finding.`nHalf the difference is 9.00. Look for an amount of 9.00 posted to the wrong side.", "Difference divisible by 9 with a whole-cent half")
    AssertEqual(DifferenceCheck(" 0.27`r`n"), "Difference: 0.27`nDivisible by 9 (0.27 / 9 = 0.03). Transposed digits or a misplaced decimal point can cause this. It is a hint, not a finding.`nHalf the difference is not a whole cent, so one amount posted to the wrong side does not explain it.", "Cents difference divisible by 9 with no whole-cent half")
    AssertEqual(DifferenceCheck("250.00"), "Difference: 250.00`nNot divisible by 9, so transposed digits or a misplaced decimal point do not explain it on their own.`nHalf the difference is 125.00. Look for an amount of 125.00 posted to the wrong side.", "Half-amount wrong-side case")
    AssertEqual(DifferenceCheck("(1,800.00)"), "Difference: -1,800.00`nDivisible by 9 (1,800.00 / 9 = 200.00). Transposed digits or a misplaced decimal point can cause this. It is a hint, not a finding.`nHalf the difference is 900.00. Look for an amount of 900.00 posted to the wrong side.", "Negative difference uses its size for hints")
    AssertEqual(DifferenceCheck("30.00"), "Difference: 30.00`nNot divisible by 9, so transposed digits or a misplaced decimal point do not explain it on their own.`nHalf the difference is 15.00. Look for an amount of 15.00 posted to the wrong side.", "Difference divisible by 3 but not 9")
    for nil in ["0", "0.00", "-0"]
        AssertEqual(DifferenceCheck(nil), "Difference: 0.00. There is nothing to diagnose.", "Nil difference " nil)
    AssertEqual(DifferenceCheck("999,999,999,999.99"), "Difference: 999,999,999,999.99`nDivisible by 9 (999,999,999,999.99 / 9 = 111,111,111,111.11). Transposed digits or a misplaced decimal point can cause this. It is a hint, not a finding.`nHalf the difference is not a whole cent, so one amount posted to the wrong side does not explain it.", "Largest accepted difference")
    for badDifference in ["18.00`n27.00", "18.00 CR", "", " ", "abc", "1,000,000,000,000.00", 18]
        AssertValueError(DifferenceCheck.Bind(badDifference), "Bad difference rejected")
    AssertValueError(() => DifferenceCheck(RepeatText(" ", 61) "1.00"), "Difference length cap")

    for offset in [["31/01/2024 + 1 month", "29/02/2024"], ["31/01/2023 + 1 month", "28/02/2023"], ["29/02/2024 + 12 months", "28/02/2025"], ["29/02/2024 +48 MONTHS", "29/02/2028"], ["31/03/2026 - 1 month", "28/02/2026"], ["2024-01-31 - 1 month", "31/12/2023"], ["30/06/2026 + 1 day", "01/07/2026"], ["2024-02-28 + 1 day", "29/02/2024"], ["01/03/2024 -1 days", "29/02/2024"], ["28/02/2100 + 1 day", "01/03/2100"], ["15/08/2025 + 0 days", "15/08/2025"], ["01/07/2025 + 364 days", "30/06/2026"], ["31/12/9999 - 0 months", "31/12/9999"], ["01/01/1601 + 99999 days", "16/10/1874"]]
        AssertEqual(DateOffset(offset[1]), offset[2], "Date offset " offset[1])
    for badOffset in ["31/12/9999 + 1 day", "01/01/1601 - 1 day", "15/12/9999 + 1 month", "15/01/1601 - 1 month", "31/01/2024 + 1", "31/01/2024 1 month", "31/01/2024 + 1 year", "31/01/2024 + 1.5 months", "31/01/2024 + 100000 days", "+ 1 day", "31/01/2024 +- 1 day", "31/02/2024 + 1 day", "31/01/2024 + 1 day`n+ 1 day"]
        AssertValueError(DateOffset.Bind(badOffset), "Bad date offset rejected: " badOffset)
    for outside in ["31/12/9999 + 1 day", "01/01/1601 - 1 day", "15/12/9999 + 1 month"] {
        try {
            DateOffset(outside)
            throw Error("Date offset outside the calendar range accepted: " outside)
        } catch ValueError as problem
            AssertEqual(problem.Message, "The result must fall between 1601 and 9999.", "Range error names the limit: " outside)
    }

    ; The date-object helpers are public, so they validate the source date rather than correcting it.
    for invalidSource in [{Year: 2024, Month: 2, Day: 31}, {Year: 2024, Month: 13, Day: 1}, {Year: 2024, Month: 0, Day: 1}, {Year: 2026, Month: 4, Day: 31}, {Year: 1900, Month: 2, Day: 29}, {Year: 2100, Month: 2, Day: 29}, {Year: 1600, Month: 12, Day: 31}, {Year: 2024, Month: 1, Day: 0}] {
        AssertValueError(DateFromMonths.Bind(invalidSource, 0), "Month offset rejects an invalid source date")
        AssertValueError(DateFromMonths.Bind(invalidSource, 1), "Month offset rejects an invalid source date before shifting")
        AssertValueError(DateFromDays.Bind(invalidSource, 0), "Day offset rejects an invalid source date")
        AssertValueError(AustralianDateOf.Bind(invalidSource), "Formatting rejects an invalid date")
    }
    for badCount in [1.5, "1", ""] {
        AssertValueError(DateFromMonths.Bind({Year: 2024, Month: 1, Day: 31}, badCount), "Month offset needs a whole number")
        AssertValueError(DateFromDays.Bind({Year: 2024, Month: 1, Day: 31}, badCount), "Day offset needs a whole number")
    }
    AssertEqual(AustralianDateOf(DateFromMonths({Year: 2024, Month: 1, Day: 31}, 1)), "29/02/2024", "Valid month-end source still ends the shorter month")
    AssertEqual(AustralianDateOf(DateFromMonths({Year: 2000, Month: 2, Day: 29}, 0)), "29/02/2000", "29 February 2000 is a valid source")
    for boundary in [["31/03/2026 + 1 month", "30/04/2026"], ["30/03/2026 + 1 month", "30/04/2026"], ["30/01/2026 + 1 month", "28/02/2026"], ["31/05/2026 + 1 month", "30/06/2026"], ["30/01/2100 + 1 month", "28/02/2100"], ["31/01/2000 + 1 month", "29/02/2000"], ["29/02/2000 + 0 days", "29/02/2000"], ["29/02/2000 + 12 months", "28/02/2001"]]
        AssertEqual(DateOffset(boundary[1]), boundary[2], "Month-end boundary " boundary[1])
    for invalidText in ["31/04/2026 + 1 month", "29/02/1900 + 0 days", "29/02/2100 + 1 month"]
        AssertValueError(DateOffset.Bind(invalidText), "Date offset rejects an impossible date: " invalidText)
    for invalidText in ["31/04/2026 net 30", "29/02/2100 30 days after month end"]
        AssertValueError(DueDate.Bind(invalidText), "Due date rejects an impossible invoice date: " invalidText)
    for monthEndTerms in [["30/04/2026 30 days after month end", "30/05/2026"], ["31/01/2026 1 day after month end", "01/02/2026"], ["30/01/2026 30 days after month end", "02/03/2026"], ["31/01/2024 29 days after month end", "29/02/2024"], ["31/01/2026 28th of next month", "28/02/2026"], ["30/03/2026 30th of next month", "30/04/2026"]]
        AssertEqual(DueDate(monthEndTerms[1]), monthEndTerms[2], "Month-end terms " monthEndTerms[1])
    for missingDay in ["31/03/2026 31st of next month", "30/01/2026 29th of next month", "31/01/2100 29th of next month"]
        AssertValueError(DueDate.Bind(missingDay), "Next-month day missing from a shorter month: " missingDay)

    for due in [["15/01/2026 net 30", "14/02/2026"], ["15/01/2026, 30 days", "14/02/2026"], ["31/01/2024 30 days", "01/03/2024"], ["15/01/2026 Net 0", "15/01/2026"], ["15/01/2026 30 days after month end", "02/03/2026"], ["10/01/2024 30 days after month end", "01/03/2024"], ["15/02/2024 30 days after month end", "30/03/2024"], ["15/01/2026 20th of next month", "20/02/2026"], ["05/12/2025 20th of the following month", "20/01/2026"], ["15/01/2024 29th of next month", "29/02/2024"], ["2026-03-31 1 day", "01/04/2026"], ["15/01/2026`r`nnet 30", "14/02/2026"], ["15/01/2026,`n`n 20th of next month", "20/02/2026"], ["21/01/2026`n1st of next month", "01/02/2026"], ["15/01/2026 2ND of next month", "02/02/2026"], ["15/01/2026 3rd of next month", "03/02/2026"], ["15/01/2026 11th of next month", "11/02/2026"], ["15/01/2026 12th of next month", "12/02/2026"], ["15/01/2026 13th of next month", "13/02/2026"], ["15/01/2026 21st of next month", "21/02/2026"], ["15/01/2026 22nd of next month", "22/02/2026"], ["15/01/2026 23rd of next month", "23/02/2026"]]
        AssertEqual(DueDate(due[1]), due[2], "Due date " due[1])
    for badTerms in ["15/01/2026 30th of next month", "15/01/2026 29th of next month", "15/01/2026 0th of next month", "15/01/2026 30 days EOM", "15/01/2026", "15/01/2026 net thirty", "31/12/9999 net 1", "15/12/9999 20th of next month", "net 30", "15/01/2026 net 30 net 30", "15/01/2026 net 10000", "15/01/2026`nnet 30`nnet 30", "15/01/2026 1nd of next month", "15/01/2026 2st of next month", "15/01/2026 3th of next month", "15/01/2026 11st of next month", "15/01/2026 12nd of next month", "15/01/2026 13rd of next month", "15/01/2026 21th of next month", "15/01/2026 22rd of next month"]
        AssertValueError(DueDate.Bind(badTerms), "Bad payment terms rejected: " badTerms)

    ; Dates from the ATO's tables for 1 July 2026 to 30 June 2027. 6 November 2026 is a Friday.
    for business in [
        ["06/11/2026", "ATO", "06/11/2026"], ["07/11/2026", "NSW", "09/11/2026"], ["01/07/2026", "ATO", "01/07/2026"], ["30/06/2027", "ATO", "30/06/2027"],
        ; National: the day before Christmas stays, since Christmas Eve is a holiday from the evening only; Christmas Day
        ; runs past the weekend and the Boxing Day substitute; New Year's Eve stays and New Year's Day moves.
        ["24/12/2026", "ATO", "24/12/2026"], ["25/12/2026", "NSW", "29/12/2026"], ["31/12/2026", "NT", "31/12/2026"], ["01/01/2027", "WA", "04/01/2027"], ["26/03/2027", "TAS", "30/03/2027"],
        ; Boxing Day 2026 and ANZAC Day 2027 fall on a weekend. Every State has a Boxing Day substitute;
        ; VIC, SA and TAS have no ANZAC Day substitute.
        ["26/12/2026", "ATO", "29/12/2026"], ["26/12/2026", "SA", "29/12/2026"], ["25/04/2027", "NSW", "27/04/2027"], ["25/04/2027", "VIC", "26/04/2027"], ["25/04/2027", "ATO", "27/04/2027"],
        ; State-only holidays count for their State, and for every State under the ATO rule.
        ["25/09/2026", "VIC", "28/09/2026"], ["25/09/2026", "NSW", "25/09/2026"], ["25/09/2026", "ATO", "28/09/2026"], ["05/10/2026", "QLD", "06/10/2026"], ["05/10/2026", "VIC", "05/10/2026"],
        ["14/06/2027", "QLD", "14/06/2027"], ["14/06/2027", "SA", "15/06/2027"], ["07/06/2027", "WA", "08/06/2027"], ["03/08/2026", "NT", "04/08/2026"], ["03/08/2026", "ACT", "03/08/2026"],
        ; Not holidays for the whole of the State, so left out.
        ["28/09/2026", "WA", "28/09/2026"], ["03/11/2026", "VIC", "03/11/2026"]
    ]
        AssertEqual(BusinessDueDate(business[1], business[2]), business[3], "Business due date " business[1] " " business[2])
    for outside in ["30/06/2026", "01/07/2027", "2024-02-28", "31/12/9999"]
        AssertValueError(BusinessDueDate.Bind(outside, "ATO"), "Date outside the holiday list refused: " outside)
    AssertValueError(() => BusinessDueDate("06/11/2026", ""), "Business due date needs a State")
    AssertValueError(() => BusinessDueDate("06/11/2026", "Victoria"), "Unknown State refused")
    AssertValueError(() => BusinessDueDate("06/11/2026 + 1 day", "ATO"), "Business due date takes one date")

    for ageing in [["30/06/2026 to 30/06/2026", "Current"], ["01/07/2026 to 30/06/2026", "Current"], ["29/06/2026 to 30/06/2026", "1 to 30 days overdue"], ["31/05/2026 to 30/06/2026", "1 to 30 days overdue"], ["30/05/2026 to 30/06/2026", "31 to 60 days overdue"], ["01/05/2026`n30/06/2026", "31 to 60 days overdue"], ["30/04/2026 to 30/06/2026", "61 to 90 days overdue"], ["01/04/2026 to 30/06/2026", "61 to 90 days overdue"], ["31/03/2026 to 30/06/2026", "Over 90 days overdue"], ["31/01/2024 to 01/03/2024", "1 to 30 days overdue"], ["31/01/2023 to 03/03/2023", "31 to 60 days overdue"]]
        AssertEqual(AgeingBucket(ageing[1]), ageing[2], "Ageing " ageing[1])
    for badAgeing in ["30/06/2026", "31/06/2026 to 30/06/2026", "30/06/2026 - 31/07/2026"]
        AssertValueError(AgeingBucket.Bind(badAgeing), "Bad ageing input rejected")

    for duration in [["09:00 to 17:30", "8.50"], ["9:00-17:20", "8.33"], ["08:40 to 09:20", "0.67"], ["09:00 to 09:01", "0.02"], ["00:00 to 24:00", "24.00"], ["18:00 TO 24:00", "6.00"], ["09:00`r`n17:30", "8.50"], ["09:00 to 17:20 round up 6", "8.40"], ["09:00 to 17:24 round up 6", "8.40"], ["09:00 to 09:03 round nearest 6", "0.10"], ["09:00 to 09:02 round nearest 6", "0.00"], ["09:00 to 17:07 round nearest 15", "8.00"], ["09:00 to 17:08 ROUND NEAREST 15", "8.25"], ["09:00 to 10:01 round up 60", "2.00"], ["09:00`n`n17:30", "8.50"], [" 09:00 `r`n `r`n 17:20 round up 6", "8.40"]]
        AssertEqual(DurationHours(duration[1]), duration[2], "Duration " duration[1])
    for badDuration in ["17:00 to 09:00", "09:00 to 09:00", "24:00 to 24:00", "24:00 to 01:00", "09:00 to 24:01", "09:60 to 10:00", "25:00 to 26:00", "9am to 5pm", "0900 to 1700", "09:00", "09:00 to 17:00 to 18:00", "09:00 to 17:00 round up 0", "09:00 to 17:00 round up 61", "09:00 to 17:00 round down 6", "09:00 to 17:00 round 6", "09:00:00 to 17:00:00", "09:00`n17:30`n18:00"]
        AssertValueError(DurationHours.Bind(badDuration), "Bad duration rejected: " badDuration)
    AssertValueError(() => DurationHours(RepeatText(" ", 60) "09:00 to 17:00"), "Duration length cap")
}

TestCatalogue() {
    context := {Year: 2026, Quarter: 1, HolidayState: "VIC", Timestamp: "20240229000000"}
    identifiers := Map()
    samples := Map("DaysBetween", "2024-02-29 to 2024-03-31", "DateOffset", "2024-02-29 + 1 month", "DueDate", "2024-02-29 net 30", "BusinessDueDate", "25/09/2026",
        "AgeingBucket", "2024-02-29 to 2024-03-31", "DurationHours", "09:00 to 17:30", "DifferenceCheck", "18.00")
    for entry in BuiltinCommands() {
        AssertEqual(identifiers.Has(entry.Id), false, "Unique command identifier")
        identifiers[entry.Id] := true
        sample := samples.Has(entry.Id) ? samples[entry.Id]
            : entry.Category = "Identifiers" ? (InStr(entry.Id, "ABN") ? "10000000000" : "001234564")
            : entry.Category = "Input dates" ? "2024-02-29"
            : entry.Category = "Amounts" || entry.Category = "GST" ? "1,234.56`n`n(10.00)" : " alpha `n beta "
        output := ProduceCommand(entry, context, sample)
        AssertEqual(output != "", true, "Every built-in producer runs")
        if entry.Id = "Uppercase"
            AssertEqual(ProduceCommand(entry, context, "MiXeD text"), "MIXED TEXT", "Uppercase exact output")
        if entry.Id = "Lowercase"
            AssertEqual(ProduceCommand(entry, context, "MiXeD text"), "mixed text", "Lowercase exact output")
        if entry.Id = "TitleCase"
            AssertEqual(ProduceCommand(entry, context, "mIXED text"), "Mixed Text", "Title case exact output")
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
    AssertEqual(ExpandSnippet("MiXeD {{FY_LABEL}} TeXt", context), "MiXeD 2025-26 TeXt", "Mixed-case snippet preserved exactly")
    for badBody in ["{{UNKNOWN}}", "{{today_au}}", "{{FY_END}", "FY_END}}", "{{}}", "{{{{FY_END}}"]
        AssertValueError(ExpandSnippet.Bind(badBody, context), "Bad token rejected")
    AssertValueError(() => ExpandSnippet(RepeatText("{{FY_END}}", 101), context), "Token count limit")
    AssertEqual(StrLen(ExpandSnippet(RepeatText("a", 16384), context)), 16384, "Snippet at character limit")
    AssertValueError(() => ExpandSnippet(RepeatText("a", 16385), context), "Snippet over character limit")
    catalogue := LoadCommandCatalogue({Year: 2026, Quarter: 4}, A_ScriptDir "\..")
    AssertEqual(catalogue.Errors.Length, 0, "Bundled snippets load without errors")
    AssertEqual(catalogue.Commands.Length, 77, "Built-ins and bundled snippets discovered")
    for draft in LoadSnippets([A_ScriptDir "\..\snippets"], context).Items
        AssertEqual(InStr(draft.Body, "[complete") > 0, true, "Bundled draft requires completion: " draft.Name)
}

AssertComparisonRejects(actual, expected, description) {
    global checks
    try AssertEqual(actual, expected, description)
    catch Error {
        checks += 1
        return
    }
    throw Error(description ": comparison unexpectedly passed.")
}

TestSnippetLabelsAndRecovery() {
    directory := A_Temp "\au-hotkeys-snippet-labels-" ProcessExist()
    second := directory "\local"
    context := {Year: 2026, Quarter: 4, Timestamp: "20240229000000"}
    DirCreate(second)
    paths := [directory "\same.txt", second "\same.txt"]
    try {
        FileAppend("{{UNKNOWN}}", paths[1], "UTF-8-RAW")
        FileAppend("accepted", paths[2], "UTF-8-RAW")
        loaded := LoadSnippets([directory, second], context)
        AssertEqual(loaded.Items.Length, 1, "Invalid snippet does not reserve its name")
        AssertEqual(loaded.Items[1].Name, "same", "Later valid name accepted")
        AssertEqual(loaded.Items[1].Body, "accepted", "Later valid body accepted")
        AssertEqual(loaded.Errors.Length, 1, "Invalid first snippet reported visibly")
        for label in [RepeatText("a", 80), RepeatText("a", 81), "_Draft", "-Draft", "R" Chr(0xE9) "sum" Chr(0xE9)] {
            path := second "\" label ".txt"
            paths.Push(path)
            FileAppend("draft", path, "UTF-8-RAW")
        }
        loaded := LoadSnippets([second], context)
        AssertEqual(loaded.Items.Length, 2, "80-character ASCII label accepted")
        AssertEqual(loaded.Errors.Length, 4, "81-character, leading punctuation and non-ASCII labels rejected")
        for message in loaded.Errors {
            AssertEqual(InStr(message, "start with an ASCII letter or digit") > 0, true, "Label error explains leading-character rule")
            AssertEqual(InStr(message, "at most 80 characters") > 0, true, "Label error explains length rule")
        }
    } finally {
        for path in paths {
            if FileExist(path)
                FileDelete(path)
        }
        DirDelete(second)
        DirDelete(directory)
    }
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
    Replacement := ""
    Approved := false
    Opened := 0
    OnConfirm := 0

    ReadText() {
        this.Reads += 1
        return this.Value
    }

    WriteText(text) {
        this.Writes += 1
        this.Output := text
        return this.Replacement = "" ? text : this.Replacement
    }

    Confirm() {
        this.Confirms += 1
        if IsObject(this.OnConfirm)
            this.OnConfirm.Call()
        return this.Approved
    }

    OpenPicker(settings) {
        this.Opened += 1
    }
}

NewTestPicker(fake, catalogue := 0) {
    return CommandPicker({Year: 2026, Quarter: 4, HolidayState: "VIC"}, IsObject(catalogue) ? catalogue : BuiltinCommands(), ObjBindMethod(fake, "ReadText"), ObjBindMethod(fake, "WriteText"), ObjBindMethod(fake, "Confirm"))
}

ChooseCommand(picker, id) {
    picker.Search.Value := id
    picker.RefreshList()
    AssertEqual(picker.SelectedId, id, "Command selected " id)
}

TestPickerHolidayState() {
    fake := FakeClipboard()
    palette := NewTestPicker(fake)
    try {
        ChooseCommand(palette, "BusinessDueDate")
        fake.Value := "25/09/2026"
        palette.LoadInput()
        AssertEqual(palette.Output, "28/09/2026", "Picker passes the [Holidays] State")
    } finally palette.Close()
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
        fake.Replacement := "changed by another program"
        AssertEqual(palette.CopyResult(), false, "Copy reports a clipboard that lost the preview")
        AssertEqual(InStr(palette.Status.Text, "Copy not confirmed"), 1, "Lost copy is not reported as copied")
        fake.Replacement := ""
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
        fake.Value := "=sum(a1)"
        palette.LoadInput()
        fake.OnConfirm := ChangeTestInput.Bind(palette, "=SUM(A1)")
        writesBeforeCaseChange := fake.Writes
        AssertEqual(palette.CopyResult(), false, "Case-only change during confirmation refuses copy")
        AssertEqual(fake.Writes, writesBeforeCaseChange, "Changed preview was not copied")
        fake.OnConfirm := 0
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

ChangeTestInput(picker, text) {
    picker.Input.Value := text
    picker.RefreshPreview()
}

TestPickerHotkeyScope() {
    fake := FakeClipboard()
    settings := ReadSettings(A_ScriptDir "\..\config.example.ini")
    SplitPath(A_AhkPath, &executable)
    settings.Applications := [executable]
    settings.Keys["Picker"] := "^!Space"
    RegisterHotkeysCore(settings, ObjBindMethod(fake, "OpenPicker"))
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

TestPickerOwnsDialogs() {
    fake := FakeClipboard()
    palette := NewTestPicker(fake)
    seen := {Owner: 0, Allowed: ""}
    palette.Confirm := ConfirmWithInspectedDialog.Bind(seen)
    try {
        palette.Show()
        if !WinWaitActive("ahk_id " palette.Window.Hwnd, , 3)
            throw Error("Synthetic dialog-test picker could not receive focus.")
        ChooseCommand(palette, "TrimText")
        palette.Input.Value := "=1+1"
        palette.RefreshPreview()
        copied := palette.CopyResult()
        AssertEqual(seen.Owner, palette.Window.Hwnd, "Formula confirmation is owned by the picker")
        AssertEqual(seen.Allowed, false, "Direct hotkeys suppressed inside picker dialogs")
        AssertEqual(copied, false, "Declined confirmation refuses copy")
        AssertEqual(fake.Writes, 0, "Declined confirmation does not write")
    } finally palette.Close()
}

ConfirmWithInspectedDialog(seen) {
    SetTimer(InspectActiveDialog.Bind(seen), -300)
    return MsgBox("Fabricated confirmation", "AU hotkeys: dialog test", "YesNo T3") = "Yes"
}

InspectActiveDialog(seen) {
    dialog := WinActive("AU hotkeys: dialog test")
    if dialog {
        seen.Owner := DllCall("GetWindow", "Ptr", dialog, "UInt", 4, "Ptr") ; GW_OWNER
        seen.Allowed := IsAllowedApplication([])
        PostMessage(0x111, 7, 0, , dialog) ; WM_COMMAND IDNO declines the confirmation.
    }
}

ReplaceNativeEdit(control, text) {
    SendMessage(0xB1, 0, -1, control) ; EM_SETSEL selects the existing text.
    SendMessage(0xC2, 0, StrPtr(text), control) ; EM_REPLACESEL exercises the edit's native limit.
    Sleep(100)
}

TestPickerManualLimits() {
    fake := FakeClipboard()
    palette := NewTestPicker(fake)
    try {
        palette.Show()
        if !WinWaitActive("ahk_id " palette.Window.Hwnd, , 3)
            throw Error("Synthetic limit-test picker could not receive focus.")
        ChooseCommand(palette, "TrimText")
        ReplaceNativeEdit(palette.Input, RepeatText("a", 32770))
        AssertEqual(StrLen(palette.Input.Value), 32769, "Native input retains one character beyond processing cap")
        AssertEqual(palette.Output, "", "Oversize native input does not produce a valid prefix")
        AssertEqual(palette.CopyButton.Enabled, false, "Oversize native input disables copy")
        ReplaceNativeEdit(palette.Input, RepeatText("a", 32768))
        AssertEqual(palette.Output, RepeatText("a", 32768), "At-cap native input produces complete output")
        AssertEqual(palette.Preview.Value, palette.Output, "At-cap native preview is complete")
        ReplaceNativeEdit(palette.Search, RepeatText("x", 130))
        AssertEqual(StrLen(palette.Search.Value), 129, "Native search retains one character beyond processing cap")
        AssertEqual(palette.Output, "", "Oversize native search clears output")
        AssertEqual(palette.CopyButton.Enabled, false, "Oversize native search disables copy")
        ReplaceNativeEdit(palette.Search, RepeatText(" ", 128))
        AssertEqual(StrLen(palette.Search.Value), 128, "At-cap native search is retained completely")
        AssertEqual(palette.Rows.Length, 65, "At-cap whitespace query still searches the catalogue")
        AssertEqual(fake.Reads + fake.Writes, 0, "Manual entry does not access clipboard")
    } finally palette.Close()
}

TestPickerTargetBoundary() {
    fake := FakeClipboard()
    palette := NewTestPicker(fake)
    settings := ReadSettings(A_ScriptDir "\..\config.example.ini")
    SplitPath(A_AhkPath, &executable)
    settings.Applications := [executable]
    settings.Keys["Picker"] := "^!Space"
    RegisterHotkeysCore(settings, (*) => palette.Show())
    target := Gui(, "AU hotkeys: fabricated originating target")
    targetInput := target.AddEdit("w400", "Target sentinel remains unchanged")
    try {
        target.Show()
        targetInput.Focus()
        if !WinWaitActive("ahk_id " target.Hwnd, , 3)
            throw Error("Fabricated target could not receive focus.")
        SendLevel(1)
        SendEvent("^!{Space}")
        if !WinWaitActive("ahk_id " palette.Window.Hwnd, , 3)
            throw Error("Picker hotkey did not open the synthetic picker.")
        ChooseCommand(palette, "YearEnd")
        AssertEqual(palette.CopyResult(), true, "Copy from hotkey-opened picker succeeds")
        AssertEqual(fake.Output, "30/06/2026", "Only writer receives exact preview")
        AssertEqual(fake.Writes, 1, "Explicit copy writes once")
        AssertEqual(fake.Reads, 0, "Generated output does not load clipboard")
        AssertEqual(!!WinActive("ahk_id " target.Hwnd), false, "Copy does not restore originating target focus")
        AssertEqual(targetInput.Value, "Target sentinel remains unchanged", "Copy does not type into originating target")
    } finally {
        palette.Close()
        target.Destroy()
    }
}
