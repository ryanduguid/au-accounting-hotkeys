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
        "ExcelPasteFormulas", PasteExactFormulas,
        "ExcelFontColour", CycleFontColour,
        "ExcelAutofitColumns", range => (range.Columns.AutoFit(), "Column width fitted"),
        "ExcelAutofitRows", range => (range.Rows.AutoFit(), "Row height fitted"),
        "ExcelIncreaseIndent", range => RibbonCommand(range, "IndentIncreaseExcel", "Indent increased"),
        "ExcelDecreaseIndent", range => RibbonCommand(range, "IndentDecreaseExcel", "Indent decreased"),
        "ExcelIncreaseDecimal", range => RibbonCommand(range, "DecimalsIncrease", "Decimal place added"),
        "ExcelDecreaseDecimal", range => RibbonCommand(range, "DecimalsDecrease", "Decimal place removed"),
        "ExcelPrecedents", ShowPrecedentPanel
    )
}

; Excel's own Home tab command on the active window's selection, which the range is, so Ctrl + Z
; undoes it and Excel applies its own rules and limits.
RibbonCommand(range, id, message) {
    range.Application.CommandBars.ExecuteMso(id)
    return message
}

; Blue for typed inputs, green for links to other sheets, black for formulas, then blue again. A
; selection of mixed colours starts at blue.
CycleFontColour(range) {
    static cycle := [[0xFF0000, "blue"], [0x008000, "green"], [0, "black"]]  ; Excel colours are BGR.
    current := range.Font.Color
    next := cycle[1]
    for colour in cycle {
        if current is Number && current = colour[1] {
            next := cycle[Mod(A_Index, cycle.Length) + 1]
            break
        }
    }
    range.Font.Color := next[1]
    return "Font colour " next[2]
}

; The ranges Excel's Trace Precedents arrows reach from the cell, across sheets and open workbooks,
; in Excel's arrow order. Excel numbers the arrows; one dashed arrow holds every reference off the
; sheet, one link each. A link Excel cannot go to, such as a closed workbook or a hidden sheet,
; returns to the cell, and so does every link of an arrow past the last; an error ends an arrow.
TracePrecedents(start) {
    app := start.Application
    targets := [], unreachable := 0
    updating := app.ScreenUpdating
    app.ScreenUpdating := false
    try {
        start.ShowPrecedents()  ; Inside the try, so screen updating returns even if this fails.
        try ScanArrows(start, targets, &unreachable)
        finally {
            try app.Goto(start)
            finally start.ShowPrecedents(true)
        }
    } finally app.ScreenUpdating := updating
    return {Targets: targets, Unreachable: unreachable}
}

; Every reference in the formula contains a run of letters, digits, dots, underscores or dollar
; signs, so there are no more arrows, and no more links on one arrow, than the formula has runs.
; More returns to the cell in a row than that can only be the arrows' end.
ScanArrows(start, targets, &unreachable) {
    RegExReplace(start.Formula, "[\w.$]+", , &runs)
    endAfter := runs + 1
    app := start.Application
    home := start.Address(true, true, 1, true)
    seen := Map()
    Loop endAfter {
        arrow := A_Index, missed := 0
        Loop endAfter {
            app.Goto(start)
            try target := start.NavigateArrow(true, arrow, A_Index)
            catch {
                unreachable += missed  ; Only a real arrow ends in an error.
                break
            }
            address := target.Address(true, true, 1, true)
            if address = home {
                if ++missed = endAfter
                    return
                continue
            }
            unreachable += missed, missed := 0
            if !seen.Has(address)
                seen[address] := true, targets.Push(target)
        }
    }
}

; A sheet name, preceded by the workbook's when it is not the starting cell's, and the address.
PrecedentLabel(target, start) {
    book := target.Worksheet.Parent.Name
    prefix := book = start.Worksheet.Parent.Name ? "" : "[" book "]"
    return prefix target.Worksheet.Name "!" target.Address(false, false)
}

; Lists the active cell's precedents; moving through the list goes to each. Enter stays there and
; Escape returns to the starting cell. The selection only moves, so nothing in the workbook changes.
ShowPrecedentPanel(range) {
    start := range.Application.ActiveCell
    if !start.HasFormula
        return "The active cell has no formula."
    if start.Worksheet.ProtectContents
        return "Excel cannot trace precedents on a protected sheet."
    traced := TracePrecedents(start)
    skipped := traced.Unreachable ? "`n" traced.Unreachable (traced.Unreachable = 1 ? " reference" : " references")
        . " not listed: Excel cannot go to a closed workbook or a hidden sheet." : ""
    if !traced.Targets.Length
        return "No precedents Excel can go to." skipped
    PrecedentPanel.Open(start, traced.Targets, WinExist("A"))
    count := traced.Targets.Length
    return count (count = 1 ? " precedent" : " precedents") skipped
}

