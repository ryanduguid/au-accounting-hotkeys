#Requires AutoHotkey v2.0

; Opt-in shortcuts that format the selected cells in the active Excel window. Each takes a Range
; and returns what it applied. Excel cannot undo a change made through its object model.
ExcelCommands() {
    static accounting := ['#,##0_);(#,##0);"-"_)', '#,##0.00_);(#,##0.00);"-"_)']
    return Map(
        "ExcelAccounting", range => CycleNumberFormat(range, accounting),
        "ExcelThousands", range => CycleNumberFormat(range, ['#,##0,_);(#,##0,);"-"_)', accounting[1]]),
        "ExcelPercent", range => CycleNumberFormat(range, ['0.0%_);(0.0%);"-"_)', '0.00%_);(0.00%);"-"_)']),
        "ExcelDates", range => CycleNumberFormat(range, ["dd/mm/yyyy", "d mmm yyyy", "mmm-yy", "yyyy-mm-dd"]),
        "ExcelColourCode", ColourCodeCells,
        "ExcelCentreAcross", CentreAcrossSelection,
        "ExcelToggleSign", range => ScaleCells(range, "negate"),
        "ExcelDivide1000", range => ScaleCells(range, "divide"),
        "ExcelMultiply1000", range => ScaleCells(range, "multiply"),
        "ExcelCopyFormulas", CopyExactFormulas,
        "ExcelPasteFormulas", PasteExactFormulas
    )
}

; Number constants and formulas returning numbers. A constant is multiplied in place; a formula is
; wrapped, or unwrapped when the opposite shortcut wrapped it, so pressing it again reverses it.
ScaleCells(range, operation) {
    static reported := Map("negate", "Sign changed in ", "divide", "Divided ", "multiply", "Multiplied ")
    cells := []
    if range.CountLarge = 1 {
        cells.Push(range)
    } else {
        ; xlCellTypeConstants and xlCellTypeFormulas, both with xlNumbers.
        for kind in [2, -4123] {
            try
                found := range.SpecialCells(kind, 1)
            catch
                continue  ; Excel throws when no cell matches.
            if cells.Length + found.CountLarge > 10000
                throw ValueError("Select at most 10,000 numbers and formulas.")
            for cell in found
                cells.Push(cell)
        }
    }
    ; Every new value is worked out before the first write, so a write cannot feed a later one.
    writes := []
    for cell in cells {
        ; Text, errors, dates, times and legacy array formulas stay as they are.
        if !(cell.Value2 is Number) || cell.HasArray || DateOrTimeFormat(cell.NumberFormat)
            continue
        property := FormulaProperty(cell)
        formula := cell.%property%
        if cell.HasFormula
            writes.Push([cell, property, ScaledFormula(formula, operation)])
        else if formula != ""  ; A cell in a spilled array has a value but no formula of its own.
            writes.Push([cell, "Value2", ScaledNumber(cell.Value2, operation)])
    }
    if !writes.Length
        return "No numbers or formulas returning numbers in the selection."
    WriteCells(range, writes)
    return reported[operation] writes.Length (writes.Length = 1 ? " cell" : " cells") (operation = "negate" ? "" : " by 1,000")
}

; Excel copies a formula written into one cell of a table's calculated column to the whole column,
; including cells outside the selection, unless AutoFillFormulasInLists is off.
WriteCells(range, writes) {
    autoCorrect := range.Application.AutoCorrect
    previous := autoCorrect.AutoFillFormulasInLists
    autoCorrect.AutoFillFormulasInLists := false
    try {
        for write in writes
            write[1].%write[2]% := write[3]
    } finally autoCorrect.AutoFillFormulasInLists := previous
}

; True for a date or time format. Quoted text, escaped characters, padding and bracketed colours,
; conditions and locales are removed first; elapsed-time brackets such as [h] count as time.
DateOrTimeFormat(format) {
    if !(format is String)
        return false
    format := RegExReplace(format, '"[^"]*"|\\.|[_*].')
    format := RegExReplace(format, "i)\[(?!h+\]|m+\]|s+\])[^\]]*\]")
    return RegExMatch(format, "i)[dmyhs]") > 0
}

ScaledFormula(formula, operation) {
    static wraps := Map("negate", ["-(", ")"], "divide", ["(", ")/1000"], "multiply", ["(", ")*1000"])
    static opposite := Map("negate", "negate", "divide", "multiply", "multiply", "divide")
    body := SubStr(formula, 2)
    undo := wraps[opposite[operation]]
    start := StrLen(undo[1]), finish := StrLen(undo[2])
    if StrLen(body) > start + finish && SubStr(body, 1, start) == undo[1] && SubStr(body, -finish) == undo[2] {
        inner := SubStr(body, start + 1, StrLen(body) - start - finish)
        if OneExpression(inner)
            return "=" inner
    }
    return "=" wraps[operation][1] body wraps[operation][2]
}

