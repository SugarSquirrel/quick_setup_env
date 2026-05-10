@echo off
setlocal EnableDelayedExpansion

set PYTHON_URL=https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe
set PYTHON_INSTALLER=python-3.10.11-amd64.exe
set ZIP_URL=https://github.com/bouob/tickets_hunter/archive/refs/tags/v2026.04.23.zip
set ZIP_NAME=tickets_hunter_v2026.04.23.zip
set EXTRACT_DIR=%USERPROFILE%\tickets_hunter_setup
set TARGET_SUBDIR=tickets_hunter-2026.04.23

echo ============================================================
echo  tickets_hunter setup - Windows
echo ============================================================

:: --- Step 1: Check Python 3.10.x ---
echo [1/4] Checking Python 3.10...

:: Use "py" launcher first, fallback to "python"
set PYTHON_CMD=
py -3.10 --version >nul 2>&1
if %ERRORLEVEL% == 0 (
    set PYTHON_CMD=py -3.10
    echo [OK] Python 3.10 found via py launcher.
    goto DOWNLOAD_ZIP
)

:: Try python directly with a timeout-safe check
where python >nul 2>&1
if %ERRORLEVEL% == 0 (
    python --version 2>&1 | findstr "3.10" >nul
    if !ERRORLEVEL! == 0 (
        set PYTHON_CMD=python
        echo [OK] Python 3.10 already installed.
        goto DOWNLOAD_ZIP
    )
)

:: Python 3.10 not found, install it
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
set "PATH=%LOCALAPPDATA%\Programs\Python\Python310;%LOCALAPPDATA%\Programs\Python\Python310\Scripts;%PATH%"
set PYTHON_CMD=python

:DOWNLOAD_ZIP
:: --- Step 2: Download ZIP ---
echo [2/4] Downloading tickets_hunter zip...
if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"
curl -L "%ZIP_URL%" -o "%EXTRACT_DIR%\%ZIP_NAME%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to download zip.
    pause
    exit /b 1
)
echo [OK] Downloaded.

:: --- Step 3: Extract ZIP ---
echo [3/4] Extracting...
powershell -Command "Expand-Archive -Path '%EXTRACT_DIR%\%ZIP_NAME%' -DestinationPath '%EXTRACT_DIR%' -Force"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Extraction failed.
    pause
    exit /b 1
)
echo [OK] Extracted.

:: --- Step 4: cd and pip install requirements ---
echo [4/4] Installing requirements...
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
