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

; Prompted fields: each distinct {{ASK:label}} or {{PICK:label|choice|choice}}, in order of first
; appearance. Labels are case sensitive.
SnippetFields(body) {
    return ReadSnippetFields(body).Labels
}

; Labels in order, the token text of each and, for a choice field, its choices. A label used again
; must repeat its token exactly, so one answer fills every use.
ReadSnippetFields(body) {
    fields := {Labels: [], Tokens: Map(), Choices: Map()}
    position := 1
    while found := RegExMatch(body, "\{\{(ASK|PICK):([^{}]*)\}\}", &field, position) {
        position := found + field.Len
        token := field[1] ":" field[2]
        choices := StrSplit(field[2], "|")
        label := field[1] = "ASK" ? field[2] : choices.RemoveAt(1)
        if !RegExMatch(label, "^[A-Za-z0-9][A-Za-z0-9 _-]{0,39}\z")
            throw ValueError("Field labels must start with an ASCII letter or digit and use at most 40 ASCII letters, digits, spaces, underscores or hyphens.")
        if fields.Tokens.Has(label) {
            if fields.Tokens[label] !== token
                throw ValueError("Field " label " is used with different choices; repeat the same token.")
            continue
        }
        if field[1] = "ASK"
            choices := ""
        else
            CheckChoices(label, choices)
        fields.Labels.Push(label)
        fields.Tokens[label] := token
        fields.Choices[label] := choices
        if fields.Labels.Length > 10
            throw ValueError("A snippet may ask for at most 10 fields.")
    }
    return fields
}

; The | separator cannot be escaped, so a choice never contains it.
CheckChoices(label, choices) {
    if choices.Length < 2 || choices.Length > 10
        throw ValueError("Choice field " label " needs 2 to 10 choices separated by |.")
    seen := Map()
    for choice in choices {
        if choice = "" || StrLen(choice) > 100 || choice !== Trim(choice, " ") || RegExMatch(choice, "[\x00-\x1F\x7F\x{85}\x{2028}\x{2029}]")
            throw ValueError("Each choice for " label " needs 1 to 100 characters, no spaces at either end and no control characters.")
        if seen.Has(choice)
            throw ValueError("Choice field " label " lists " choice " twice.")
        seen[choice] := true
    }
}

