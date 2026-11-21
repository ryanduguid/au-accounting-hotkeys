#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\commands.ahk
#Include %A_LineFile%\..\clipboard.ahk

ConfirmFormulaCopy() {
    return MsgBox("Some output cells begin with =, +, - or @. A spreadsheet may interpret them as formulas.`n`nCopy the exact preview?", "Check spreadsheet text", "YesNo Icon!") = "Yes"
}

; A :T: entry, which types its text literally, that SnippetsFromHotstrings reads back unchanged.
HotstringEntry(name, text) {
    static escapes := [["``", "````"], [":", "``:"], [";", "``;"], ["`n", "``n"], ["`t", "``t"]]
    for pair in escapes {
        name := StrReplace(name, pair[1], pair[2])
        text := StrReplace(text, pair[1], pair[2])
    }
    ; Spaces at either end would be trimmed when the line is read.
    RegExMatch(text, "^( *)(.*?)( *)\z", &parts)
    return ":T:" name "::" StrReplace(parts[1], " ", "``s") parts[2] StrReplace(parts[3], " ", "``s")
}

; Appends a snippet to snippets.local\Added.ahk and returns the reloaded catalogue. Refuses a label
; already loaded and text the loader would not read back exactly. If the loader would then miss the
; new snippet or one it loaded before (its file, size or count limits), the append is undone.
AddHotstringSnippet(root, name, text, settings) {
    if !RegExMatch(name, "^[!-~]{1,40}\z")
        throw ValueError("Use a trigger of 1 to 40 ASCII letters, digits or symbols, without spaces.")
    text := CheckedText(NormaliseLineEndings(text), 16384)
    if InStr(text, "{{") || InStr(text, "}}")
        throw ValueError("Text must not contain {{ or }}. For date tokens or fields, add a .txt snippet instead.")
    line := HotstringEntry(name, text)
    parsed := SnippetsFromHotstrings(line)
    if parsed.Items.Length != 1 || parsed.Items[1].Name !== name || parsed.Items[1].Body !== text
        throw ValueError("This text cannot be stored exactly in Added.ahk.")
    before := LoadCommandCatalogue(settings, root).Commands
    for command in before {
        if command.Id = "Snippet:" name
            throw ValueError("A snippet labelled " name " already exists.")
    }
    directory := root "\snippets.local", path := directory "\Added.ahk"
    if !DirExist(directory)
        DirCreate(directory)
    if InStr(FileGetAttrib(directory), "L") || FileExist(path) && InStr(FileGetAttrib(path), "L")
        throw ValueError("Linked snippet folders and files are not changed.")
    size := FileExist(path) ? FileGetSize(path) : -1
    if size > 0 {
        handle := FileOpen(path, "r")
        handle.Pos := size - 1
        line := (handle.ReadUChar() = 10 ? "" : "`n") line
        handle.Close()
    }
    FileAppend(line "`n", path, "UTF-8-RAW")
    after := LoadCommandCatalogue(settings, root)
    loaded := Map()
    for command in after.Commands
        loaded[command.Id] := true
    missing := loaded.Has("Snippet:" name) ? "" : name
    for command in before {
        if !loaded.Has(command.Id)
            missing .= (missing = "" ? "" : ", ") command.Label
    }
    if missing != "" {
        try {
            if size < 0
                FileDelete(path)
            else {
                handle := FileOpen(path, "rw")
                handle.Length := size
                handle.Close()
            }
        } catch Error as problem
            throw ValueError("Added.ahk keeps the new last line, which could not be removed (" problem.Message "). Remove it by hand: the picker would no longer load " missing ".")
        throw ValueError("Not saved: the picker would no longer load " missing "." (after.Errors.Length ? " " JoinLines(after.Errors, " ") : ""))
    }
    return {Path: path, Catalogue: after}
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
        SplitPath(A_LineFile, , &root)
        this.Root := root
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
        this.Window.AddButton("x+10 w130", "&Add snippet...").OnEvent("Click", (*) => this.OpenAddSnippet())
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
        if this.LoadErrors.Length {
            this.Window.Opt("+OwnDialogs")
            MsgBox(JoinLines(this.LoadErrors), "Some snippets were excluded", "Icon!")
        }
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
        context := {Year: this.Settings.Year, Quarter: this.Settings.Quarter, HolidayState: this.Settings.HolidayState, Timestamp: A_Now}
        if this.Selected.Input && this.Input.Value = "" {
            if this.Selected.HasOwnProp("Fields") && this.Selected.Fields.Length {
                ; Shows the draft with [label] placeholders; Copy stays off until every field is answered.
                try this.Preview.Value := this.Selected.Produce.Call(context, "")
                this.Status.Text := "Type one answer per line, in this order: " JoinLines(this.Selected.Fields, ", ") "."
            } else
                this.Status.Text := "Input required. Type text here or choose Load clipboard and preview."
            return
        }
        try {
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
        this.Window.Opt("+OwnDialogs")
        if LooksLikeFormula(output) && !this.Confirm.Call()
            return false
        if output !== this.Output || !this.CopyButton.Enabled
            return false
        try {
            if this.Write.Call(output) !== output {
                this.Status.Text := "Copy not confirmed: the clipboard does not hold the preview. Another program may have changed it."
                return false
            }
            this.Status.Text := "Copied " StrLen(output) " characters. Paste into the intended destination."
            return true
        } catch Error as problem {
            this.Status.Text := "Copy failed: " problem.Message
            return false
        }
    }

    OpenAddSnippet() {
        dialog := Gui("+Owner" this.Window.Hwnd, "Add snippet")
        dialog.SetFont("s10", "Segoe UI")
        dialog.AddText("w480", "&Trigger: the label in the picker, 1 to 40 characters without spaces")
        trigger := dialog.AddEdit("w480 Limit40")
        dialog.AddText("w480", "&Text, saved as typed")
        body := dialog.AddEdit("w480 r8 Limit16384")
        status := dialog.AddText("w480 r2", "Saved to snippets.local\Added.ahk in AutoHotkey hotstrings format.")
        dialog.AddButton("w100", "&Save").OnEvent("Click", (*) => this.AddSnippet(trigger.Value, body.Value, status) && dialog.Destroy())
        dialog.AddButton("x+10 w100", "Cancel").OnEvent("Click", (*) => dialog.Destroy())
        dialog.OnEvent("Escape", (*) => dialog.Destroy())
        dialog.Show()
    }

    ; Saves the snippet, reloads the catalogue and selects the new entry. Errors go to status.
    AddSnippet(name, text, status) {
        try saved := AddHotstringSnippet(this.Root, name, text, this.Settings)
        catch Error as problem {
            status.Text := problem.Message
            return false
        }
        this.Commands := saved.Catalogue.Commands
        this.Search.Value := ""
        this.RefreshList()
        for item in this.Rows {
            if item.Id == "Snippet:" name {
                this.List.Modify(A_Index, "Select Focus Vis")
                this.SelectRow(A_Index)
                break
            }
        }
        this.Status.Text := "Added " name " to " saved.Path "."
        return true
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
