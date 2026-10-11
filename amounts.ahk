#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\text.ahk

ParseAmountCents(text) {
    line := Trim(text, " `t" Chr(0xA0))
    if RegExMatch(line, "i)[0-9)][ `t\x{00A0}]*(?:CR|DR)\z")
        throw ValueError("CR/DR suffix is ambiguous; replace it with an explicit sign.")
    if !RegExMatch(line, "^(?:(-)|(\())?\$?([0-9]{1,12}|[1-9][0-9]{0,2}(?:,[0-9]{3}){1,3})(?:\.([0-9]{1,2}))?(?(2)\))\z", &parts)
        throw ValueError("Use an amount such as 1234.56, -1,234.56 or ($1,234.56), with at most 12 whole-dollar digits and 2 decimal places.")
    cents := Integer(StrReplace(parts[3], ",")) * 100 + Integer(SubStr(parts[4] "00", 1, 2))
    return parts[1] != "" || parts[2] != "" ? -cents : cents
}

; Larger amounts exceed the 15 significant digits Excel keeps for numbers. Comparing before
; any arithmetic also keeps library callers away from 64-bit integer wraparound.
CheckedCents(cents) {
    if Type(cents) != "Integer" || cents > 999999999999999 || cents < -999999999999999
        throw ValueError("Amount must be whole cents within 9,999,999,999,999.99 either side of zero; it was not rounded.")
    return cents
}

FormatCents(cents, separators := false) {
    whole := String(Abs(CheckedCents(cents)) // 100)
    if separators
        whole := RegExReplace(whole, "[0-9](?=(?:[0-9]{3})+\z)", "$0,")
    return (cents < 0 ? "-" : "") whole "." Format("{:02}", Mod(Abs(cents), 100))
}

; Rounds cents / divisor to the nearest cent, with exact half cents away from zero.
RoundedShare(cents, divisor) {
    if Type(divisor) != "Integer" || divisor < 1 || divisor > 100
        throw ValueError("Divisor must be a whole number from 1 to 100.")
    share := (2 * Abs(CheckedCents(cents)) + divisor) // (2 * divisor)
    return cents < 0 ? -share : share
}

GSTOnExclusive(cents) {
    return RoundedShare(cents, 10)
}

GSTInInclusive(cents) {
    return RoundedShare(cents, 11)
}

; Applies transform to each amount line; blank lines stay blank so pasted columns keep their rows.
AmountLines(text, transform, separators := false) {
    lines := StrSplit(NormaliseLineEndings(text), "`n")
    found := false
    for index, line in lines {
        if Trim(line, " `t" Chr(0xA0)) = "" {
            lines[index] := ""
            continue
        }
        try lines[index] := FormatCents(transform(ParseAmountCents(line)), separators)
        catch ValueError as problem
            throw ValueError("Line " index ": " problem.Message)
        found := true
    }
    if !found
        throw ValueError("Enter at least one amount.")
    return JoinLines(lines)
}

TotalAmounts(text) {
    total := 0
    found := false
    for index, line in StrSplit(NormaliseLineEndings(text), "`n") {
        if Trim(line, " `t" Chr(0xA0)) = ""
            continue
        try total += ParseAmountCents(line)
        catch ValueError as problem
            throw ValueError("Line " index ": " problem.Message)
        found := true
    }
    if !found
        throw ValueError("Enter at least one amount.")
    return FormatCents(total)
}
