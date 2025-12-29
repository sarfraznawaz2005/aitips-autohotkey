#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn

; ------------------------------------------------------------------------------------------
; Global Error Handler
; ------------------------------------------------------------------------------------------

OnError(ShowError)
ShowError(e, *) {
    MsgBox("An error occurred:`n`n"
        . "File: " e.File "`n"
        . "Line: " e.Line "`n"
        . "Message: " e.Message, "Script Error", "Iconx")
    return true ; Suppress default dialog
}

; ---------- Global GUI Trackers ----------
global PROMPTS_GUI := ""
global ADD_PROMPT_GUI := ""
global SAVED_GUI := ""

; ---------- Logging ----------
global LOG_DEBUG := A_ScriptDir "\debug.log"

try FileDelete(LOG_DEBUG)

LogDebug(msg) {
    ;FileAppend(Format("[{1}] DEBUG: {2}`r`n", A_Now, msg), LOG_DEBUG)
}

; ---------- Includes ----------
#Include "utils.ahk"
#Include "add_prompt.ahk"
#Include "view_prompts.ahk"
#Include "view_saved.ahk"
#Include "result_window.ahk"
#Include "scheduler.ahk"
#Include "ai_call.ahk"

; ---------- Tray Icon and Menu ----------
A_IconTip := "AI Tips"
TraySetIcon("shell32.dll", 44)

A_TrayMenu.Delete()
A_TrayMenu.Add("Saved Tips", (*) => ShowViewSaved())
A_TrayMenu.Default := "Saved Tips"
A_TrayMenu.ClickCount := 1
A_TrayMenu.Add("Prompts", (*) => ShowViewPrompts())
A_TrayMenu.Add()
A_TrayMenu.Add("Reload", (*) => Reload())
A_TrayMenu.Add("Exit", (*) => ExitApp())

LogDebug("App started")

; ---------- Initialization ----------
Persistent(true)

try {
    InitScheduler()
} catch as initErr {
    LogDebug("CRITICAL ERROR during initialization: " initErr.Message "`n" initErr.Stack)
}

; ---------- Auto-execute end ----------