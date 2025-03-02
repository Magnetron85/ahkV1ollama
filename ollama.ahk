#NoEnv  ; Recommended for performance and compatibility
#SingleInstance Force
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory
SetBatchLines, -1  ; Makes the script run at maximum speed

; GUI variables
global serverUrl := "http://localhost:11434"
global chatHistory := ""
global selectedModel := ""
global isProcessing := false

; Create the GUI with adjusted layout
Gui, Font, s10, Segoe UI
; Server URL controls
Gui, Add, Text, x10 y10 w100 h25, Server URL:
Gui, Add, Edit, x110 y10 w280 h25 vserverUrl, %serverUrl%
; Model selection controls (increased ComboBox height for a larger dropdown)
Gui, Add, Text, x10 y40 w100 h25, Model:
Gui, Add, ComboBox, x110 y40 w280 h150 vSelectedModel, 
Gui, Add, Button, x400 y40 w100 h25 gLoadModels, Load Models
; Chat history display (moved down to avoid overlap)
Gui, Add, Edit, x10 y200 w600 h300 vChatHistory ReadOnly, Welcome to Ollama Chat!`n`n
; User prompt input (moved down)
Gui, Add, Edit, x10 y510 w600 h60 vUserPrompt,
; Action buttons
Gui, Add, Button, x10 y580 w200 h30 gSendPrompt, Send Prompt
Gui, Add, Button, x220 y580 w200 h30 gClearChat, Clear Chat
Gui, Add, Button, x430 y580 w180 h30 gShowDebugLog, View Debug Log

Gui, Show, w620 h630, Ollama Chat Interface

; Create debug log
FileDelete, %A_ScriptDir%\ollama_debug.txt
LogDebug("Script started. Interface created.")

; Automatically load models on startup.
Gui, Submit, NoHide
LogDebug("Initial model: " . selectedModel)
gosub, LoadModels
Return

LoadModels:
    Gui, Submit, NoHide  ; Update variables from GUI (including serverUrl)
    if (isProcessing) {
        AppendToChat("[SYSTEM] Already processing a request. Please wait.")
        return
    }
    
    isProcessing := true
    AppendToChat("[SYSTEM] Loading models from " . serverUrl . "/api/tags")
    LogDebug("Loading models from API at " . serverUrl . "/api/tags")
    
    ; Simple HTTP GET to fetch models
    httpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    httpObj.Open("GET", serverUrl . "/api/tags", false)
    httpObj.Send()
    
    responseText := httpObj.ResponseText
    LogDebug("Response received, length: " . StrLen(responseText))
    
    ; Parse model names using regex
    modelsStr := ""
    modelCount := 0
    pos := 1
    Loop {
        foundPos := RegExMatch(responseText, """name"":""([^""]+)""", match, pos)
        if (!foundPos)
            break
            
        modelName := match1
        LogDebug("Found model: " . modelName)
        modelCount++
        
        ; Build dropdown list string
        if (modelsStr != "")
            modelsStr .= "|"
        modelsStr .= modelName
        
        ; Move past the current match
        pos := foundPos + StrLen(match)
    }
    
    ; Update the model dropdown
    if (modelCount > 0) {
        GuiControl,, SelectedModel, |%modelsStr%
        GuiControl, Choose, SelectedModel, 1
        Gui, Submit, NoHide
        AppendToChat("[SYSTEM] Loaded " . modelCount . " models.")
    } else {
        AppendToChat("[SYSTEM] No models found.")
    }
    
    isProcessing := false
Return

