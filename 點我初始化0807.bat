@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Keep this file ASCII-only so it works with both LF and CRLF line endings.
set "PYTHON_URL=https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe"
set "PYTHON_INSTALLER=python-3.10.11-amd64.exe"
set "PYTHON_DIR=%LOCALAPPDATA%\Programs\Python\Python310"
set "PYTHON_SCRIPTS=%PYTHON_DIR%\Scripts"
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"
set "ZIP_URL=https://github.com/SugarSquirrel/tickets_hunter/archive/refs/heads/0807-version-plus.zip"
set "ZIP_NAME=tickets_hunter_0807-version-plus.zip"
set "EXTRACT_DIR=%USERPROFILE%\0807-version-plus"
set "TARGET_SUBDIR=tickets_hunter-0807-version-plus"
set "TARGET_PATH=%EXTRACT_DIR%\%TARGET_SUBDIR%"

echo ============================================================
echo  tickets_hunter full setup - Windows
echo ============================================================
echo.

rem Step 1: Install Python 3.10.11 directly.
echo [1/5] Downloading the Python 3.10.11 installer...
curl.exe -L --fail "%PYTHON_URL%" -o "%TEMP%\%PYTHON_INSTALLER%"
if errorlevel 1 (
    echo [ERROR] Failed to download the Python installer.
    pause
    exit /b 1
)

echo Installing Python 3.10.11...
"%TEMP%\%PYTHON_INSTALLER%" /quiet InstallAllUsers=0 TargetDir="%PYTHON_DIR%" PrependPath=1 Include_pip=1 Include_launcher=1
if errorlevel 1 (
    echo [ERROR] Python installation failed.
    pause
    exit /b 1
)

if not exist "%PYTHON_EXE%" (
    echo [ERROR] Python was not found after installation:
    echo %PYTHON_EXE%
    pause
    exit /b 1
)
echo [OK] Python 3.10.11 is installed.

rem Step 2: Update PATH for this session and the current user.
echo [2/5] Configuring the Python PATH...
set "PATH=%PYTHON_DIR%;%PYTHON_SCRIPTS%;%PATH%"

reg query "HKCU\Environment" /v PATH >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul ^| findstr /i " PATH"') do set "CURRENT_PATH=%%B"
) else (
    set "CURRENT_PATH="
)

echo(!CURRENT_PATH!| findstr /i /c:"%PYTHON_DIR%" >nul
if errorlevel 1 (
    if defined CURRENT_PATH (
        setx PATH "%PYTHON_DIR%;%PYTHON_SCRIPTS%;!CURRENT_PATH!" >nul
    ) else (
        setx PATH "%PYTHON_DIR%;%PYTHON_SCRIPTS%" >nul
    )
    if errorlevel 1 (
        echo [ERROR] Failed to update the user PATH.
        pause
        exit /b 1
    )
    echo [OK] Python was added to the user PATH.
) else (
    echo [OK] Python is already present in the user PATH.
)

rem Step 3: Download the selected GitHub branch.
echo [3/5] Downloading the tickets_hunter 0807-version-plus branch...
if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"
if errorlevel 1 (
    echo [ERROR] Failed to create this directory:
    echo %EXTRACT_DIR%
    pause
    exit /b 1
)

curl.exe -L --fail "%ZIP_URL%" -o "%EXTRACT_DIR%\%ZIP_NAME%"
if errorlevel 1 (
    echo [ERROR] Failed to download the project ZIP file.
    pause
    exit /b 1
)
echo [OK] Project download completed.

rem Step 4: Extract the project.
echo [4/5] Extracting the project...
powershell.exe -NoProfile -Command "Expand-Archive -LiteralPath '%EXTRACT_DIR%\%ZIP_NAME%' -DestinationPath '%EXTRACT_DIR%' -Force"
if errorlevel 1 (
    echo [ERROR] Project extraction failed.
    pause
    exit /b 1
)

if not exist "%TARGET_PATH%\src\settings.py" (
    echo [ERROR] The launcher was not found:
    echo %TARGET_PATH%\src\settings.py
    pause
    exit /b 1
)
echo [OK] Project extraction completed.

rem Step 5: Install project dependencies.
echo [5/5] Installing project requirements...
cd /d "%TARGET_PATH%"
if not exist "requirement.txt" (
    echo [ERROR] requirement.txt was not found.
    pause
    exit /b 1
)

"%PYTHON_EXE%" -m pip install -r requirement.txt
if errorlevel 1 (
    echo [ERROR] Failed to install project requirements.
    pause
    exit /b 1
)
echo [OK] Project requirements are installed.

rem Start the program after setup.
echo.
echo ============================================================
echo  Setup completed. Starting tickets_hunter...
echo  Working directory: %TARGET_PATH%
echo ============================================================
"%PYTHON_EXE%" src\settings.py
set "PROGRAM_EXIT=%ERRORLEVEL%"

echo.
if not "%PROGRAM_EXIT%"=="0" (
    echo [ERROR] The program exited with code %PROGRAM_EXIT%.
) else (
    echo The program exited normally.
)
pause
endlocal & exit /b %PROGRAM_EXIT%
