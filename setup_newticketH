@echo off
setlocal EnableDelayedExpansion

set PYTHON_URL=https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe
set PYTHON_INSTALLER=python-3.10.11-amd64.exe
set ZIP_URL=https://github.com/SugarSquirrel/tickets_hunter/archive/refs/heads/main.zip
set ZIP_NAME=tickets_hunter_main.zip
set EXTRACT_DIR=%USERPROFILE%\tickets_hunter_setup
set TARGET_SUBDIR=tickets_hunter-main
set PYTHON_DIR=%LOCALAPPDATA%\Programs\Python\Python310
set PYTHON_SCRIPTS=%LOCALAPPDATA%\Programs\Python\Python310\Scripts

echo ============================================================
echo  tickets_hunter setup - Windows
echo ============================================================

:: --- Step 1: Check Python 3.10.x ---
echo [1/5] Checking Python 3.10...

py -3.10 --version >nul 2>&1
if %ERRORLEVEL% == 0 (
    set PYTHON_CMD=py -3.10
    echo [OK] Python 3.10 found via py launcher.
    goto ADD_PATH
)

where python >nul 2>&1
if %ERRORLEVEL% == 0 (
    python --version 2>&1 | findstr "3.10" >nul
    if !ERRORLEVEL! == 0 (
        set PYTHON_CMD=python
        echo [OK] Python 3.10 already installed.
        goto ADD_PATH
    )
)

echo Python 3.10 not found. Downloading installer...
curl -L "%PYTHON_URL%" -o "%TEMP%\%PYTHON_INSTALLER%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to download Python installer.
    pause
    exit /b 1
)

echo Installing Python 3.10.11...
"%TEMP%\%PYTHON_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Python installation failed.
    pause
    exit /b 1
)
echo [OK] Python 3.10.11 installed.
set PYTHON_CMD=python

:ADD_PATH
:: --- Step 2: Add Python to system PATH permanently ---
echo [2/5] Adding Python to PATH...

:: Add to current session
set "PATH=%PYTHON_DIR%;%PYTHON_SCRIPTS%;%PATH%"

:: Add to user PATH permanently via registry
reg query "HKCU\Environment" /v PATH >nul 2>&1
if %ERRORLEVEL% == 0 (
    for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul ^| findstr PATH') do set CURRENT_PATH=%%B
) else (
    set CURRENT_PATH=
)

echo !CURRENT_PATH! | findstr /i "Python310" >nul
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

:DOWNLOAD_ZIP
:: --- Step 3: Download ZIP ---
echo [3/5] Downloading tickets_hunter (main branch)...
if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"
curl -L "%ZIP_URL%" -o "%EXTRACT_DIR%\%ZIP_NAME%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to download zip.
    pause
    exit /b 1
)
echo [OK] Downloaded.

:: --- Step 4: Extract ZIP ---
echo [4/5] Extracting...
powershell -Command "Expand-Archive -Path '%EXTRACT_DIR%\%ZIP_NAME%' -DestinationPath '%EXTRACT_DIR%' -Force"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Extraction failed.
    pause
    exit /b 1
)
echo [OK] Extracted.

:: --- Step 5: cd and pip install requirements ---
echo [5/5] Installing requirements...
set TARGET_PATH=%EXTRACT_DIR%\%TARGET_SUBDIR%
if not exist "%TARGET_PATH%" (
    echo [ERROR] Target path not found: %TARGET_PATH%
    pause
    exit /b 1
)
cd /d "%TARGET_PATH%"
echo [OK] Now in: %TARGET_PATH%

if not exist "requirement.txt" (
    echo [ERROR] requirement.txt not found.
    pause
    exit /b 1
)

%PYTHON_CMD% -m pip install -r requirement.txt
if %ERRORLEVEL% neq 0 (
    echo [ERROR] pip install failed.
    pause
    exit /b 1
)
echo [OK] Requirements installed.

echo.
echo ============================================================
echo  Setup complete. Working dir: %TARGET_PATH%
echo  Next step: %PYTHON_CMD% src\settings.py
echo ============================================================
pause
endlocal
