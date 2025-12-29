#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn

#Include "JSON.ahk"

; ---------- AI Call ----------

CallAI(prompt) {
    LogDebug("Calling AI with prompt: " SubStr(prompt, 1, 50) "...")
    
    try {
        apiKey := Trim(IniRead(CONFIG_FILE, "Settings", "api_key", ""))
        if (apiKey == "") {
            return "Error: api_key not set in config.ini [Settings] api_key="
        }
        
        model := Trim(IniRead(CONFIG_FILE, "Settings", "model", "gemini-1.5-flash"))
        
        ; Build payload using JSON library with grounding search
        payload := {
            contents: [
                {
                    parts: [
                        { text: prompt }
                    ]
                }
            ],
            tools: [
                {
                    google_search: {}
                }
            ]
        }
        jsonPayload := JSON.Stringify(payload)
        
        url := "https://generativelanguage.googleapis.com/v1beta/models/" model ":generateContent?key=" apiKey
        
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", url, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(jsonPayload)
        
        if (whr.Status == 200) {
            responseObj := JSON.Parse(whr.ResponseText)
            try {
                ; Navigate the Gemini response structure
                ; responseObj is a Map, arrays are Array
                result := responseObj["candidates"][1]["content"]["parts"][1]["text"]
                LogDebug("AI call successful")
                return result
            } catch {
                LogDebug("Error parsing Gemini JSON response")
                return "Error: Unexpected response structure from AI."
            }
        } else {
            return "Error: HTTP " whr.Status " - " whr.StatusText
        }
    } catch as aiErr {
        LogDebug("AI call error: " aiErr.Message)
        return "Error: " aiErr.Message
    }
}
