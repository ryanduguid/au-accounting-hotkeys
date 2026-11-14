#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\dates.ahk
#Include %A_LineFile%\..\text.ahk

SnippetTokens(context) {
    return Map(
        "TODAY_AU", AustralianDate(context.Timestamp),
        "TODAY_ISO", IsoDate(context.Timestamp),
        "FILE_DATE", FileDate(context.Timestamp),
        "FY_START", FinancialYearStart(context.Year),
        "FY_END", FinancialYearEnd(context.Year),
        "FY_LABEL", FinancialYearLabel(context.Year),
        "FY_RANGE", FinancialYearRange(context.Year),
        "Q_START", QuarterStart(context.Year, context.Quarter),
        "Q_END", QuarterEnd(context.Year, context.Quarter),
        "Q_RANGE", QuarterRange(context.Year, context.Quarter),
        "Q_NUMBER", String(context.Quarter)
    )
}

; Prompted fields: each distinct {{ASK:label}}, in order of first appearance. Labels are case sensitive.
SnippetFields(body) {
    fields := []
    seen := Map()
    position := 1
    while found := RegExMatch(body, "\{\{ASK:([^{}]*)\}\}", &field, position) {
        if !RegExMatch(field[1], "^[A-Za-z0-9][A-Za-z0-9 _-]{0,39}\z")
            throw ValueError("Field labels must start with an ASCII letter or digit and use at most 40 ASCII letters, digits, spaces, underscores or hyphens.")
        if !seen.Has(field[1]) {
            seen[field[1]] := true
            fields.Push(field[1])
            if fields.Length > 10
                throw ValueError("A snippet may ask for at most 10 fields.")
        }
        position := found + field.Len
    }
    return fields
}

; answers holds one line per field, in SnippetFields order. Without answers, each field shows as [label].
; Answers are inserted once, so a token typed in an answer stays text.
ExpandSnippet(body, context, answers := "") {
    CheckedText(body, 16384)
    tokens := SnippetTokens(context)
    fields := SnippetFields(body)
    if answers = "" {
        for label in fields
            tokens["ASK:" label] := "[" label "]"
    } else {
        if fields.Length = 0
            throw ValueError("This snippet has no fields to answer.")
        lines := StrSplit(RTrim(NormaliseLineEndings(answers), "`n"), "`n")
        if lines.Length != fields.Length
            throw ValueError("Type " fields.Length " answers, one per line: " JoinLines(fields, ", ") ".")
        for label in fields {
            answer := Trim(lines[A_Index], " `t")
            if answer = "" || StrLen(answer) > 200
                throw ValueError("Answer " label " in 1 to 200 characters.")
            tokens["ASK:" label] := answer
        }
    }
    result := ""
    position := 1
    count := 0
    while found := RegExMatch(body, "\{\{([^{}]*)\}\}", &token, position) {
        count += 1
        if count > 100
            throw ValueError("A snippet may contain at most 100 tokens.")
        literal := SubStr(body, position, found - position)
        CheckTokenDelimiters(literal)
        result .= literal (tokens.Has(token[1]) ? tokens[token[1]] : ShiftedDateToken(token[1], context))
        position := found + token.Len
    }
    remainder := SubStr(body, position)
    CheckTokenDelimiters(remainder)
    return CheckedText(result remainder)
}

; {{TODAY_AU+N}} is N calendar days after today. {{DUE_AU+N}} is that date moved off a weekend
; or public holiday for the [Holidays] State, as BusinessDueDate does. N is 1 to 999.
ShiftedDateToken(name, context) {
    if !RegExMatch(name, "^(TODAY|DUE)_AU\+(.*)\z", &parts)
        throw ValueError("Snippet contains an unknown token.")
    if !RegExMatch(parts[2], "^[1-9][0-9]{0,2}\z")
        throw ValueError("Shift " parts[1] "_AU by 1 to 999 days, such as {{" parts[1] "_AU+14}}.")
    date := AustralianDate(DateAdd(context.Timestamp, Integer(parts[2]), "Days"))
    if parts[1] = "TODAY"
        return date
    return BusinessDueDate(date, context.HasOwnProp("HolidayState") ? context.HolidayState : "")
}

