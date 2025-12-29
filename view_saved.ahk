#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn

; ---------- View Saved GUI ----------

ShowViewSaved() {
    global SAVED_GUI
    
    if (SAVED_GUI != "" && WinExist(SAVED_GUI)) {
        SAVED_GUI.Show()
        WinActivate(SAVED_GUI)
        return
    }

    LogDebug("Showing View Saved GUI")
    
    myGui := Gui()
    SAVED_GUI := myGui
    
    myGui.OnEvent("Close", (*) => SAVED_GUI := "")
    myGui.OnEvent("Escape", (*) => (SAVED_GUI := "", myGui.Destroy()))
    myGui.Title := "Saved Tips"
    
    lv := myGui.Add("ListView", "w430 h300", ["Title", "Date", "Path"])
    lv.ModifyCol(1, 300) ; Title width
    lv.ModifyCol(2, 120) ; Date width
    lv.ModifyCol(3, 0) ; Hide Path column
    lv.OnEvent("DoubleClick", OpenSelected)
    lv.OnEvent("ItemSelect", (*) => UpdateDeleteButtonState(lv, deleteBtn))

    results := GetSavedResults()
    for result in results {
        lv.Add(, result.title, result.date, result.path)
    }
    lv.ModifyCol(2, "SortDesc") ; Sort by Date descending

    deleteBtn := myGui.Add("Button", "w80 Disabled", "Delete")
    deleteBtn.OnEvent("Click", (*) => DeleteSelected(lv, myGui))

    closeBtn := myGui.Add("Button", "x360 w80 yp", "Close")
    closeBtn.OnEvent("Click", (*) => (SAVED_GUI := "", myGui.Destroy()))
    
    myGui.Show()
}

UpdateDeleteButtonState(lv, deleteBtn) {
    selected := lv.GetNext()
    deleteBtn.Enabled := (selected > 0)
}

OpenSelected(lv, rowNumber) {
    if (rowNumber == 0) {
        return
    }
    
    title := lv.GetText(rowNumber, 1)
    path := lv.GetText(rowNumber, 3)
    
    try {
        content := FileRead(path)
        ShowResult(content, title, false)
    } catch as err {
        MsgBox("Could not read file: " err.Message)
    }
}

DeleteSelected(lv, myGui) {
    row := lv.GetNext()
    if (row == 0) {
        MsgBox("No item selected.")
        return
    }
    title := lv.GetText(row, 1)
    path := lv.GetText(row, 3)
    
    if (MsgBox("Are you sure you want to delete this result?`n`n" title, "Confirm Delete", 4) == "Yes") {
        DeleteResult(path)
        lv.Delete(row)
    }
}