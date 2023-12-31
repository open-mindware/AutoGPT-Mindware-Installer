@echo off
setlocal

REM Get the full path to the script's current directory
set CURRENT_DIR=%~dp0

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker could not be found.
    echo Please install Docker and then re-run this script.
    exit /b 1
)

REM Set up necessary variables
REM Update the WORKDIR to point to the parent directory
set "WORKDIR=%CURRENT_DIR%..\AutoGPT"
set "ENV_FILE=.env"
set "AI_SETTINGS_FILE=ai_settings.yaml"
set "PLUGINS_CONFIG_FILE=plugins_config.yaml"
set "DOCKER_COMPOSE_FILE=docker-compose.yml"
set "PLUGINS_DIR=plugins"

REM Create directory for AutoGPT in the parent of the current directory and navigate into it, if it doesn't exist
if not exist "%WORKDIR%" mkdir "%WORKDIR%"
cd /d "%WORKDIR%"

REM Create necessary files if they don't exist
type nul > "%ENV_FILE%"
type nul > "%AI_SETTINGS_FILE%"

REM Ask for API keys and append them to the environment file
set /p OPENAI_API_KEY=Please enter your OpenAI API key: 
echo OPENAI_API_KEY=%OPENAI_API_KEY% >> "%ENV_FILE%"

set /p MINDWARE_API_KEY=Please enter your Mindware API key: 
echo MINDWARE_API_KEY=%MINDWARE_API_KEY% >> "%ENV_FILE%"

REM Create plugins_config.yaml file if it doesn't exist
if not exist "%PLUGINS_CONFIG_FILE%" (
    (
    echo MindwarePlugin:
    echo   config: {}
    echo   enabled: true
    ) > "%PLUGINS_CONFIG_FILE%"
)

REM Create docker-compose.yml file if it doesn't exist
if not exist "%DOCKER_COMPOSE_FILE%" (
    (
    echo version: "3.9"
    echo services:
    echo   auto-gpt:
    echo     image: significantgravitas/auto-gpt
    echo     env_file:
    echo       - .env
    echo     profiles: ["exclude-from-up"]
    echo     volumes:
    echo       - ./auto_gpt_workspace:/app/auto_gpt_workspace
    echo       - ./data:/app/data
    echo       - ./logs:/app/logs
    echo       - ./plugins:/app/plugins
    echo       - type: bind
    echo         source: ./ai_settings.yaml
    echo         target: /app/ai_settings.yaml
    echo       - type: bind
    echo         source: ./plugins_config.yaml
    echo         target: /app/plugins_config.yaml
    ) > "%DOCKER_COMPOSE_FILE%"
)

REM Pull the necessary Docker image
docker pull significantgravitas/auto-gpt

REM Create directory for plugins if it doesn't exist and navigate into it
if not exist "%PLUGINS_DIR%" mkdir "%PLUGINS_DIR%"
cd /d "%PLUGINS_DIR%"

REM Pull the latest Mindware repository, zip it, and clean up
if not exist "AutoGPT-Mindware" (
    git clone https://github.com/open-mindware/AutoGPT-Mindware.git
    REM Use 7-Zip to archive the folder, assuming it's installed and available in PATH.
    7z a -r AutoGPT-Mindware.zip .\AutoGPT-Mindware\
    rmdir /s /q .\AutoGPT-Mindware
)

REM Navigate back to the working directory
cd /d "%WORKDIR%"

REM Create a temporary script in the system's temp directory.
REM This script will delete "AutoGPT-Mindware-Installer" and then run the Docker container.
set TEMP_SCRIPT=%TEMP%\tempScript.bat
(
echo @echo off
echo cd /d "%WORKDIR%"
echo rmdir /s /q "%CURRENT_DIR%"
echo docker compose run --rm auto-gpt --install-plugin-deps
) > "%TEMP_SCRIPT%"

REM Call the temporary script directly, without opening a new command prompt.
call "%TEMP_SCRIPT%"

REM End local environment and exit the script
endlocal
exit /b
