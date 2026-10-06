#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\text.ahk

IdentifierDigits(text, count) {
    CheckedText(text, 64)
    if !RegExMatch(text, "^[0-9 ]+\z")
        throw ValueError("Identifiers accept digits and ordinary spaces only.")
    digits := StrReplace(text, " ")
    if StrLen(digits) != count
        throw ValueError("Identifier must contain exactly " count " digits.")
    return digits
}

FormatABN(text) {
    digits := IdentifierDigits(text, 11)
    return SubStr(digits, 1, 2) " " SubStr(digits, 3, 3) " " SubStr(digits, 6, 3) " " SubStr(digits, 9, 3)
}

ABNChecksumPasses(text) {
    try digits := IdentifierDigits(text, 11)
    catch ValueError
        return false
    if SubStr(digits, 1, 1) = "0"
        return false
    weights := [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19]
    total := 0
    Loop 11
        total += (Integer(SubStr(digits, A_Index, 1)) - (A_Index = 1 ? 1 : 0)) * weights[A_Index]
    return Mod(total, 89) = 0
}

FormatACN(text) {
    digits := IdentifierDigits(text, 9)
    return SubStr(digits, 1, 3) " " SubStr(digits, 4, 3) " " SubStr(digits, 7, 3)
}

ACNChecksumPasses(text) {
    try digits := IdentifierDigits(text, 9)
    catch ValueError
        return false
    total := 0
    Loop 8
        total += Integer(SubStr(digits, A_Index, 1)) * (9 - A_Index)
    return Mod(10 - Mod(total, 10), 10) = Integer(SubStr(digits, 9, 1))
}

IdentifierReport(text, kind) {
    switch kind {
        case "ABN":
            formatted := FormatABN(text)
            passes := ABNChecksumPasses(text)
        case "ACN":
            formatted := FormatACN(text)
            passes := ACNChecksumPasses(text)
        default: throw ValueError("Identifier type must be ABN or ACN.")
    }
    return kind " " formatted "`nFormat/checksum: " (passes ? "passes" : "fails")
        . "`nRegistry/existence/status: not checked"
}
