#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\dates.ahk
#Include %A_LineFile%\..\identifiers.ahk
#Include %A_LineFile%\..\snippets.ahk

MakeCommand(id, label, category, produce, input := false, maximum := 32768) {
    return {Id: id, Label: label, Category: category, Produce: produce, Input: input, MaxInput: maximum}
}

BuiltinCommands() {
    return [
        MakeCommand("YearEnd", "Financial year end", "Period dates", (c, t) => FinancialYearEnd(c.Year)),
        MakeCommand("YearStart", "Financial year start", "Period dates", (c, t) => FinancialYearStart(c.Year)),
        MakeCommand("YearRange", "Financial year date range", "Period dates", (c, t) => FinancialYearRange(c.Year)),
        MakeCommand("FinancialYear", "Financial year label", "Period dates", (c, t) => FinancialYearLabel(c.Year)),
        MakeCommand("FYHeading", "Financial year workpaper heading", "Workpapers", (c, t) => "For the year ended " FinancialYearEnd(c.Year)),
        MakeCommand("FYFileLabel", "Financial year filename label", "Workpapers", (c, t) => "FY" c.Year "_" ConvertDate(FinancialYearEnd(c.Year), "File")),
        MakeCommand("YearEndISO", "Financial year end ISO", "Period dates", (c, t) => ConvertDate(FinancialYearEnd(c.Year))),
        MakeCommand("YearStartISO", "Financial year start ISO", "Period dates", (c, t) => ConvertDate(FinancialYearStart(c.Year))),
        MakeCommand("YearEndFile", "Financial year end filename date", "Period dates", (c, t) => ConvertDate(FinancialYearEnd(c.Year), "File")),
        MakeCommand("PreviousYearEnd", "Previous financial year end", "Period dates", (c, t) => CalendarDate(c.Year - 1, 6, 30)),
        MakeCommand("QuarterEnd", "Quarter end", "Period dates", (c, t) => QuarterEnd(c.Year, c.Quarter)),
        MakeCommand("QuarterStart", "Quarter start", "Period dates", (c, t) => QuarterStart(c.Year, c.Quarter)),
        MakeCommand("QuarterRange", "Quarter date range", "Period dates", (c, t) => QuarterRange(c.Year, c.Quarter)),
        MakeCommand("QuarterLabel", "Financial year and quarter label", "Workpapers", (c, t) => "FY " FinancialYearLabel(c.Year) " Q" c.Quarter),
        MakeCommand("QuarterHeading", "Quarter workpaper heading", "Workpapers", (c, t) => "For the quarter ended " QuarterEnd(c.Year, c.Quarter)),
        MakeCommand("QuarterEndISO", "Quarter end ISO", "Period dates", (c, t) => ConvertDate(QuarterEnd(c.Year, c.Quarter))),
        MakeCommand("QuarterEndFile", "Quarter end filename date", "Period dates", (c, t) => ConvertDate(QuarterEnd(c.Year, c.Quarter), "File")),
        MakeCommand("Today", "Today Australian date", "Current dates", (c, t) => AustralianDate(c.Timestamp)),
        MakeCommand("TodayISO", "Today ISO date", "Current dates", (c, t) => IsoDate(c.Timestamp)),
        MakeCommand("TodayFile", "Today filename date", "Current dates", (c, t) => FileDate(c.Timestamp)),
        MakeCommand("Yesterday", "Yesterday Australian date", "Current dates", (c, t) => AustralianDate(DateAdd(c.Timestamp, -1, "Days"))),
        MakeCommand("Tomorrow", "Tomorrow Australian date", "Current dates", (c, t) => AustralianDate(DateAdd(c.Timestamp, 1, "Days"))),
        MakeCommand("DateAU", "Convert date to Australian", "Input dates", (c, t) => ConvertDate(t, "AU"), true, 64),
        MakeCommand("DateISO", "Convert date to ISO", "Input dates", (c, t) => ConvertDate(t, "ISO"), true, 64),
        MakeCommand("DateFile", "Convert date to filename date", "Input dates", (c, t) => ConvertDate(t, "File"), true, 64),
        MakeCommand("MonthStart", "Month start from input date", "Input dates", (c, t) => MonthFromDate(t, "Start"), true, 64),
        MakeCommand("MonthEnd", "Month end from input date", "Input dates", (c, t) => MonthFromDate(t, "End"), true, 64),
        MakeCommand("MonthRange", "Month date range from input date", "Input dates", (c, t) => MonthFromDate(t, "Range"), true, 64),
        MakeCommand("MonthLabel", "Month label from input date", "Input dates", (c, t) => MonthFromDate(t, "Label"), true, 64),
        MakeCommand("ABNFormat", "Format ABN with spaces", "Identifiers", (c, t) => FormatABN(t), true, 64),
        MakeCommand("ABNCheck", "ABN format and checksum report", "Identifiers", (c, t) => IdentifierReport(t, "ABN"), true, 64),
        MakeCommand("ACNFormat", "Format ACN with spaces", "Identifiers", (c, t) => FormatACN(t), true, 64),
        MakeCommand("ACNCheck", "ACN format and checksum report", "Identifiers", (c, t) => IdentifierReport(t, "ACN"), true, 64),
        MakeCommand("TrimText", "Trim surrounding whitespace", "Text", (c, t) => Trim(CheckedText(t), " `t`r`n" Chr(0xA0)), true),
        MakeCommand("TrimLines", "Trim each line", "Text", (c, t) => TrimLines(t), true),
        MakeCommand("CollapseSpaces", "Collapse spaces within each line", "Text", (c, t) => CollapseHorizontalWhitespace(t), true),
        MakeCommand("SingleLine", "Join text into one line", "Text", (c, t) => SingleLine(t), true),
        MakeCommand("LineEndings", "Normalise line endings", "Text", (c, t) => NormaliseLineEndings(t), true),
        MakeCommand("UniqueLines", "Remove duplicate non-empty lines", "Text", (c, t) => UniqueLines(t), true),
        MakeCommand("SortLines", "Sort non-empty lines case sensitively", "Text", (c, t) => SortedLines(t), true),
        MakeCommand("Uppercase", "Uppercase text", "Text", (c, t) => StrUpper(t), true),
        MakeCommand("Lowercase", "Lowercase text", "Text", (c, t) => StrLower(t), true),
        MakeCommand("CSVRow", "Turn lines into a CSV row", "Text", (c, t) => CSVRow(t), true),
        MakeCommand("TSVRow", "Turn lines into a tab-separated row", "Text", (c, t) => TSVRow(t), true),
        MakeCommand("Filename", "Prepare filename text", "Workpapers", (c, t) => PrepareFilenameText(t), true)
    ]
}

