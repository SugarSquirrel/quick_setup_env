@echo off
setlocal EnableDelayedExpansion

set CHROME_URL=https://dl.google.com/chrome/install/latest/chrome_installer.exe
set CHROME_INSTALLER=%TEMP%\chrome_installer.exe

echo ============================================================
echo  Google Chrome Silent Installer - Windows
echo ============================================================

:: --- Check if Chrome is already installed ---
echo [1/2] Checking if Chrome is already installed...

reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo [OK] Chrome is already installed. Exiting.
    pause
    exit /b 0
)

reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo [OK] Chrome is already installed. Exiting.
    pause
    exit /b 0
)

echo Chrome not found. Downloading...

:: --- Download Chrome installer ---
echo [2/2] Downloading and installing Chrome silently...
curl -L "%CHROME_URL%" -o "%CHROME_INSTALLER%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to download Chrome installer.
    pause
    exit /b 1
)

:: /silent /install = fully silent, no prompts, no window
"%CHROME_INSTALLER%" /silent /install
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Chrome installation failed.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  [OK] Google Chrome installed successfully.
echo ============================================================
pause
endlocal
