# ahkV1ollama
Ollama implementation in AHK v1.1
Ollama Chat Interface
This repository contains an AutoHotkey (AHK) script that provides a graphical user interface (GUI) for interacting with an Ollama chat API. The script is optimized for performance and compatibility and offers a user-friendly way to load models, send prompts, and view responses.

Features
GUI Chat Interface: A clean, responsive interface for chatting with the Ollama API.
Dynamic Model Loading: Retrieves available models from the API endpoint (/api/tags) and populates a dropdown list.
Prompt Handling: Sends user prompts to the API (/api/generate) and displays the generated responses.
Debug Logging: Logs key events and errors to a debug file (ollama_debug.txt) for troubleshooting.
Chat History Management: Maintains a conversation log with options to clear the chat.

Usage
Set the Server URL:

The default URL is http://localhost:11434. Modify it in the GUI or update the serverUrl variable in the script if needed.
Load Models:

Click the Load Models button to fetch available models from the server. The models will populate the dropdown list.
Select a Model:

Choose your desired model from the dropdown menu.
Send a Prompt:

Type your prompt into the provided text field and click Send Prompt.
The response from the model will appear in the chat history area.
Clear Chat:

Use the Clear Chat button to clear the conversation history.
View Debug Log:

Click View Debug Log to open the debug log file (ollama_debug.txt) in Notepad, which records key events and debug messages.
Script Overview
Performance & Compatibility Settings:

Uses #NoEnv for enhanced performance and #SingleInstance Force to avoid multiple instances.
GUI Components:

Contains controls for entering the server URL, selecting a model, displaying chat history, inputting prompts, and several action buttons.
HTTP Requests:

Uses the WinHttp.WinHttpRequest.5.1 COM object to make GET and POST requests to the Ollama API.
JSON Handling:

Constructs and escapes JSON strings for communication with the API.
Debug Logging:

Records events and errors to a log file for troubleshooting.
Customization
Server URL & API Endpoints:

Modify the serverUrl variable or adjust the endpoints in the script to match your server configuration.
User Interface:

Customize the layout, fonts, and controls by editing the GUI section of the script.
License
This project is licensed under the MIT License. See the LICENSE file for details.

Contributing
Contributions are welcome! If you have suggestions or bug fixes, please fork the repository and submit a pull request.

Support
For issues or questions, please open an issue in the GitHub repository.
