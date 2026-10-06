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

ExpandSnippet(body, context) {
    CheckedText(body, 16384)
    tokens := SnippetTokens(context)
    result := ""
    position := 1
    count := 0
    while found := RegExMatch(body, "\{\{([^{}]*)\}\}", &token, position) {
        count += 1
        if count > 100
            throw ValueError("A snippet may contain at most 100 tokens.")
        literal := SubStr(body, position, found - position)
        CheckTokenDelimiters(literal)
        if !tokens.Has(token[1])
            throw ValueError("Snippet contains an unknown token.")
        result .= literal tokens[token[1]]
        position := found + token.Len
    }
    remainder := SubStr(body, position)
    CheckTokenDelimiters(remainder)
    return CheckedText(result remainder)
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
                    throw ValueError("Snippet labels must use letters, digits, spaces, underscores or hyphens.")
                if names.Has(name)
                    throw ValueError("Duplicate snippet label.")
                names[name] := true
                if InStr(FileGetAttrib(path), "L")
                    throw ValueError("Linked snippet files are not loaded.")
                body := ReadUtf8Snippet(path)
                ExpandSnippet(body, context)
                if total + StrLen(body) > 262144
                    throw ValueError("Total snippet text exceeds 262,144 characters.")
                total += StrLen(body)
                result.Items.Push({Name: name, Body: body})
            } catch Error as problem {
                result.Errors.Push(name ": " problem.Message)
            }
        }
    }
    return result
}