CheckTokenDelimiters(text) {
    if InStr(text, "{{") || InStr(text, "}}")
        throw ValueError("Snippet contains an incomplete token.")
}

ReadUtf8Snippet(path) {
    handle := FileOpen(path, "r")
    if !IsObject(handle)
        throw ValueError("Snippet could not be opened for reading.")
    try {
        length := handle.Length
        if length = 0 || length > 65536
            throw ValueError("Snippet must contain 1 to 65,536 UTF-8 bytes.")
        bytes := Buffer(length)
        handle.Pos := 0
        if handle.RawRead(bytes, length) != length
            throw ValueError("Snippet could not be read completely.")
    } finally handle.Close()
    characters := DllCall("MultiByteToWideChar", "UInt", 65001, "UInt", 8, "Ptr", bytes, "Int", length, "Ptr", 0, "Int", 0)
    if characters = 0
        throw ValueError("Snippet must be well-formed UTF-8.")
    wide := Buffer(characters * 2)
    if DllCall("MultiByteToWideChar", "UInt", 65001, "UInt", 8, "Ptr", bytes, "Int", length, "Ptr", wide, "Int", characters) != characters
        throw ValueError("Snippet could not be decoded.")
    body := StrGet(wide, characters, "UTF-16")
    if SubStr(body, 1, 1) = Chr(0xFEFF)
        body := SubStr(body, 2)
    ; StrGet stops at NUL, so reject embedded NUL before accepting the decoded text.
    Loop characters {
        if NumGet(wide, (A_Index - 1) * 2, "UShort") = 0
            throw ValueError("Snippet contains a NUL character.")
    }
    return CheckedText(body, 16384)
}

LoadSnippets(directories, context) {
    result := {Items: [], Errors: []}
    names := Map()
    names.CaseSense := "Off"
    total := 0
    attempts := 0
    for directory in directories {
        if !DirExist(directory)
            continue
        if InStr(FileGetAttrib(directory), "L") {
            result.Errors.Push("Linked snippet directories are not loaded.")
            continue
        }
        paths := ""
        directoryCount := 0
        Loop Files directory "\*.txt", "F" {
            directoryCount += 1
            if directoryCount > 100
                break
            paths .= A_LoopFileFullPath "`n"
        }
        if directoryCount > 100 {
            result.Errors.Push("A snippet directory exceeds 100 text files and was excluded.")
            continue
        }
        for path in StrSplit(RTrim(Sort(paths), "`r`n"), "`n", "`r") {
            if path = ""
                continue
            attempts += 1
            if attempts > 100 {
                result.Errors.Push("Only the first 100 snippet files are considered.")
                return result
            }
            SplitPath(path, , , , &name)
            try {
                if !RegExMatch(name, "^[A-Za-z0-9][A-Za-z0-9 _-]{0,79}\z")
                    throw ValueError("Snippet labels must start with an ASCII letter or digit, use only ASCII letters, digits, spaces, underscores or hyphens, and contain at most 80 characters.")
                if names.Has(name)
                    throw ValueError("Duplicate snippet label.")
                if InStr(FileGetAttrib(path), "L")
                    throw ValueError("Linked snippet files are not loaded.")
                body := ReadUtf8Snippet(path)
                ExpandSnippet(body, context)
                if total + StrLen(body) > 262144
                    throw ValueError("Total snippet text exceeds 262,144 characters.")
                total += StrLen(body)
                names[name] := true
                result.Items.Push({Name: name, Body: body})
            } catch Error as problem {
                result.Errors.Push(name ": " problem.Message)
            }
        }
    }
    return result
}
