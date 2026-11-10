#Requires AutoHotkey v2.0

; Seeded property tests exercise the native helpers, without clipboard or keyboard access.
TestGeneratedInputs() {
    commands := BuiltinCommands()
    sequence := GeneratedRandom(1)
    AssertEqual(sequence.Next(0, 2147483646), 182605794, "Repeatable generator first pair")
    AssertEqual(sequence.Next(0, 2147483646), 1914720637, "Repeatable generator second pair")
    for seed in [1, 0x5EED] {
        rng := GeneratedRandom(seed)
        Loop 500 {
            iteration := A_Index
            try {
                FuzzAmounts(iteration, rng)
                FuzzDates(rng)
                FuzzWorkpaperArithmetic(rng)
                FuzzCommandInputs(commands, rng)
            } catch Error as problem {
                throw Error("Generated inputs: seed " seed ", case " iteration ": " problem.Message
                    . "`n" problem.What ": " problem.Extra "`n" problem.Stack)
            }
        }
    }
}

; AutoHotkey v2's Random cannot be seeded. A test-only Park-Miller generator
; keeps cases reproducible on both architectures; two draws cover large amounts.
class GeneratedRandom {
    __New(seed) {
        this.State := seed
    }

    Next(minimum, maximum) {
        this.State := Mod(this.State * 48271, 2147483647)
        high := this.State
        this.State := Mod(this.State * 48271, 2147483647)
        return minimum + Mod(high * 2147483647 + this.State, maximum - minimum + 1)
    }
}

FuzzAmounts(iteration, rng) {
    edges := [0, 1, -1, 99, -99, 100, -100, 99999999999999, -99999999999999]
    cents := iteration <= edges.Length ? edges[iteration] : rng.Next(-99999999999999, 99999999999999)
    plain := FormatCents(cents)
    AssertEqual(ParseAmountCents(plain), cents, "Generated amount round trip")
    AssertEqual(ParseAmountCents(FormatCents(cents, true)), cents, "Generated grouped amount round trip")
    AssertEqual(TotalAmounts(plain "`n" FormatCents(-cents)), "0.00", "Generated opposite amounts cancel")

    divisor := rng.Next(1, 100)
    magnitude := Abs(cents)
    expected := magnitude // divisor + (Mod(magnitude, divisor) * 2 >= divisor ? 1 : 0)
    if cents < 0
        expected := -expected
    AssertEqual(RoundedShare(cents, divisor), expected, "Generated exact rounding against quotient and remainder")
    for suffix in ["x", " CR", " DR", ".001"]
        AssertValueError(ParseAmountCents.Bind(plain suffix), "Generated malformed amount rejected")
}

FuzzDates(rng) {
    ; Windows date arithmetic is the oracle, independent of the helper's month/leap rules.
    timestamp := DateAdd(Format("{:04}0101000000", rng.Next(1601, 9998)), rng.Next(0, 364), "Days")
    expected := FormatTime(timestamp, "yyyy-MM-dd")
    for dateFormat in ["dd/MM/yyyy", "yyyy-MM-dd", "yyyyMMdd"] {
        text := FormatTime(timestamp, dateFormat)
        AssertEqual(ConvertDate(text), expected, "Generated date formats agree with Windows")
        AssertValueError(ParseStrictDate.Bind(text "x"), "Generated date trailing garbage rejected")
    }
    AssertValueError(ParseStrictDate.Bind(FormatTime(timestamp, "yyyy-MM") "-00"), "Generated day zero rejected")
    AssertValueError(ParseStrictDate.Bind(FormatTime(timestamp, "yyyy") "-13-01"), "Generated month thirteen rejected")
}