class PrecedentPanel {
    static Window := 0

    static Open(start, targets, excelWindow) {
        this.Close()
        window := Gui("+AlwaysOnTop +ToolWindow", "Precedents of " PrecedentLabel(start, start))
        list := window.AddListView("w420 r" Min(targets.Length, 12) " -Multi NoSortHdr", ["Cell", "Shows"])
        for target in targets
            list.Add(, PrecedentLabel(target, start), target.CountLarge = 1 ? target.Text : target.CountLarge " cells")
        list.ModifyCol(1, 220), list.ModifyCol(2, 180)
        window.AddButton("Default", "Stay here").OnEvent("Click", (*) => this.Stay(targets[Max(list.GetNext(0, "Focused"), 1)], excelWindow))
        window.AddButton("x+8", "Back to start").OnEvent("Click", (*) => this.Return(start, excelWindow))
        window.OnEvent("Escape", (*) => this.Return(start, excelWindow))
        window.OnEvent("Close", (*) => this.Return(start, excelWindow))
        formula := start.Formula
        list.OnEvent("ItemFocus", (control, item) => this.Follow(start, formula, targets[item], excelWindow))
        this.Window := window, this.List := list
        window.Show()
        list.Focus()
        list.Modify(1, "Select Focus")
        this.Go(targets[1])  ; ItemFocus reports only keyboard and mouse moves.
    }

    ; The list is of the formula as it was when the panel opened; after an edit it may be wrong.
    static Follow(start, formula, target, excelWindow) {
        try current := start.Formula
        if IsSet(current) && current == formula
            return this.Go(target)
        this.Close(excelWindow)
        ToolTip("The formula has changed; open the precedents again."), SetTimer(() => ToolTip(), -2500)
    }

    static Go(target) {
        try target.Application.Goto(target)
        catch
            ToolTip("Excel cannot go to that cell now."), SetTimer(() => ToolTip(), -2500)
    }

    static Stay(target, excelWindow) {
        this.Close(this.TargetWindow(target, excelWindow))
    }

    static TargetWindow(target, excelWindow) {
        targetWindow := 0
        try targetWindow := target.Application.ActiveWindow.Hwnd
        if !targetWindow {
            try targetWindow := target.Worksheet.Parent.Windows(1).Hwnd
        }
        return targetWindow || excelWindow
    }

    static Return(start, excelWindow) {
        this.Go(start)
        this.Close(excelWindow)
    }

    static Close(excelWindow := 0) {
        if window := this.Window {
            this.Window := 0
            window.Destroy()
        }
        if excelWindow && WinExist("ahk_id " excelWindow)
            WinActivate()
    }
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
                if cell.HasArray
                    throw ValueError("Cannot copy legacy array formulas.")
                property := FormulaProperty(cell)
                formulas.Push([row, A_Index, property, cell.%property%])
            }
        }
    }
    if !formulas.Length
        return "No formulas in the selection."
    ExactFormulas.Copied := {Rows: range.Rows.Count, Columns: range.Columns.Count, Formulas: formulas}
    return "Copied " formulas.Length (formulas.Length = 1 ? " formula" : " formulas") " exactly"
}

; Writes the copied formulas into the selected block from its first cell; extra destination
; cells and cells that held no formula are left alone.
PasteExactFormulas(range) {
    if !ExactFormulas.Copied
        return "Copy formulas exactly first."
    if range.Areas.Count != 1
        throw ValueError("Select one block of cells.")
    copied := ExactFormulas.Copied
    if range.Rows.Count < copied.Rows || range.Columns.Count < copied.Columns
        throw ValueError("Select at least " copied.Rows " by " copied.Columns " cells to paste the copied formulas.")
    if SheetBoundsExceeded(range, copied)
        throw ValueError("Copied block goes past the edge of the sheet.")
    writes := []
    for formula in copied.Formulas {
        cell := range.Cells(formula[1], formula[2])
        if cell.HasArray
            throw ValueError("Cannot paste over a legacy array formula.")
        writes.Push([cell, formula[3], formula[4]])
    }
    WriteCells(range, writes)
    return "Pasted " copied.Formulas.Length (copied.Formulas.Length = 1 ? " formula" : " formulas") " exactly"
}

SheetBoundsExceeded(range, copied) {
    try {
        maxRow := range.Worksheet.Rows.Count
        maxCol := range.Worksheet.Columns.Count
        return range.Row + copied.Rows - 1 > maxRow || range.Column + copied.Columns - 1 > maxCol
    }
    return false
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
