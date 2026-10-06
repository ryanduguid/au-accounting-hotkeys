#Requires AutoHotkey v2.0

CheckedText(text, maximum := 32768) {
    if Type(text) != "String" || text = ""
        throw ValueError("Text must not be empty.")
    if StrLen(text) > maximum
        throw ValueError("Text exceeds the " maximum " character limit; it was not truncated.")
    if RegExMatch(text, "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]")
        throw ValueError("Text contains unsupported control characters.")
    return text
}

NormaliseLineEndings(text) {
    return StrReplace(StrReplace(CheckedText(text), "`r`n", "`n"), "`r", "`n")
}

TrimLines(text) {
    result := ""
    for line in StrSplit(NormaliseLineEndings(text), "`n")
        result .= (A_Index = 1 ? "" : "`n") Trim(line, " `t" Chr(0xA0))
    return CheckedText(result)
}

CollapseHorizontalWhitespace(text) {
    return RegExReplace(TrimLines(text), "[ `t\x{00A0}]+", " ")
}

SingleLine(text) {
    return CheckedText(Trim(RegExReplace(CheckedText(text), "[\s\x{00A0}]+", " ")))
}

NonEmptyLines(text) {
    lines := []
    for line in StrSplit(TrimLines(text), "`n") {
        if line != ""
            lines.Push(line)
    }
    return lines
}

JoinLines(lines, separator := "`n") {
    result := ""
    for line in lines
        result .= (A_Index = 1 ? "" : separator) line
    return CheckedText(result)
}

UniqueLines(text) {
    seen := Map()
    seen.CaseSense := "On"
    result := []
    for line in NonEmptyLines(text) {
        if !seen.Has(line) {
            seen[line] := true
            result.Push(line)
        }
    }
    return JoinLines(result)
}

SortedLines(text) {
    return Sort(JoinLines(NonEmptyLines(text)), "C")
}

CSVRow(text) {
    fields := []
    for line in NonEmptyLines(text) {
        if InStr(line, ',') || InStr(line, '"')
            line := '"' StrReplace(line, '"', '""') '"'
        fields.Push(line)
    }
    return JoinLines(fields, ",")
}

TSVRow(text) {
    lines := NonEmptyLines(text)
    for line in lines {
        if InStr(line, "`t")
            throw ValueError("Each input line must contain one value without tabs.")
    }
    return JoinLines(lines, "`t")
}

PrepareFilenameText(text) {
    text := RegExReplace(SingleLine(text), '[<>:"/\\|?*]', "_")
    text := RTrim(text, " .")
    if text = ""
        throw ValueError("Filename text is empty after preparation.")
    if RegExMatch(text, "i)^(CON|PRN|AUX|NUL|COM[1-9\x{00B9}\x{00B2}\x{00B3}]|LPT[1-9\x{00B9}\x{00B2}\x{00B3}])(?:\.|$)")
        text := "_" text
    return CheckedText(text, 200)
}

LooksLikeFormula(text) {
    for cell in StrSplit(NormaliseLineEndings(text), ["`n", "`t", ","]) {
        if RegExMatch(cell, '^[\s\x{00A0}]*"?[=+@-]')
            return true
    }
    return false
}