SendPrompt:
    if (isProcessing) {
        AppendToChat("[SYSTEM] Already processing a request. Please wait.")
        return
    }
    
    Gui, Submit, NoHide
    
    if (UserPrompt = "") {
        AppendToChat("[SYSTEM] Please enter a prompt.")
        Return
    }
    
    if (selectedModel = "") {
        AppendToChat("[SYSTEM] Please select a model first.")
        Return
    }
    
    isProcessing := true
    AppendToChat("> " . UserPrompt)
    LogDebug("Processing prompt: " . UserPrompt)
    
    ; Save and clear the user prompt
    promptText := UserPrompt
    GuiControl,, UserPrompt, 
    AppendToChat("[SYSTEM] Processing request...")
    
    ; Build JSON request manually
    jsonData := "{""model"":""" . selectedModel . """,""prompt"":""" . EscapeJSON(promptText) . """,""stream"":false}"
    LogDebug("Request data: " . jsonData)
    
    ; Send HTTP POST request to generate a response
    httpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    httpObj.SetTimeouts(600000, 600000, 600000, 600000)
    httpObj.Open("POST", serverUrl . "/api/generate", false)
    httpObj.SetRequestHeader("Content-Type", "application/json")
    httpObj.Send(jsonData)
    
    responseText := httpObj.ResponseText
    LogDebug("Response received, length: " . StrLen(responseText))
    
    ; Extract and unescape the response text
    responsePos := InStr(responseText, """response"":""")
    if (responsePos > 0) {
        responsePos += 12  ; Skip the field name and quote
        endPos := responsePos
        inEscape := false
        Loop, Parse, % SubStr(responseText, responsePos)
        {
            if (inEscape) {
                inEscape := false
            } else if (A_LoopField = "\") {
                inEscape := true
            } else if (A_LoopField = """" && !inEscape) {
                break
            }
            endPos++
        }
        responseValue := SubStr(responseText, responsePos, endPos - responsePos)
        responseValue := StrReplace(responseValue, "\""", """")
        responseValue := StrReplace(responseValue, "\\", "\")
        responseValue := StrReplace(responseValue, "\n", "`n")
        responseValue := StrReplace(responseValue, "\r", "`r")
        responseValue := StrReplace(responseValue, "\t", "`t")
        responseValue := StrReplace(responseValue, "\u003c", "<")
        responseValue := StrReplace(responseValue, "\u003e", ">")
        
        ; Remove any <think> section
        thinkStart := InStr(responseValue, "<think>")
        if (thinkStart > 0) {
            thinkEnd := InStr(responseValue, "</think>", false, thinkStart)
            if (thinkEnd > thinkStart) {
                beforeThink := SubStr(responseValue, 1, thinkStart - 1)
                afterThink := SubStr(responseValue, thinkEnd + 8)  ; 8 = length of "</think>"
                responseValue := beforeThink . afterThink
            }
        }
        AppendToChat(Trim(responseValue))
    } else {
        AppendToChat("[SYSTEM] Error: Could not extract response from model output.")
    }
    
    isProcessing := false
Return

ShowDebugLog:
    Run, notepad.exe %A_ScriptDir%\ollama_debug.txt
Return

ClearChat:
    chatHistory := "Chat cleared. Model: " . selectedModel . "`n`n"
    GuiControl,, ChatHistory, %chatHistory%
    LogDebug("Chat cleared")
Return

AppendToChat(text) {
    chatHistory .= text . "`n`n"
    GuiControl,, ChatHistory, %chatHistory%
    ; Auto-scroll to the bottom
    ControlSend, Edit1, ^{End}, Ollama Chat Interface
}

LogDebug(text) {
    timestamp := A_Hour . ":" . A_Min . ":" . A_Sec . "." . A_MSec
    FileAppend, [%timestamp%] %text%`n, %A_ScriptDir%\ollama_debug.txt
}

; Escape JSON string for sending
EscapeJSON(str) {
    result := StrReplace(str, "\", "\\")
    result := StrReplace(result, """", "\""")
    result := StrReplace(result, "`n", "\n")
    result := StrReplace(result, "`r", "\r")
    result := StrReplace(result, "`t", "\t")
    return result
}

; Handle GUI close
GuiClose:
    LogDebug("Application closing")
    ExitApp
