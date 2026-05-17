@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM ticket-bot setup for Windows VM (no conda / no venv)
REM Installs: Python 3.11 + ticket-bot + Playwright Chromium
REM (No system Chrome required; uses Playwright's bundled browser)
REM ============================================================

set PYTHON_VERSION=3.11.9
set PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-amd64.exe
set PYTHON_INSTALLER=python-%PYTHON_VERSION%-amd64.exe
set PYTHON_DIR=%LOCALAPPDATA%\Programs\Python\Python311
set PYTHON_SCRIPTS=%LOCALAPPDATA%\Programs\Python\Python311\Scripts

set ZIP_URL=https://github.com/SugarSquirrel/ticket-bot-public/archive/refs/heads/main.zip
set ZIP_NAME=ticket_bot_main.zip
set EXTRACT_DIR=%USERPROFILE%\ticket_bot_setup
set TARGET_SUBDIR=ticket-bot-public-main

echo ============================================================
echo  ticket-bot setup - Windows VM
echo ============================================================

REM --- Step 1: Check / install Python 3.11 ---
echo [1/6] Checking Python 3.11...

py -3.11 --version >nul 2>&1
if %ERRORLEVEL% == 0 (
    set PYTHON_CMD=py -3.11
    echo [OK] Python 3.11 found via py launcher.
    goto ADD_PATH
)

where python >nul 2>&1
if %ERRORLEVEL% == 0 (
    python --version 2>&1 | findstr "3.11" >nul
    if !ERRORLEVEL! == 0 (
        set PYTHON_CMD=python
        echo [OK] Python 3.11 already installed.
        goto ADD_PATH
    )
)

echo Python 3.11 not found. Downloading installer...
curl -L "%PYTHON_URL%" -o "%TEMP%\%PYTHON_INSTALLER%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to download Python installer.
    pause
    exit /b 1
)

echo Installing Python %PYTHON_VERSION%...
"%TEMP%\%PYTHON_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Python installation failed.
    pause
    exit /b 1
)
echo [OK] Python %PYTHON_VERSION% installed.
set PYTHON_CMD=python

:ADD_PATH
REM --- Step 2: Persist Python in user PATH ---
echo [2/6] Adding Python to PATH...

set "PATH=%PYTHON_DIR%;%PYTHON_SCRIPTS%;%PATH%"

reg query "HKCU\Environment" /v PATH >nul 2>&1
if %ERRORLEVEL% == 0 (
    for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul ^| findstr PATH') do set CURRENT_PATH=%%B
) else (
    set CURRENT_PATH=
)

echo !CURRENT_PATH! | findstr /i "Python311" >nul
if %ERRORLEVEL% neq 0 (
    if defined CURRENT_PATH (
        setx PATH "%PYTHON_DIR%;%PYTHON_SCRIPTS%;!CURRENT_PATH!" >nul
    ) else (
        setx PATH "%PYTHON_DIR%;%PYTHON_SCRIPTS%" >nul
    )
    echo [OK] Python added to user PATH permanently.
) else (
    echo [OK] Python already in PATH, skipping.
)

REM --- Step 3: Download ticket-bot from fork ---
echo [3/6] Downloading ticket-bot (fork main branch)...
if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"
curl -L "%ZIP_URL%" -o "%EXTRACT_DIR%\%ZIP_NAME%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to download repository zip.
    pause
    exit /b 1
)
echo [OK] Downloaded.

REM --- Step 4: Extract ---
echo [4/6] Extracting...
powershell -Command "Expand-Archive -Path '%EXTRACT_DIR%\%ZIP_NAME%' -DestinationPath '%EXTRACT_DIR%' -Force"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Extraction failed.
    pause
    exit /b 1
)

set TARGET_PATH=%EXTRACT_DIR%\%TARGET_SUBDIR%
if not exist "%TARGET_PATH%" (
    echo [ERROR] Extracted path not found: %TARGET_PATH%
    pause
    exit /b 1
)
echo [OK] Extracted to %TARGET_PATH%.

REM --- Step 5: pip install -e . + Playwright Chromium ---
echo [5/6] Installing ticket-bot, deps, and Playwright Chromium (~5-10 min total)...
cd /d "%TARGET_PATH%"
if not exist "pyproject.toml" (
    echo [ERROR] pyproject.toml not found in %TARGET_PATH%.
    pause
    exit /b 1
)

%PYTHON_CMD% -m pip install --upgrade pip
%PYTHON_CMD% -m pip install -e .
if %ERRORLEVEL% neq 0 (
    echo [ERROR] pip install failed.
    pause
    exit /b 1
)
echo [OK] Python packages installed.

echo Downloading Playwright Chromium (~120 MB)...
%PYTHON_CMD% -m playwright install chromium
if %ERRORLEVEL% neq 0 (
    echo [ERROR] playwright install chromium failed.
    pause
    exit /b 1
)
echo [OK] Playwright Chromium ready.

REM --- Step 6: Set up config.yaml from template ---
echo [6/6] Preparing config.yaml...
if not exist "config.yaml" (
    copy "config.yaml.example" "config.yaml" >nul
    echo [OK] config.yaml created from config.yaml.example.
) else (
    echo [OK] config.yaml already exists, skipping.
)

echo.
echo ============================================================
echo  Setup complete.
echo  Project dir: %TARGET_PATH%
echo.
echo  NEXT STEPS:
echo  1. Edit config.yaml:
echo     - events[0].url / date_keyword / area_keyword / sale_time
echo     - sessions[0].tixcraft_sid (TIXUISID cookie value)
echo     - browser.engine should already be 'playwright' (default)
echo  2. Verify login:         ticket-bot login
echo  3. Dry-run test:         ticket-bot run --dry-run
echo  4. Real run (countdown): ticket-bot countdown
echo.
echo  cd %TARGET_PATH%
echo ============================================================
pause
endlocal
