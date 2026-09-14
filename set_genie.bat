@echo off
setlocal

REM ============================================================
REM  set_genie.bat
REM
REM  1. Downloads a ZIP file from Google Drive, verifies that the
REM     download is a real ZIP archive, and extracts it onto the
REM     current user's Desktop.
REM  2. Installs Google Chrome if it is not already present.
REM
REM  Encoding    : ASCII only, no BOM
REM  Line ending : CRLF
REM  Requires    : Windows 10 1803+ or Windows Server 2019+
REM                curl.exe and PowerShell 5.1 are built in there.
REM                Administrator rights, but only for the Chrome step.
REM  Installs    : Google Chrome only. No Python, no pip, no PATH changes.
REM ============================================================


REM ============================================================
REM  CONFIGURATION - EDIT THE VALUES BELOW
REM ============================================================

REM  1. Google Drive file ID of the ZIP.
REM     A share link looks like this:
REM       https://drive.google.com/file/d/1AbCdEfGh_IjKlMnOpQr/view?usp=sharing
REM     The file ID is the part between  /d/  and  /view  :
REM       1AbCdEfGh_IjKlMnOpQr
REM     The file must be shared as "Anyone with the link" / Viewer.
set "GDRIVE_FILE_ID=1xy1sK0oQ33a40Le2I7kE1Bu3vBEcl-rZ"

REM  2. File name used when saving the ZIP onto the Desktop.
set "ZIP_NAME=genie.zip"

REM  3. Folder name created on the Desktop for the extracted files.
set "TARGET_FOLDER=genie"

REM  4. Install Google Chrome?  yes = install if missing, no = skip entirely.
set "INSTALL_CHROME=yes"

REM  5. Google Chrome installer. This is the small online installer, about
REM     12 MB, which pulls only the components this machine needs. It is
REM     the same browser as the full package, it just downloads less.
REM
REM     If this machine has restricted outbound access and the small
REM     installer fails, swap in the full 160 MB offline package instead:
REM       https://dl.google.com/chrome/install/standalonesetup64.exe
set "CHROME_INSTALLER_URL=https://dl.google.com/chrome/install/latest/chrome_installer.exe"

REM ============================================================
REM  END OF CONFIGURATION - do not edit below this line
REM ============================================================

title Genie ZIP Setup - Windows

echo.
echo ============================================================
echo  Genie ZIP Setup - Windows
echo ============================================================
echo.

REM ---------- preflight checks ----------

if not defined GDRIVE_FILE_ID goto :err_config
if "%GDRIVE_FILE_ID%"=="PUT_YOUR_FILE_ID_HERE" goto :err_config
if not defined ZIP_NAME goto :err_config
if not defined TARGET_FOLDER goto :err_config

where curl.exe >nul 2>&1
if errorlevel 1 goto :err_no_curl

where powershell.exe >nul 2>&1
if errorlevel 1 goto :err_no_powershell


REM ---------- [1/5] locate the real Desktop folder ----------

echo [1/5] Detecting Desktop directory...

