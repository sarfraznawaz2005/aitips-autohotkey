#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn

; ---------- Scheduler ----------

global LAST_RUNS := Map()

InitScheduler() {
    LogDebug("Initializing scheduler")
    ; Calculate time to next minute for alignment
    seconds := Number(FormatTime(A_Now, "ss"))
    msToNextMinute := (60 - seconds) * 1000
    
    LogDebug("Waiting " msToNextMinute "ms to align with next minute")
    ; Wait for next minute boundary to start the periodic check
    SetTimer(StartScheduler, -msToNextMinute)
}

StartScheduler() {
    CheckPrompts()
    SetTimer(CheckPrompts, 60000)
}

CheckPrompts() {
    global LAST_RUNS
    prompts := LoadPrompts()
    now := A_Now
    currentMinute := FormatTime(now, "yyyyMMddHHmm")
    
    for prompt in prompts {
        if (prompt.enabled && ShouldRun(prompt, now)) {
            ; Check if already run this minute to avoid duplicates
            key := prompt.title "_" currentMinute
            if (!LAST_RUNS.Has(key)) {
                LAST_RUNS[key] := true
                LogDebug("Executing prompt: " prompt.title)
                ExecutePrompt(prompt)
            }
        }
    }
    
    ; Clean up old LAST_RUNS (optional, but good for memory)
    if (LAST_RUNS.Count > 100) {
        for k, v in LAST_RUNS {
            ; If key is from more than 10 minutes ago, delete
            if (SubStr(k, -12) < FormatTime(DateAdd(now, -10, "minutes"), "yyyyMMddHHmm"))
                LAST_RUNS.Delete(k)
        }
    }
}

ShouldRun(prompt, now) {
    freq := prompt.freq
    ; Ensure start is a clean 14-char numeric string
    cleanStart := StrReplace(prompt.start, ":", "")
    startTime := SubStr(cleanStart, -6) ; HHmmss
    currentTime := SubStr(now, 9, 6) ; HHmmss
    
    ; Basic time check for specific schedules
    isScheduleTime := (SubStr(currentTime, 1, 4) == SubStr(startTime, 1, 4)) ; Match HHmm
    
    if (freq == "Once") {
        return (now >= cleanStart && !HasRunOnce(prompt))
    }
    if (freq == "Every Minute") {
        return true
    }
    if (freq == "Every 5 Minutes") {
        return (Mod(Number(FormatTime(now, "mm")), 5) == 0)
    }
    if (freq == "Every 15 Minutes") {
        return (Mod(Number(FormatTime(now, "mm")), 15) == 0)
    }
    if (freq == "Every 30 Minutes") {
        return (Mod(Number(FormatTime(now, "mm")), 30) == 0)
    }
    if (freq == "Every Hour") {
        return (FormatTime(now, "mm") == "00")
    }
    if (freq == "Every 3 Hours") {
        return (FormatTime(now, "mm") == "00" && Mod(Number(FormatTime(now, "HH")), 3) == 0)
    }
    if (freq == "Every Day") {
        return isScheduleTime
    }
    if (freq == "Every Week") {
        if (isScheduleTime) {
            dayName := FormatTime(now, "ddd")
            for d in prompt.days {
                if (d == dayName) {
                    return true
                }
            }
        }
        return false
    }
    if (freq == "Every Month") {
        if (isScheduleTime) {
            dayOfMonth := FormatTime(now, "d")
            return (dayOfMonth == prompt.dayOfMonth)
        }
        return false
    }
    
    return false
}

HasRunOnce(prompt) {
    ; For "Once", we might need a way to track if it finished
    ; For now, let's assume if it's in the past and we are checking, we should run it if not run before.
    ; This is tricky without persistent state of "completed" tasks.
    return false 
}

ExecutePrompt(prompt) {
    try {
        result := CallAI(prompt.prompt)
        ShowResult(result, prompt.title)
        
        ; If frequency is "Once", remove it so it doesn't run again
        if (prompt.freq == "Once") {
            prompts := LoadPrompts()
            newPrompts := []
            for p in prompts {
                ; Use title and start as unique identifier for now
                if (p.title != prompt.title || p.start != prompt.start) {
                    newPrompts.Push(p)
                }
            }
            SavePrompts(newPrompts)
            LogDebug("Removed 'Once' prompt: " prompt.title)
        }
    } catch as exErr {
        LogDebug("Error executing prompt " prompt.title ": " exErr.Message)
    }
}