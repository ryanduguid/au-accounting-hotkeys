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
        "ExcelCentreAcross", CentreAcrossSelection
    )
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
    return ComObjFromPtr(window).RangeSelection
}

RunExcelCommand(command, *) {
    try message := command.Call(ActiveExcelSelection())
    catch Error as problem
        message := "Formatting not applied. Finish editing the cell and check the sheet is not protected.`n" problem.Message
    ToolTip(message)
    SetTimer(() => ToolTip(), -2500)
}