set "DESKTOP_DIR="
for /f "usebackq delims=" %%D in (`powershell.exe -NoProfile -NonInteractive -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP_DIR=%%D"

if not defined DESKTOP_DIR set "DESKTOP_DIR=%USERPROFILE%\Desktop"
if not exist "%DESKTOP_DIR%\" set "DESKTOP_DIR=%USERPROFILE%\Desktop"
if not exist "%DESKTOP_DIR%\" goto :err_desktop

echo [OK] Desktop: %DESKTOP_DIR%
echo.

set "ZIP_PATH=%DESKTOP_DIR%\%ZIP_NAME%"
set "EXTRACT_DIR=%DESKTOP_DIR%\%TARGET_FOLDER%"
set "COOKIE_FILE=%TEMP%\set_genie_cookies.txt"
set "CHROME_INSTALLER_PATH=%TEMP%\set_genie_chrome_setup.exe"

set "URL_PRIMARY=https://drive.usercontent.google.com/download?id=%GDRIVE_FILE_ID%&export=download&confirm=t"
set "URL_FALLBACK=https://drive.google.com/uc?export=download&confirm=t&id=%GDRIVE_FILE_ID%"


REM ---------- [2/5] download the ZIP ----------

echo [2/5] Downloading ZIP from Google Drive...
echo       File ID  : %GDRIVE_FILE_ID%
echo       Saving to: %ZIP_PATH%
echo.

echo       Attempt 1 of 2 - primary endpoint
call :fetch "%URL_PRIMARY%"
if not errorlevel 1 goto :download_ok

echo.
echo       Attempt 1 did not return ZIP data.
echo       Attempt 2 of 2 - alternate endpoint
call :fetch "%URL_FALLBACK%"
if not errorlevel 1 goto :download_ok

goto :err_download

:download_ok
echo [OK] Download completed.
echo.


REM ---------- [3/5] validate the ZIP archive ----------

echo [3/5] Validating ZIP archive...

powershell.exe -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; try { Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[IO.Compression.ZipFile]::OpenRead($env:ZIP_PATH); $c=$z.Entries.Count; $z.Dispose(); if ($c -lt 1) { Write-Host '      Archive contains no entries.'; exit 1 }; Write-Host ('      Entries in archive: ' + $c); exit 0 } catch { Write-Host ('      ' + $_.Exception.Message); exit 1 }"
if errorlevel 1 goto :err_bad_zip

echo [OK] ZIP validation passed.
echo.


REM ---------- [4/5] extract onto the Desktop ----------

echo [4/5] Extracting ZIP to Desktop...
echo       Target: %EXTRACT_DIR%

powershell.exe -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; try { Expand-Archive -LiteralPath $env:ZIP_PATH -DestinationPath $env:EXTRACT_DIR -Force; exit 0 } catch { Write-Host ('      ' + $_.Exception.Message); exit 1 }"
if errorlevel 1 goto :err_extract

if not exist "%EXTRACT_DIR%\" goto :err_extract

powershell.exe -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; try { $n=(Get-ChildItem -LiteralPath $env:EXTRACT_DIR -Force | Measure-Object).Count; if ($n -lt 1) { exit 1 }; Write-Host ('      Top-level items extracted: ' + $n); exit 0 } catch { exit 1 }"
if errorlevel 1 goto :err_extract_empty

echo [OK] Extraction completed.
echo.


REM ---------- [5/5] install Google Chrome ----------

echo [5/5] Installing Google Chrome...

set "CHROME_STATUS=skipped by configuration"
if /i not "%INSTALL_CHROME%"=="yes" goto :chrome_skipped

call :find_chrome
if not errorlevel 1 goto :chrome_already_there

echo       Chrome was not found. Installing it now.

net session >nul 2>&1
if errorlevel 1 goto :err_chrome_admin

echo       Downloading the Chrome installer, about 12 MB.
echo.

if exist "%CHROME_INSTALLER_PATH%" del /f /q "%CHROME_INSTALLER_PATH%" >nul 2>&1
curl.exe -L --fail --connect-timeout 30 --retry 2 --retry-delay 3 -o "%CHROME_INSTALLER_PATH%" "%CHROME_INSTALLER_URL%"
if errorlevel 1 goto :err_chrome_download
if not exist "%CHROME_INSTALLER_PATH%" goto :err_chrome_download

echo.
echo       Running the silent installer. It now fetches the browser
echo       itself, so this step takes a few minutes with no output.
"%CHROME_INSTALLER_PATH%" /silent /install

REM  The online installer does not return a dependable exit code and can
REM  hand off to a background process, so wait for chrome.exe to appear
REM  rather than trusting the exit code. Gives up after about 5 minutes.
set "WAIT_TICKS=0"

:chrome_wait
call :find_chrome
if not errorlevel 1 goto :chrome_installed
set /a WAIT_TICKS+=1
if %WAIT_TICKS% GEQ 60 goto :err_chrome_install
ping -n 6 127.0.0.1 >nul 2>&1
goto :chrome_wait

:chrome_installed
del /f /q "%CHROME_INSTALLER_PATH%" >nul 2>&1
call :chrome_version
echo [OK] Google Chrome installed: %CHROME_VERSION%
set "CHROME_STATUS=installed, version %CHROME_VERSION%"
goto :chrome_done

:chrome_already_there
call :chrome_version
echo [OK] Google Chrome is already installed: %CHROME_VERSION%
set "CHROME_STATUS=already present, version %CHROME_VERSION%"
goto :chrome_done

:chrome_skipped
echo [--] INSTALL_CHROME is not set to yes. Skipping this step.
goto :chrome_done

:chrome_done
echo.


REM ---------- done ----------

echo ============================================================
echo  Setup completed successfully.
echo ============================================================
echo.
echo  ZIP file  : %ZIP_PATH%
echo  Extracted : %EXTRACT_DIR%
echo  Chrome    : %CHROME_STATUS%
echo.
echo  The ZIP file was intentionally kept so you can inspect it.
echo.

call :cleanup
endlocal
exit /b 0


REM ============================================================
REM  Subroutines
REM ============================================================

:fetch
REM  %1 = quoted download URL
REM  Returns 0 only if the downloaded file starts with a ZIP signature.
if exist "%ZIP_PATH%" del /f /q "%ZIP_PATH%" >nul 2>&1
if exist "%COOKIE_FILE%" del /f /q "%COOKIE_FILE%" >nul 2>&1
type nul > "%COOKIE_FILE%"

curl.exe -L --fail --connect-timeout 30 --retry 2 --retry-delay 3 -b "%COOKIE_FILE%" -c "%COOKIE_FILE%" -o "%ZIP_PATH%" %1
if errorlevel 1 exit /b 1

powershell.exe -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; try { $p=$env:ZIP_PATH; if (-not (Test-Path -LiteralPath $p)) { exit 1 }; $f=Get-Item -LiteralPath $p; if ($f.Length -lt 100) { exit 1 }; $s=[IO.File]::OpenRead($f.FullName); $b=New-Object byte[] 2; $null=$s.Read($b,0,2); $s.Close(); if ($b[0] -ne 80 -or $b[1] -ne 75) { exit 1 }; exit 0 } catch { exit 1 }"
if errorlevel 1 exit /b 1

exit /b 0


:find_chrome
REM  Sets CHROME_EXE and returns 0 if a Chrome executable was found.
set "CHROME_EXE="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if defined CHROME_EXE exit /b 0
if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if defined CHROME_EXE exit /b 0
if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
if defined CHROME_EXE exit /b 0
exit /b 1


:chrome_version
REM  Reads the product version of CHROME_EXE into CHROME_VERSION.
set "CHROME_VERSION=unknown"
for /f "usebackq delims=" %%V in (`powershell.exe -NoProfile -NonInteractive -Command "(Get-Item -LiteralPath $env:CHROME_EXE).VersionInfo.ProductVersion"`) do set "CHROME_VERSION=%%V"
exit /b 0


:cleanup
if exist "%COOKIE_FILE%" del /f /q "%COOKIE_FILE%" >nul 2>&1
exit /b 0


REM ============================================================
REM  Error handlers
REM ============================================================

:err_config
echo [ERROR] The configuration block has not been filled in.
echo         Open set_genie.bat and set GDRIVE_FILE_ID to your
echo         Google Drive file ID, then run the script again.
goto :fail

:err_no_curl
echo [ERROR] curl.exe was not found on this system.
echo         curl.exe ships with Windows 10 1803 and Windows Server 2019
echo         and later. On older systems it must be installed manually.
goto :fail

:err_no_powershell
echo [ERROR] powershell.exe was not found on this system.
goto :fail

:err_desktop
echo [ERROR] Could not locate the Desktop directory for this user.
echo         Tried the shell folder API and the USERPROFILE fallback.
goto :fail

:err_download
echo.
echo [ERROR] Failed to download a valid ZIP file from Google Drive.
echo         Both endpoints were tried and neither returned ZIP data.
echo.
echo         Common causes:
echo          - The file is not shared as "Anyone with the link".
echo          - GDRIVE_FILE_ID is wrong or incomplete.
echo          - The daily download quota for this file was exceeded.
echo          - This machine has no internet access.
echo.
echo         To see what the server actually returned, run this command
echo         and read the first few lines of the output:
echo           curl.exe -L "%URL_PRIMARY%" ^| more
goto :fail

:err_bad_zip
echo.
echo [ERROR] The downloaded file is not a readable ZIP archive.
echo         File: %ZIP_PATH%
echo         It was left in place so you can inspect it.
goto :fail

:err_extract
echo.
echo [ERROR] Failed to extract the ZIP archive.
echo         Source: %ZIP_PATH%
echo         Target: %EXTRACT_DIR%
goto :fail

:err_extract_empty
echo.
echo [ERROR] Extraction produced an empty folder.
echo         Target: %EXTRACT_DIR%
goto :fail

:err_chrome_admin
echo.
echo [ERROR] Installing Google Chrome requires Administrator rights.
echo         Close this window, right click on Command Prompt, choose
echo         "Run as administrator", and run the same command again.
echo.
echo         The ZIP was already downloaded and extracted successfully:
echo           %EXTRACT_DIR%
echo.
echo         To skip Chrome entirely, set INSTALL_CHROME=no near the top
echo         of this script.
goto :fail

:err_chrome_download
echo.
echo [ERROR] Failed to download the Google Chrome installer.
echo         URL: %CHROME_INSTALLER_URL%
echo.
echo         The ZIP was already downloaded and extracted successfully:
echo           %EXTRACT_DIR%
goto :fail

:err_chrome_install
echo.
echo [ERROR] Chrome did not finish installing within the time limit, and
echo         chrome.exe was not found in any of the expected locations.
echo         The installer was kept so you can run it by hand:
echo           %CHROME_INSTALLER_PATH%
echo.
echo         If this machine has restricted outbound access, edit
echo         CHROME_INSTALLER_URL near the top of this script and use the
echo         full offline package listed in the comment above it.
echo.
echo         The ZIP was already downloaded and extracted successfully:
echo           %EXTRACT_DIR%
goto :fail

:fail
echo.
echo ============================================================
echo  Setup FAILED.
echo ============================================================
echo.
call :cleanup
endlocal
exit /b 1
