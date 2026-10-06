#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\text.ahk

ReadClipboardText() {
    return CheckedText(A_Clipboard)
}

WriteClipboardText(text) {
    A_Clipboard := CheckedText(text)
}