ProduceCommand(command, context, input := "") {
    if command.Input
        CheckedText(input, command.MaxInput)
    return CheckedText(command.Produce.Call(context, input))
}

FilterCommands(commands, query) {
    if StrLen(query) > 128
        throw ValueError("Search accepts at most 128 characters.")
    terms := StrSplit(Trim(query), [" ", "`t"])
    result := []
    for item in commands {
        haystack := item.Id " " item.Label " " item.Category
        if item.HasOwnProp("SearchText")
            haystack .= " " item.SearchText
        matches := true
        for term in terms {
            if term != "" && !InStr(haystack, term) {
                matches := false
                break
            }
        }
        if matches
            result.Push(item)
    }
    return result
}

SnippetCommand(item) {
    command := MakeCommand("Snippet:" item.Name, StrReplace(item.Name, "-", " "), "Draft snippets", (c, t) => ExpandSnippet(item.Body, c))
    command.SearchText := item.Body
    return command
}

LoadCommandCatalogue(settings, root := "") {
    if root = ""
        SplitPath(A_LineFile, , &root)
    commands := BuiltinCommands()
    loaded := LoadSnippets([root "\snippets", root "\snippets.local"], {Year: settings.Year, Quarter: settings.Quarter, Timestamp: A_Now})
    for item in loaded.Items
        commands.Push(SnippetCommand(item))
    return {Commands: commands, Errors: loaded.Errors}
}
