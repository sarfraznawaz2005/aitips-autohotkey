#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn

; ---------- Utils ----------

global CONFIG_FILE := A_ScriptDir "\config.ini"
global SAVED_DIR := A_ScriptDir "\saved"

StrJoin(arr, sep := ",") {
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

LoadPrompts() {
    prompts := []
    try {
        i := 1
        loop {
            section := "Prompt" i
            title := IniRead(CONFIG_FILE, section, "title", "")
            if (title == "")
                break

            prompt := IniRead(CONFIG_FILE, section, "prompt", "")
            prompt := StrReplace(prompt, "\n", "`n")
            freq := IniRead(CONFIG_FILE, section, "freq", "")
            start := IniRead(CONFIG_FILE, section, "start", "")

            ; Load days field regardless, but only use it for weekly prompts
            daysStr := IniRead(CONFIG_FILE, section, "days", "")
            days := []
            if (freq == "Every Week") {
                ; Robust days parsing for weekly prompts
                for d in StrSplit(daysStr, ",") {
                    trimmed := Trim(d)
                    if (trimmed != "")
                        days.Push(trimmed)
                }
            }

            dayOfMonth := IniRead(CONFIG_FILE, section, "day_of_month", "1")
            enabled := IniRead(CONFIG_FILE, section, "enabled", "1") == "1"

            LogDebug("Loaded prompt " section ": title=" . title . ", freq=" . freq . ", days=" . StrJoin(days, ",") . ", day_of_month=" . dayOfMonth . ", enabled=" . enabled)
            prompts.Push({title: title, prompt: prompt, freq: freq, start: start, days: days, dayOfMonth: dayOfMonth, enabled: enabled})
            i++
        }
    } catch as err {
        LogDebug("Error loading prompts: " err.Message . " - " . err.Stack)
    }
    return prompts
}

SavePrompts(prompts) {
    try {
        ; Clear old prompts
        try {
            sections := IniRead(CONFIG_FILE)
            for section in StrSplit(sections, "`n") {
                if (SubStr(section, 1, 6) == "Prompt") {
                    try IniDelete(CONFIG_FILE, section)
                }
            }
        } catch {
            ; File might not exist
        }

        ; Write new prompts
        for i, prompt in prompts {
            section := "Prompt" i

            IniWrite(prompt.title, CONFIG_FILE, section, "title")
            escapedPrompt := StrReplace(prompt.prompt, "`n", "\n")
            IniWrite(escapedPrompt, CONFIG_FILE, section, "prompt")
            IniWrite(prompt.freq, CONFIG_FILE, section, "freq")
            IniWrite(prompt.start, CONFIG_FILE, section, "start")

            ; Only save days for weekly prompts, otherwise save empty string
            daysToSave := ""
            if (prompt.freq == "Every Week" && IsObject(prompt.days)) {
                daysToSave := StrJoin(prompt.days, ",")
            }

            IniWrite(daysToSave, CONFIG_FILE, section, "days")

            IniWrite(prompt.dayOfMonth, CONFIG_FILE, section, "day_of_month")
            IniWrite(prompt.enabled ? "1" : "0", CONFIG_FILE, section, "enabled")
            LogDebug("Saved prompt " section ": title=" . prompt.title . ", freq=" . prompt.freq . ", days=" . daysToSave . ", day_of_month=" . prompt.dayOfMonth . ", enabled=" . prompt.enabled)
        }
    } catch as err {
        LogDebug("Error saving prompts: " err.Message . " - " . err.Stack)
    }
}

SaveResult(title, result) {
    try {
        dir := SAVED_DIR "\" title
        DirCreate(dir)
        fileName := Format("{1}\{2}_{3}.txt", dir, title, FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss"))
        FileAppend(result, fileName)
        LogDebug("Result saved: " fileName)
        return true
    } catch as saveErr {
        LogDebug("Error saving result: " saveErr.Message)
        return false
    }
}

GetSavedResults() {
    results := []
    if !DirExist(SAVED_DIR) {
        return results
    }
    Loop Files SAVED_DIR "\*.*", "D" {
        Loop Files A_LoopFilePath "\*.txt" {
            if RegExMatch(A_LoopFileName, "(.+)_(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})\.txt", &match) {
                results.Push({title: match[1], date: match[2], path: A_LoopFilePath})
            }
        }
    }
    return results
}

DeleteResult(path) {
    try {
        LogDebug("Attempting to delete: " path)
        if !FileExist(path) {
            LogDebug("Delete failed: File not found")
            return
        }
        FileDelete(path)
        if !FileExist(path) {
            LogDebug("Successfully deleted: " path)
        } else {
            LogDebug("Delete failed: File still exists after FileDelete")
        }
    } catch as delErr {
        LogDebug("Error deleting: " delErr.Message)
    }
}
