#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn

; ---------- View Prompts GUI ----------

ShowViewPrompts() {
    global PROMPTS_GUI
    
    if (PROMPTS_GUI != "" && WinExist(PROMPTS_GUI)) {
        PROMPTS_GUI.Show()
        WinActivate(PROMPTS_GUI)
        return
    }

    LogDebug("Showing View Prompts GUI")
    
    myGui := Gui()
    PROMPTS_GUI := myGui
    
    myGui.OnEvent("Close", (*) => PROMPTS_GUI := "")
    myGui.OnEvent("Escape", (*) => (PROMPTS_GUI := "", myGui.Destroy()))
    myGui.Title := "Prompts"
    
    lv := myGui.Add("ListView", "w370 h200", ["Title", "Frequency", "Start Time", "Status", "Index"])
    lv.ModifyCol(1, 150)
    lv.ModifyCol(2, 80)
    lv.ModifyCol(3, 70)
    lv.ModifyCol(4, 65)
    lv.ModifyCol(5, 0) ; Hide Index column
    lv.OnEvent("DoubleClick", (lv, rowNumber) => OpenEditPrompt(lv))
    lv.OnEvent("ItemSelect", (*) => UpdateButtonStates(lv, editBtn, deleteBtn, runBtn))

    RefreshPromptsList(lv)

    addBtn := myGui.Add("Button", "w66", "Add New")
    addBtn.OnEvent("Click", (*) => OpenAddPrompt(lv))

    editBtn := myGui.Add("Button", "w66 x+10 yp Disabled", "Edit")
    editBtn.OnEvent("Click", (*) => OpenEditPrompt(lv))

    deleteBtn := myGui.Add("Button", "w66 x+10 yp Disabled", "Delete")
    deleteBtn.OnEvent("Click", (*) => DeletePromptEntry(lv))

    runBtn := myGui.Add("Button", "w66 x+10 yp Disabled", "Run")
    runBtn.OnEvent("Click", (*) => RunPrompt(lv))

    closeBtn := myGui.Add("Button", "w66 x+10 yp", "Close")
    closeBtn.OnEvent("Click", (*) => (PROMPTS_GUI := "", myGui.Destroy()))
    
    myGui.Show()
}

RefreshPromptsList(lv) {
    lv.Delete()
    prompts := LoadPrompts()

    for i, prompt in prompts {
        status := prompt.enabled ? "Enabled" : "Disabled"
        ; Only show start time for frequencies that use time: Once, Every Day, Every Week, Every Month
        timeNeeded := (prompt.freq == "Once" || prompt.freq == "Every Day" || prompt.freq == "Every Week" || prompt.freq == "Every Month")
        startTime := timeNeeded && prompt.start != "" ? FormatTime(prompt.start, "HH:mm") : ""
        lv.Add(, prompt.title, prompt.freq, startTime, status, i)
    }
    lv.ModifyCol(1, "Sort") ; Sort by Title ascending
}

UpdateButtonStates(lv, editBtn, deleteBtn, runBtn) {
    selected := lv.GetNext()
    editBtn.Enabled := (selected > 0)
    deleteBtn.Enabled := (selected > 0)
    runBtn.Enabled := (selected > 0)
}

OpenAddPrompt(lv) {
    ShowAddPrompt( , , (*) => RefreshPromptsList(lv))
}

OpenEditPrompt(lv) {
    row := lv.GetNext()
    if (row == 0) {
        return
    }

    index := lv.GetText(row, 5)
    prompts := LoadPrompts()
    if (index > prompts.Length) {
        return
    }

    promptObj := prompts[index]
    ShowAddPrompt(promptObj, index, (*) => RefreshPromptsList(lv))
}

DeletePromptEntry(lv) {
    row := lv.GetNext()
    if (row == 0) {
        MsgBox("Please select a prompt to delete.")
        return
    }

    title := lv.GetText(row, 1)
    index := lv.GetText(row, 5)
    if (MsgBox("Are you sure you want to delete the prompt: " title "?", "Confirm Delete", 4) == "Yes") {
        prompts := LoadPrompts()
        if (index <= prompts.Length) {
            prompts.RemoveAt(index)
            SavePrompts(prompts)
            RefreshPromptsList(lv)
            LogDebug("Deleted prompt: " title)
        }
    }
}

RunPrompt(lv) {
    row := lv.GetNext()
    if (row == 0) {
        MsgBox("Please select a prompt to run.")
        return
    }

    index := lv.GetText(row, 5)
    prompts := LoadPrompts()
    if (index > prompts.Length) {
        return
    }

    promptObj := prompts[index]
    result := CallAI(promptObj.prompt)
    ShowResult(result, promptObj.title)
}
