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
