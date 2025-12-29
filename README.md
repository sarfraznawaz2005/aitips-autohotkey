# AI Tips

An AutoHotKey v2 application that generates AI-powered tips and notifications based on user-defined prompts at scheduled intervals using Google Gemini AI.

## Overview

AI Tips runs in the system tray and automatically generates content using AI based on configurable prompts. It supports various scheduling frequencies from every minute to monthly, and saves generated tips for later viewing.

## Features

- **Scheduled AI Generation**: Generate tips at specified intervals (every minute, 5 minutes, hourly, daily, weekly, monthly, or once)
- **Prompt Management**: Add, edit, and delete custom prompts
- **Result Viewing**: View generated tips in a dedicated window
- **Tip Saving**: Save interesting tips for future reference
- **System Tray Integration**: Minimal UI with tray menu access
- **Flexible Scheduling**: Support for different time patterns and days of the week

## Installation

1. Download all `.ahk` files and `config.ini` to a directory
2. Install AutoHotKey v2 (https://www.autohotkey.com/)
3. Edit `config.ini` to add your Google Gemini API key
4. Run `main.ahk` or compile to `main.exe` for standalone execution

## Configuration

Edit `config.ini`:

```ini
[Settings]
api_key=your_google_gemini_api_key_here
model=gemini-2.5-flash

[Prompt1]
title=Quote
prompt=Tell me a nice quote.
freq=Every 5 Minutes
start=20000101090000
days=
day_of_month=
```

### Settings Section
- `api_key`: Your Google Gemini API key (required)
- `model`: Gemini model to use (default: gemini-1.5-flash)

### Prompt Sections
Each prompt is a separate section (Prompt1, Prompt2, etc.)
- `title`: Display name for the prompt
- `prompt`: The text sent to AI
- `freq`: Frequency options:
  - Once
  - Every Minute
  - Every 5 Minutes
  - Every 15 Minutes
  - Every 30 Minutes
  - Every Hour
  - Every 3 Hours
  - Every Day
  - Every Week
  - Every Month
- `start`: Start time in YYYYMMDDHHMMSS format
- `days`: Comma-separated days for weekly prompts (Mon,Tue,Wed,etc.)
- `day_of_month`: Day number for monthly prompts (1-31)

## Usage

1. **Run the App**: Execute `main.ahk` or `main.exe`
2. **Access Menu**: Right-click the tray icon (folder icon)
3. **Manage Prompts**: Select "Prompts" to add/edit/delete prompts
4. **View Saved Tips**: Select "Saved Tips" to browse saved results
5. **Reload**: Use "Reload" to restart the app after config changes

### Adding a Prompt

1. Open "Prompts" from tray menu
2. Click "Add New"
3. Enter title and prompt text
4. Select frequency
5. Set time/date as needed
6. For weekly: select days
7. For monthly: select day of month
8. Click "Save"

### Viewing Results

When a prompt executes, a result window appears with the AI-generated content. Click "Save" to keep it, or "Close" to dismiss.

## Code Structure

### Main Files

- `main.ahk`: Entry point, tray menu, includes all modules
- `config.ini`: Configuration file
- `main.exe`: Compiled executable (optional)

### Modules

- `utils.ahk`: Utility functions for loading/saving prompts and results
- `add_prompt.ahk`: GUI for adding/editing prompts
- `view_prompts.ahk`: GUI for listing and managing prompts
- `view_saved.ahk`: GUI for viewing saved tips
- `result_window.ahk`: GUI for displaying AI results
- `scheduler.ahk`: Scheduling logic and execution
- `ai_call.ahk`: Google Gemini API integration
- `JSON.ahk`: JSON parsing library

### Key Functions

#### Utils (`utils.ahk`)
- `LoadPrompts()`: Load all prompts from config.ini
- `SavePrompts(prompts)`: Save prompts array to config.ini
- `SaveResult(title, result)`: Save a result to file
- `GetSavedResults()`: Get list of saved results

#### Scheduler (`scheduler.ahk`)
- `InitScheduler()`: Initialize the scheduler
- `CheckPrompts()`: Check and execute due prompts
- `ShouldRun(prompt, now)`: Determine if a prompt should run
- `ExecutePrompt(prompt)`: Call AI and show result

#### AI Integration (`ai_call.ahk`)
- `CallAI(prompt)`: Send prompt to Gemini API and return response

#### GUIs
- `ShowAddPrompt()`: Add/edit prompt dialog
- `ShowViewPrompts()`: Prompts management window
- `ShowViewSaved()`: Saved tips browser
- `ShowResult(result, title)`: Result display window

## Modifying and Adding Features

### Adding a New Frequency

1. Add to `freqList` in `add_prompt.ahk`
2. Add logic in `ShouldRun()` in `scheduler.ahk`
3. Update `UpdateControls()` for any new UI elements

Example for "Every 2 Hours":
```autohotkey
; In add_prompt.ahk
freqList := ["Once", "Every Minute", ..., "Every 2 Hours"]

; In scheduler.ahk ShouldRun()
if (freq == "Every 2 Hours") {
    return (FormatTime(now, "mm") == "00" && Mod(Number(FormatTime(now, "HH")), 2) == 0)
}
```

### Adding New Prompt Fields

1. Add to prompt object structure in `utils.ahk` LoadPrompts/SavePrompts
2. Update GUI in `add_prompt.ahk`
3. Update config.ini saving/loading
4. Modify scheduler logic if needed

### Changing AI Provider

1. Modify `CallAI()` in `ai_call.ahk`
2. Update config.ini for new API settings
3. Change JSON parsing for new response format

### Adding Notification Types

Currently shows GUI windows. To add toast notifications:

1. Use Windows API or external tools
2. Modify `ExecutePrompt()` in `scheduler.ahk`

### Custom Result Processing

Modify `ShowResult()` in `result_window.ahk` to add formatting, copying, etc.

### Logging Enhancements

Currently logs to debug.log. Enhance in `LogDebug()` calls throughout.

## Run, Test

NOTE: Check errors and logs, fix, run and stop on autopilot.

- Run the script with `/ErrorStdOut` to capture any startup errors to the console if possible.
- Run script (Windows): `"C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey64.exe" /ErrorStdOut {SCRIPT_PATH_HERE}`
- Run a specific module (if modularized): adjust the path accordingly.
- Run tests (if `test/runner.ahk` exists): `"C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey64.exe" test\\runner.ahk`
- While debugging, start and stop the script automatically so you can check back logs eg `error.log` or `debug.log`.
- You have powershell powertool available to use any time.
- Always keep backup of script you are working on by copying it with `.bak` extension before making changes. Use this backup any time you mess up the script.

Note: `error.log` will be provided to you automatically everytime you run the script.