; answers holds one line per field, in SnippetFields order. Without answers, each field shows as
; [label], or [label: choice / choice] for a choice field. A choice answer must match a choice exactly.
; Answers are inserted once, so a token typed in an answer stays text.
ExpandSnippet(body, context, answers := "") {
    CheckedText(body, 16384)
    tokens := SnippetTokens(context)
    fields := ReadSnippetFields(body)
    labels := fields.Labels
    if answers = "" {
        for label in labels {
            choices := fields.Choices[label]
            tokens[fields.Tokens[label]] := "[" label (IsObject(choices) ? ": " JoinLines(choices, " / ") : "") "]"
        }
    } else {
        if labels.Length = 0
            throw ValueError("This snippet has no fields to answer.")
        lines := StrSplit(RTrim(NormaliseLineEndings(answers), "`n"), "`n")
        if lines.Length != labels.Length
            throw ValueError("Type " labels.Length " answers, one per line: " JoinLines(labels, ", ") ".")
        for label in labels {
            answer := Trim(lines[A_Index], " `t")
            if answer = "" || StrLen(answer) > 200
                throw ValueError("Answer " label " in 1 to 200 characters.")
            choices := fields.Choices[label]
            if IsObject(choices) {
                matched := false
                for choice in choices
                    matched := matched || choice == answer
                if !matched
                    throw ValueError("Answer " label " with one of: " JoinLines(choices, ", ") ".")
            }
            tokens[fields.Tokens[label]] := answer
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

ReadUtf8Snippet(path, maximum := 16384) {
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
    return CheckedText(body, maximum)
}

; Reads AutoHotkey hotstrings (:options:abbreviation::replacement) as snippets without running
; anything. Only replacements that type literal text load; every other entry is reported by line.
SnippetsFromHotstrings(source) {
    result := {Items: [], Errors: []}
    lines := StrSplit(NormaliseLineEndings(source), "`n")
    index := 0
    inComment := false
    while index < lines.Length {
        index += 1
        line := lines[index]
        if inComment || RegExMatch(line, "^[ `t]*/\*") {
            inComment := !InStr(line, "*/")
            continue
        }
        ; A directive that sets default options changes every entry below it, as X would.
        if RegExMatch(line, "^[ `t]*#(\w+)[ `t]*(\S*)", &directive) && directive[1] = "Hotstring" && !RegExMatch(directive[2], "i)^(EndChars|NoMouse)\z")
            throw ValueError("line " index ": #" directive[1] " changes the default options; set options on each entry instead.")
        if !RegExMatch(line, "^[ `t]*:([^:]*):(.+?)::(.*)\z", &entry)
            continue
        start := index
        try {
            mode := ""
            options := entry[1]
            while options != "" {
                if !RegExMatch(options, "i)^(?:[ `t]+|\*0?|\?0?|B0?|C[01]?|K-?[0-9]+|O0?|P[0-9]+|S[IPE]|Z0?|(T0?|R0?|X))", &option)
                    throw ValueError("Unknown option in :" entry[1] ":.")
                if option[1] = "X"
                    throw ValueError("Runs code instead of typing text.")
                if option[1] != ""
                    mode := SubStr(option[1], 2) = "0" ? "send" : "text"
                options := SubStr(options, option.Len + 1)
            }
            name := AhkUnescape(entry[2])
            if !RegExMatch(name, "^[!-~]{1,40}\z")
                throw ValueError("The abbreviation becomes the label, so it must be 1 to 40 ASCII letters, digits or symbols, without spaces.")
            text := WithoutComment(entry[3])
            if text = "" {
                if index = lines.Length || !RegExMatch(lines[index + 1], "^[ `t]*\((.*)\z", &opening)
                    throw ValueError("Runs code instead of typing text.")
                index += 1
                section := []
                closing := ""
                while index < lines.Length {
                    index += 1
                    if RegExMatch(lines[index], "^[ `t]*\)(.*)\z", &closing)
                        break
                    section.Push(lines[index])
                }
                if !IsObject(closing)
                    throw ValueError("The continuation section has no closing parenthesis.")
                if WithoutComment(opening[1]) != "" || WithoutComment(closing[1]) != ""
                    throw ValueError("Continuation options and text after the closing parenthesis are not supported.")
                text := ContinuationText(section)
                ; A continuation section types as text unless an option says otherwise.
                mode := mode = "" ? "text" : mode
            }
            text := AhkUnescape(text)
            if mode != "text" && RegExMatch(text, "[{}^!+#]")
                throw ValueError("Uses key syntax such as {Enter}, ^c or !; add the T option to load it as text.")
            result.Items.Push({Name: name, Body: text, Line: start})
        } catch ValueError as problem {
            result.Errors.Push("line " start ", " entry[2] ": " problem.Message)
        }
    }
    return result
}

; A semicolon with a space or tab to its left starts a comment; trailing spaces and tabs are dropped.
WithoutComment(text) {
    return RTrim(RegExReplace(text, "[ `t]+;.*"), " `t")
}

; Joins continuation lines as AutoHotkey does by default: the first line's leading spaces or tabs
; are removed from each line that starts with them, and trailing spaces and tabs are removed.
ContinuationText(section) {
    indent := section.Length && RegExMatch(section[1], "^( +|`t+)", &lead) ? lead[1] : ""
    text := ""
    for line in section {
        if indent != "" && SubStr(line, 1, StrLen(indent)) == indent
            line := SubStr(line, StrLen(indent) + 1)
        text .= (A_Index = 1 ? "" : "`n") RTrim(line, " `t")
    }
    return text
}

AhkUnescape(text) {
    static sequences := Map("``", "``", ";", ";", ":", ":", "{", "{", "n", "`n", "r", "`r", "t", "`t", "s", " ", '"', '"', "'", "'")
    result := ""
    position := 1
    while found := RegExMatch(text, "``(.?)", &escape, position) {
        if !sequences.Has(escape[1])
            throw ValueError("Unsupported escape sequence ``" escape[1] ".")
        result .= SubStr(text, position, found - position) sequences[escape[1]]
        position := found + escape.Len
    }
    return result SubStr(text, position)
}

; A .txt file is one snippet named after the file; an .ahk file holds hotstrings.
SnippetFileEntries(path, name, extension) {
    if extension != "ahk" && !RegExMatch(name, "^[A-Za-z0-9][A-Za-z0-9 _-]{0,79}\z")
        throw ValueError("Snippet labels must start with an ASCII letter or digit, use only ASCII letters, digits, spaces, underscores or hyphens, and contain at most 80 characters.")
    if InStr(FileGetAttrib(path), "L")
        throw ValueError("Linked snippet files are not loaded.")
    if extension != "ahk"
        return {Items: [{Name: name, Body: ReadUtf8Snippet(path)}], Errors: []}
    loaded := SnippetsFromHotstrings(ReadUtf8Snippet(path, 65536))
    if loaded.Items.Length = 0 && loaded.Errors.Length = 0
        throw ValueError("No hotstrings found.")
    return loaded
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
        for pattern in ["*.txt", "*.ahk"] {
            Loop Files directory "\" pattern, "F" {
                directoryCount += 1
                if directoryCount > 100
                    break
                paths .= A_LoopFileFullPath "`n"
            }
        }
        if directoryCount > 100 {
            result.Errors.Push("A snippet directory exceeds 100 snippet files and was excluded.")
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
            SplitPath(path, , , &extension, &name)
            source := extension = "ahk" ? name ".ahk" : name
            try loaded := SnippetFileEntries(path, name, extension)
            catch Error as problem {
                result.Errors.Push(source ": " problem.Message)
                continue
            }
            problems := loaded.Errors
            capped := false
            for entry in loaded.Items {
                if result.Items.Length = 1000 {
                    capped := true
                    break
                }
                try {
                    if names.Has(entry.Name)
                        throw ValueError("Duplicate snippet label.")
                    ExpandSnippet(entry.Body, context)
                    if total + StrLen(entry.Body) > 262144
                        throw ValueError("Total snippet text exceeds 262,144 characters.")
                    total += StrLen(entry.Body)
                    names[entry.Name] := true
                    result.Items.Push({Name: entry.Name, Body: entry.Body})
                } catch Error as problem {
                    problems.Push((entry.HasOwnProp("Line") ? "line " entry.Line ", " entry.Name ": " : "") problem.Message)
                }
            }
            ; One .ahk file can hold hundreds of entries, so each file lists at most 10 problems.
            for problem in problems {
                if A_Index > 10 {
                    result.Errors.Push(source ": " (problems.Length - 10) " more entries were not loaded.")
                    break
                }
                result.Errors.Push(source ": " problem)
            }
            if capped {
                result.Errors.Push("Only the first 1,000 snippets are loaded.")
                return result
            }
        }
    }
    return result
}