; True when the brackets balance and never close early, ignoring text, quoted sheet names and
; structured references, so the opening and closing brackets around it belong together.
OneExpression(text) {
    depth := 0, quote := "", brackets := 0, escaped := false
    Loop Parse text {
        character := A_LoopField
        if quote != "" {
            if character = quote
                quote := ""
        } else if brackets {
            if escaped
                escaped := false
            else if character = "'"
                escaped := true
            else if character = "["
                brackets += 1
            else if character = "]"
                brackets -= 1
        } else if character = '"' || character = "'" {
            quote := character
        } else if character = "[" {
            brackets := 1
        } else if character = "(" {
            depth += 1
        } else if character = ")" && --depth < 0 {
            return false
        }
    }
    return depth = 0 && quote = "" && !brackets
}

; Excel keeps 15 significant digits, so dividing and then multiplying returns the same number.
ScaledNumber(value, operation) {
    if operation = "negate"
        return -value
    return Float(Format("{:.15g}", operation = "divide" ? value / 1000 : value * 1000))
}

; Formula2 writes dynamic-array formulas as written; Excel versions without it have only Formula.
FormulaProperty(cell) {
    try {
        formula := cell.Formula2
        return "Formula2"
    }
    return "Formula"
}

class ExactFormulas {
    static Copied := ""
}

; Remembers the selection's formulas as written, so pasting them elsewhere keeps every reference.
CopyExactFormulas(range) {
    if range.Areas.Count != 1
        throw ValueError("Select one block of cells.")
    if range.CountLarge > 10000
        throw ValueError("Select at most 10,000 cells.")
    formulas := []
    Loop range.Rows.Count {
        row := A_Index
        Loop range.Columns.Count {
            cell := range.Cells(row, A_Index)
            if cell.HasFormula {
                property := FormulaProperty(cell)
                formulas.Push([row, A_Index, property, cell.%property%])
            }
        }
    }
    if !formulas.Length
        return "No formulas in the selection."
    ExactFormulas.Copied := formulas
    return "Copied " formulas.Length (formulas.Length = 1 ? " formula" : " formulas") " exactly"
}

; Writes the copied formulas from the selection's first cell; cells that held no formula are left alone.
PasteExactFormulas(range) {
    if !ExactFormulas.Copied
        return "Copy formulas exactly first."
    writes := []
    for formula in ExactFormulas.Copied
        writes.Push([range.Cells(formula[1], formula[2]), formula[3], formula[4]])
    WriteCells(range, writes)
    return "Pasted " ExactFormulas.Copied.Length (ExactFormulas.Copied.Length = 1 ? " formula" : " formulas") " exactly"
}

; Applies the format after the selection's current one, or the first. Excel may report a format
; with backslashes or quotes around literal characters, and a mixed selection as null.
CycleNumberFormat(range, formats) {
    current := range.NumberFormat
    next := formats[1]
    for candidate in formats {
        if current is String && RegExReplace(current, '[\\"]') = RegExReplace(candidate, '[\\"]') {
            next := formats[Mod(A_Index, formats.Length) + 1]
            break
        }
    }
    range.NumberFormat := next
    return "Number format " next
}

; Number constants blue and formulas black. SpecialCells on one cell would search the whole sheet.
ColourCodeCells(range) {
    static blue := 0xFF0000, black := 0  ; Excel colours are BGR.
    if range.CountLarge = 1 {
        if range.HasFormula
            range.Font.Color := black
        else if IsNumber(range.Value2)
            range.Font.Color := blue
        else
            return "No number or formula in the selected cell."
        return "Inputs blue, formulas black"
    }
    changed := false
    ; xlCellTypeConstants with xlNumbers, then xlCellTypeFormulas of every result type.
    for kind in [[2, 1, blue], [-4123, 23, black]] {
        try
            cells := range.SpecialCells(kind[1], kind[2])
        catch
            continue  ; Excel throws when no cell matches.
        cells.Font.Color := kind[3]
        changed := true
    }
    return changed ? "Inputs blue, formulas black" : "No numbers or formulas in the selection."
}

CentreAcrossSelection(range) {
    alignment := range.HorizontalAlignment
    centred := alignment is Integer && alignment = 7  ; xlCenterAcrossSelection
    range.HorizontalAlignment := centred ? 1 : 7  ; xlGeneral
    return centred ? "Alignment general" : "Centred across selection"
}

; The active workbook window's own object (OBJID_NATIVEOM), so no other Excel instance is touched.
ActiveExcelSelection() {
    grid := ControlGetHwnd("EXCEL71", "A")
    iid := Buffer(16)
    DllCall("ole32\CLSIDFromString", "Str", "{00020400-0000-0000-C000-000000000046}", "Ptr", iid, "HRESULT")
    DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", grid, "UInt", 0xFFFFFFF0, "Ptr", iid, "Ptr*", &window := 0, "HRESULT")
    return SelectedRange(ComObjFromPtr(window).Selection)
}

; RangeSelection would return the last cells selected even whilst a chart or shape is selected.
SelectedRange(selection) {
    if ComObjType(selection, "Name") != "Range"
        throw ValueError("Select cells first; a chart or shape is selected.")
    return selection
}

RunExcelCommand(command, *) {
    try message := command.Call(ActiveExcelSelection())
    catch Error as problem
        message := "Formatting not applied. Finish editing the cell, or check the sheet allows formatting.`n" problem.Message
    ToolTip(message)
    SetTimer(() => ToolTip(), -2500)
}
