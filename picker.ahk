#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\commands.ahk
#Include %A_LineFile%\..\clipboard.ahk

ConfirmFormulaCopy() {
    return MsgBox("Some output cells begin with =, +, - or @. A spreadsheet may interpret them as formulas.`n`nCopy the exact preview?", "Check spreadsheet text", "YesNo Icon!") = "Yes"
}

class CommandPicker {
    static ActiveHwnd := 0

    __New(settings, catalogue := 0, read := ReadClipboardText, write := WriteClipboardText, confirm := ConfirmFormulaCopy) {
        this.Settings := settings
        this.Read := read
        this.Write := write
        this.Confirm := confirm
        loaded := IsObject(catalogue) ? {Commands: catalogue, Errors: []} : LoadCommandCatalogue(settings)
        this.Commands := loaded.Commands
        this.LoadErrors := loaded.Errors
        this.Output := ""
        this.SelectedId := ""
        this.Updating := false
        this.Window := Gui(, "AU accounting commands")
        this.Window.SetFont("s10", "Segoe UI")
        this.Window.AddText("w720", "FY " FinancialYearLabel(settings.Year) " | Q" settings.Quarter " | " QuarterRange(settings.Year, settings.Quarter))
        this.Window.AddText("xm", "&Search commands")
        this.Search := this.Window.AddEdit("xm w720 Limit129")
        this.List := this.Window.AddListView("xm w720 r9 -Multi +NoSortHdr", ["Command", "Category"])
        this.List.ModifyCol(1, 485)
        this.List.ModifyCol(2, 210)
        this.Window.AddText("xm", "&Input text (type here, or choose Load clipboard)")
        this.Input := this.Window.AddEdit("xm w720 r3 Limit32769")
        this.LoadButton := this.Window.AddButton("xm w225", "&Load clipboard and preview")
        this.Window.AddText("xm", "&Preview of exact text to copy")
        this.Preview := this.Window.AddEdit("xm w720 r6 ReadOnly")
        this.Status := this.Window.AddText("xm w720 r2", "")
        this.CopyButton := this.Window.AddButton("xm w150 Disabled", "&Copy result")
        this.Window.AddButton("x+10 w100", "Close").OnEvent("Click", (*) => this.Close())
        this.Search.OnEvent("Change", (*) => this.RefreshList())
        this.List.OnEvent("ItemSelect", (control, row, selected) => selected ? this.SelectRow(row) : 0)
        this.Input.OnEvent("Change", (*) => this.InputChanged())
        this.LoadButton.OnEvent("Click", (*) => this.LoadInput())
        this.CopyButton.OnEvent("Click", (*) => this.CopyResult())
        this.Window.OnEvent("Escape", (*) => this.Close())
        this.Window.OnEvent("Close", (*) => this.Close())
        this.RefreshList()
    }

    Show() {
        CommandPicker.ActiveHwnd := this.Window.Hwnd
        this.Window.Show()
        this.Search.Focus()
        if this.LoadErrors.Length
            MsgBox(JoinLines(this.LoadErrors), "Some snippets were excluded", "Icon!")
    }

    RefreshList() {
        try this.Rows := FilterCommands(this.Commands, this.Search.Value)
        catch ValueError as searchFailure {
            this.Rows := []
            this.List.Delete()
            this.SelectedId := ""
            this.ClearInput()
            this.SetError(searchFailure.Message)
            this.LoadButton.Enabled := false
            this.Input.Enabled := false
            return
        }
        this.Updating := true
        try {
            this.List.Delete()
            for item in this.Rows
                this.List.Add(, item.Label, item.Category)
            if this.Rows.Length
                this.List.Modify(1, "Select Focus")
        } finally this.Updating := false
        if this.Rows.Length
            this.SelectRow(1)
        else {
            this.SelectedId := ""
            this.ClearInput()
            this.SetError("No matching commands.")
            this.LoadButton.Enabled := false
            this.Input.Enabled := false
        }
    }

    SelectRow(row) {
        if this.Updating || row < 1 || row > this.Rows.Length
            return
        item := this.Rows[row]
        if item.Id != this.SelectedId {
            this.ClearInput()
            this.SelectedId := item.Id
        }
        this.Selected := item
        this.LoadButton.Enabled := item.Input
        this.Input.Enabled := item.Input
        this.RefreshPreview()
    }

    ClearInput() {
        this.Updating := true
        try this.Input.Value := ""
        finally this.Updating := false
        this.Output := ""
        this.Preview.Value := ""
        this.CopyButton.Enabled := false
    }

    InputChanged() {
        if !this.Updating
            this.RefreshPreview()
    }

    RefreshPreview() {
        this.Output := ""
        this.Preview.Value := ""
        this.CopyButton.Enabled := false
        if this.SelectedId = ""
            return
        if this.Selected.Input && this.Input.Value = "" {
            this.Status.Text := "Input required. Clipboard has not been read for this selection."
            return
        }
        try {
            context := {Year: this.Settings.Year, Quarter: this.Settings.Quarter, Timestamp: A_Now}
            output := ProduceCommand(this.Selected, context, this.Input.Value)
            this.Output := output
            this.Preview.Value := output
            this.Status.Text := StrLen(output) " characters. Copy replaces the clipboard."
                . (LooksLikeFormula(output) ? "`nFormula-like text: copying requires confirmation. Use appropriate spreadsheet cell formatting." : "")
            this.CopyButton.Enabled := true
        } catch Error as problem {
            this.SetError(problem.Message)
        }
    }

    SetError(message) {
        this.Output := ""
        this.Preview.Value := ""
        this.CopyButton.Enabled := false
        this.Status.Text := message
    }

    LoadInput() {
        if this.SelectedId = "" || !this.Selected.Input
            return
        try {
            text := CheckedText(this.Read.Call(), this.Selected.MaxInput)
            this.Updating := true
            try this.Input.Value := text
            finally this.Updating := false
            this.RefreshPreview()
        } catch Error as problem {
            this.ClearInput()
            this.SetError(problem.Message)
        }
    }

    CopyResult() {
        if !this.CopyButton.Enabled || this.Output = ""
            return false
        output := this.Output
        if LooksLikeFormula(output) && !this.Confirm.Call()
            return false
        if output != this.Output || !this.CopyButton.Enabled
            return false
        try {
            this.Write.Call(output)
            this.Status.Text := "Copied " StrLen(output) " characters. Paste into the intended destination."
            return true
        } catch Error as problem {
            this.Status.Text := "Copy failed: " problem.Message
            return false
        }
    }

    Close() {
        if CommandPicker.ActiveHwnd = this.Window.Hwnd
            CommandPicker.ActiveHwnd := 0
        this.Output := ""
        this.Input.Value := ""
        this.Preview.Value := ""
        this.Window.Destroy()
    }
}

ShowPicker(settings) {
    static picker := 0
    if IsObject(picker) {
        try picker.Close()
    }
    try {
        picker := CommandPicker(settings)
        picker.Show()
    } catch Error as problem {
        MsgBox(problem.Message, "Could not open accounting commands", "Icon!")
    }
}
