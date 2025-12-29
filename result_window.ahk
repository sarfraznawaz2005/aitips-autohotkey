#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn

; ---------- Result Window GUI ----------

ShowResult(result, title, showSave := true) {
    LogDebug("Showing Result Window for: " title)
    
    myGui := Gui()
    myGui.Title := "Tip - " title
    
    myGui.SetFont("s12") ; Increase font size
    resultEdit := myGui.Add("Edit", "w800 h600 ReadOnly Multi", result)
    myGui.SetFont() ; Reset font for buttons
    
    if (showSave) {
        saveBtn := myGui.Add("Button", "w80", "Save")
        saveBtn.OnEvent("Click", (*) => OnSave(title, result, myGui))
        
        closeBtn := myGui.Add("Button", "w80 x+640 yp", "Close")
        closeBtn.OnEvent("Click", (*) => myGui.Destroy())
    } else {
        closeBtn := myGui.Add("Button", "w80 x730", "Close")
        closeBtn.OnEvent("Click", (*) => myGui.Destroy())
    }
    
    myGui.Show()
}

OnSave(title, result, myGui) {
    if (SaveResult(title, result)) {
        myGui.Destroy()
    } else {
        MsgBox("Failed to save result. Check debug.log for details.", "Error", 16)
    }
}