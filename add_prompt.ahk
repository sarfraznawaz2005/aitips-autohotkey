#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn

; ---------- Add/Edit Prompt GUI ----------

ShowAddPrompt(editObj := "", editIndex := 0, onSaveCallback := "") {
    global ADD_PROMPT_GUI
    
    if (ADD_PROMPT_GUI != "" && WinExist(ADD_PROMPT_GUI)) {
        ADD_PROMPT_GUI.Show()
        WinActivate(ADD_PROMPT_GUI)
        return
    }

    LogDebug(editIndex > 0 ? "Showing Edit Prompt GUI" : "Showing Add Prompt GUI")
    
    myGui := Gui()
    ADD_PROMPT_GUI := myGui
    
    myGui.OnEvent("Close", (*) => ADD_PROMPT_GUI := "")
    myGui.OnEvent("Escape", (*) => (ADD_PROMPT_GUI := "", myGui.Destroy()))
    myGui.Title := editIndex > 0 ? "Edit Prompt" : "Add Prompt"
    
    ; Title
    myGui.Add("Text", "x10 y10 w100", "Title:")
    titleEdit := myGui.Add("Edit", "x120 y10 w350", editObj != "" ? editObj.title : "")
    
    ; Prompt
    myGui.Add("Text", "x10 y40 w100", "Prompt:")
    promptEdit := myGui.Add("Edit", "x120 y40 w350 h120 Multi", editObj != "" ? editObj.prompt : "")
    
    ; Frequency
    myGui.Add("Text", "x10 y170 w100", "Frequency:")
    freqList := ["Once", "Every Minute", "Every 5 Minutes", "Every 15 Minutes", "Every 30 Minutes", "Every Hour", "Every 3 Hours", "Every Day", "Every Week", "Every Month"]
    defaultFreq := 1
    if (editObj != "") {
        for i, f in freqList {
            if (f == editObj.freq) {
                defaultFreq := i
                break
            }
        }
    }
    freqDDL := myGui.Add("DDL", "x120 y170 w200 Choose" . defaultFreq, freqList)

    ; Enabled
    enabledCB := myGui.Add("CheckBox", "x10 y200 w100" . (editObj == "" || editObj.enabled ? " Checked" : ""), "Enabled")

    ; Date
    dateLabel := myGui.Add("Text", "x10 y230 w100", "Date:")
    initDate := (editObj != "" && editObj.freq == "Once") ? SubStr(editObj.start, 1, 8) : A_Now
    dateCtrl := myGui.Add("DateTime", "x120 y230 w120", initDate)
    dateCtrl.Format := "yyyy-MM-dd"

    ; Time
    timeLabel := myGui.Add("Text", "x10 y260 w100", "Time:")
    hourOptions := []
    Loop 24
        hourOptions.Push(Format("{:02}", A_Index - 1))
    
    defaultHour := 10 ; Default 09
    defaultMin := 1 ; Default 00
    
    if (editObj != "") {
        h := SubStr(editObj.start, 9, 2)
        m := SubStr(editObj.start, 11, 2)
        defaultHour := Number(h) + 1
        defaultMin := Number(m) + 1
    }
    
    hourDDL := myGui.Add("DDL", "x120 y260 w60 Choose" . defaultHour, hourOptions)

    minOptions := []
    Loop 60
        minOptions.Push(Format("{:02}", A_Index - 1))
    minDDL := myGui.Add("DDL", "x190 y260 w60 Choose" . defaultMin, minOptions)

    ; Days
    daysLabel := myGui.Add("Text", "x10 y290 w200", "Days of Week:")

    monCB := myGui.Add("CheckBox", "x10 y310 w50" . (CheckPromptDay("Mon", editObj) ? " Checked" : ""), "Mon")
    tueCB := myGui.Add("CheckBox", "x70 y310 w50" . (CheckPromptDay("Tue", editObj) ? " Checked" : ""), "Tue")
    wedCB := myGui.Add("CheckBox", "x130 y310 w50" . (CheckPromptDay("Wed", editObj) ? " Checked" : ""), "Wed")
    thuCB := myGui.Add("CheckBox", "x190 y310 w50" . (CheckPromptDay("Thu", editObj) ? " Checked" : ""), "Thu")
    friCB := myGui.Add("CheckBox", "x250 y310 w50" . (CheckPromptDay("Fri", editObj) ? " Checked" : ""), "Fri")
    satCB := myGui.Add("CheckBox", "x310 y310 w50" . (CheckPromptDay("Sat", editObj) ? " Checked" : ""), "Sat")
    sunCB := myGui.Add("CheckBox", "x370 y310 w50" . (CheckPromptDay("Sun", editObj) ? " Checked" : ""), "Sun")

    ; Day of Month
    dayLabel := myGui.Add("Text", "x10 y340 w200", "Day of Month:")
    dayOptions := []
    Loop 31
        dayOptions.Push(A_Index . "")
    
    defaultDayOfMonth := editObj != "" && editObj.freq == "Every Month" && editObj.dayOfMonth != "" ? Number(editObj.dayOfMonth) : 1
    dayDDL := myGui.Add("DDL", "x10 y360 w60 Choose" . defaultDayOfMonth, dayOptions)

    UpdateControls(freqDDL.Text, dateLabel, dateCtrl, timeLabel, hourDDL, minDDL, daysLabel, monCB, tueCB, wedCB, thuCB, friCB, satCB, sunCB, dayLabel, dayDDL)
    freqDDL.OnEvent("Change", (*) => UpdateControls(freqDDL.Text, dateLabel, dateCtrl, timeLabel, hourDDL, minDDL, daysLabel, monCB, tueCB, wedCB, thuCB, friCB, satCB, sunCB, dayLabel, dayDDL))
    
    saveBtn := myGui.Add("Button", "x150 y390 w80", "Save")
    saveBtn.OnEvent("Click", (*) => SavePrompt(titleEdit, promptEdit, freqDDL, dateCtrl, hourDDL, minDDL, monCB, tueCB, wedCB, thuCB, friCB, satCB, sunCB, dayDDL, enabledCB, myGui, editIndex, onSaveCallback))
    
    cancelBtn := myGui.Add("Button", "x250 y390 w80", "Close")
    cancelBtn.OnEvent("Click", (*) => (ADD_PROMPT_GUI := "", myGui.Destroy()))
    
    myGui.Show("w500 h420")
}