FuzzWorkpaperArithmetic(rng) {
    ; Swapping 2 digits of an amount, or doubling it, must produce the matching hint.
    digits := String(rng.Next(10, 99999999999999))
    first := rng.Next(1, StrLen(digits))
    second := rng.Next(1, StrLen(digits))
    swapped := digits
    swapped := SubStr(swapped, 1, first - 1) SubStr(digits, second, 1) SubStr(swapped, first + 1)
    swapped := SubStr(swapped, 1, second - 1) SubStr(digits, first, 1) SubStr(swapped, second + 1)
    difference := Integer(digits) - Integer(swapped)
    hint := DifferenceCheck(FormatCents(difference))
    AssertEqual(difference = 0 || InStr(hint, "`nDivisible by 9 (") > 0, true, "Generated transposition is divisible by 9")
    posted := rng.Next(1, 49999999999999)
    AssertEqual(InStr(DifferenceCheck(FormatCents(-2 * posted)), "`nHalf the difference is " FormatCents(posted, true) ". ") > 0, true, "Generated wrong-side posting is half the difference")

    ; DaysBetween uses Windows DateDiff, an independent oracle for the offset and terms commands.
    start := ConvertDate(FormatTime(DateAdd(Format("{:04}0101", rng.Next(1611, 9988)), rng.Next(0, 364), "Days"), "yyyyMMdd"), "AU")
    days := rng.Next(0, 3000)
    AssertEqual(DaysBetween(start " to " DateOffset(start " + " days " days")), String(days), "Generated day offset agrees with DateDiff")
    AssertEqual(DaysBetween(start " to " DateOffset(start " - " days " days")), String(-days), "Generated negative day offset agrees with DateDiff")
    AssertEqual(DueDate(start " net " days), DateOffset(start " + " days " days"), "Generated net terms equal a day offset")
    expectedBucket := days = 0 ? "Current" : days <= 30 ? "1 to 30 days overdue" : days <= 60 ? "31 to 60 days overdue" : days <= 90 ? "61 to 90 days overdue" : "Over 90 days overdue"
    AssertEqual(AgeingBucket(start " to " DateOffset(start " + " days " days")), expectedBucket, "Generated ageing bucket edges")

    months := rng.Next(-120, 120)
    date := ParseStrictDate(start)
    shifted := ParseStrictDate(DateOffset(start (months < 0 ? " - " : " + ") Abs(months) " months"))
    AssertEqual((shifted.Year * 12 + shifted.Month) - (date.Year * 12 + date.Month), months, "Generated month offset moves whole months")
    AssertEqual(shifted.Day, Min(date.Day, DaysInMonth(shifted.Year, shifted.Month)), "Generated month offset keeps the day or ends the month")

    following := NextWeekday(start)
    gap := Integer(DaysBetween(start " to " following))
    weekday := Integer(FormatTime(ConvertDate(following, "File"), "WDay"))
    AssertEqual(weekday >= 2 && weekday <= 6 && gap >= 1 && gap <= 3, true, "Generated next weekday is the first weekday after the date")
    AssertEqual(gap = 1 || Integer(FormatTime(DateAdd(ConvertDate(following, "File"), -1, "Days"), "WDay")) = 1, true, "Generated next weekday skips only a weekend")

    ; Decimal hours stay within half a hundredth of the exact minutes.
    begin := rng.Next(0, 1439)
    finish := rng.Next(begin + 1, 1440)
    hours := DurationHours(Format("{:02}:{:02} to {:02}:{:02}", begin // 60, Mod(begin, 60), finish // 60, Mod(finish, 60)))
    AssertEqual(Abs(Integer(StrReplace(hours, ".")) * 60 - (finish - begin) * 100) <= 30, true, "Generated decimal hours round to the nearest hundredth")
}

FuzzCommandInputs(commands, rng) {
    context := {Year: rng.Next(1900, 9998), Quarter: rng.Next(1, 4), Timestamp: "20240229000000"}
    alphabet := 'aZ09 ,."{}[]()<>%$=+@-/\_éΩ中' "`t`r`n"
    text := ""
    Loop rng.Next(0, 96)
        text .= SubStr(alphabet, rng.Next(1, StrLen(alphabet)), 1)
    ; Exclude the three supported whitespace controls: tab, LF and CR.
    controls := [0, 1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 127]
    position := rng.Next(0, StrLen(text))
    invalid := SubStr(text, 1, position) Chr(controls[rng.Next(1, controls.Length)]) SubStr(text, position + 1)
    for command in commands {
        if !command.Input
            continue
        AssertValueError(ProduceCommand.Bind(command, context, invalid), "Generated control character rejected by " command.Id)
        try output := ProduceCommand(command, context, text)
        catch ValueError
            continue ; Arbitrary text need not satisfy a date, identifier or amount grammar.
        AssertEqual(Type(output), "String", "Generated output type for " command.Id)
        AssertEqual(StrLen(output) > 0 && StrLen(output) <= 32768, true, "Generated output bounds for " command.Id)
        AssertEqual(RegExMatch(output, "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]"), 0, "Generated output controls for " command.Id)
    }
}