UpdateControls(freq, dateLabel, dateCtrl, timeLabel, hourDDL, minDDL, daysLabel, monCB, tueCB, wedCB, thuCB, friCB, satCB, sunCB, dayLabel, dayDDL) {
    onceNeeded := (freq == "Once")
    dateLabel.Visible := onceNeeded
    dateCtrl.Visible := onceNeeded

    timeNeeded := (freq == "Once" || freq == "Every Day" || freq == "Every Week" || freq == "Every Month")
    timeLabel.Visible := timeNeeded
    hourDDL.Visible := timeNeeded
    minDDL.Visible := timeNeeded

    weekNeeded := (freq == "Every Week")
    daysLabel.Visible := weekNeeded
    monCB.Visible := weekNeeded
    tueCB.Visible := weekNeeded
    wedCB.Visible := weekNeeded
    thuCB.Visible := weekNeeded
    friCB.Visible := weekNeeded
    satCB.Visible := weekNeeded
    sunCB.Visible := weekNeeded

    monthNeeded := (freq == "Every Month")
    dayLabel.Visible := monthNeeded
    dayDDL.Visible := monthNeeded

    if (!weekNeeded) {
        monCB.Value := 0
        tueCB.Value := 0
        wedCB.Value := 0
        thuCB.Value := 0
        friCB.Value := 0
        satCB.Value := 0
        sunCB.Value := 0
    }
}

; Local utility function for joining array elements
LocalStrJoin(arr, sep := ",") {
    result := ""
    if !IsObject(arr)
        return String(arr)

    for v in arr {
        curr := Trim(String(v))
        if (curr == "")
            continue
        if (result != "")
            result .= sep
        result .= curr
    }
    return result
}

SavePrompt(titleEdit, promptEdit, freqDDL, dateCtrl, hourDDL, minDDL, monCB, tueCB, wedCB, thuCB, friCB, satCB, sunCB, dayDDL, enabledCB, myGui, editIndex, onSaveCallback) {
    global ADD_PROMPT_GUI
    title := titleEdit.Value
    prompt := promptEdit.Value
    freq := freqDDL.Text

    ; Robust numeric retrieval
    hVal := Format("{:02}", hourDDL.Value - 1)
    mVal := Format("{:02}", minDDL.Value - 1)
    timeOnly := hVal . mVal . "00"

    start := ""
    if (freq == "Once") {
        start := SubStr(dateCtrl.Value, 1, 8) . timeOnly
    } else {
        start := "20000101" . timeOnly
    }

    days := []
    if (monCB.Value) days.Push("Mon")
    if (tueCB.Value) days.Push("Tue")
    if (wedCB.Value) days.Push("Wed")
    if (thuCB.Value) days.Push("Thu")
    if (friCB.Value) days.Push("Fri")
    if (satCB.Value) days.Push("Sat")
    if (sunCB.Value) days.Push("Sun")

    ; Save to config.ini
    prompts := []
    try {
        prompts := LoadPrompts()
    } catch {
        ; keep []
    }

    ; Only include days for weekly prompts
    finalDays := []
    if (freq == "Every Week") {
        finalDays := days
    }

    promptData := {title: title, prompt: prompt, freq: freq, start: start, days: finalDays, dayOfMonth: freq == "Every Month" ? dayDDL.Text : "", enabled: enabledCB.Value}

    LogDebug("SavePrompt - Prompt saved: " . title . ", freq: " . freq . ", days: " . LocalStrJoin(finalDays, ","))

    if (editIndex > 0 && editIndex <= prompts.Length) {
        prompts[editIndex] := promptData
    } else {
        prompts.Push(promptData)
    }

    LogDebug("SavePrompt - About to save prompts. Total prompts: " . prompts.Length)
    for i, p in prompts {
        LogDebug("SavePrompt - Prompt " . i . ": title=" . p.title . ", freq=" . p.freq . ", days=" . LocalStrJoin(p.days, ","))
    }

    SavePrompts(prompts)
    LogDebug((editIndex > 0 ? "Prompt updated: " : "Prompt saved: ") . title)

    if (HasMethod(onSaveCallback, "Call")) {
        onSaveCallback()
    }

    ADD_PROMPT_GUI := ""
    myGui.Destroy()
}

CheckPromptDay(dayName, obj) {
    if (obj == "" || !HasProp(obj, "days") || !IsObject(obj.days)) {
        return false
    }
    for d in obj.days {
        if (d == dayName) {
            return true
        }
    }
    return false
}