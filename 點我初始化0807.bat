@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

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
echo  tickets_hunter 完整初始化 - Windows
echo ============================================================
echo.

:: --- Step 1: 直接安裝 Python 3.10.11 ---
echo [1/5] 正在下載 Python 3.10.11 安裝程式...
curl -L --fail "%PYTHON_URL%" -o "%TEMP%\%PYTHON_INSTALLER%"
if errorlevel 1 (
    echo [錯誤] Python 安裝程式下載失敗。
    pause
    exit /b 1
)

echo 正在安裝 Python 3.10.11...
"%TEMP%\%PYTHON_INSTALLER%" /quiet InstallAllUsers=0 TargetDir="%PYTHON_DIR%" PrependPath=1 Include_pip=1 Include_launcher=1
if errorlevel 1 (
    echo [錯誤] Python 安裝失敗。
    pause
    exit /b 1
)

if not exist "%PYTHON_EXE%" (
    echo [錯誤] 安裝完成後仍找不到：%PYTHON_EXE%
    pause
    exit /b 1
)
echo [OK] Python 3.10.11 安裝完成。

:: --- Step 2: 設定目前工作階段與使用者 PATH ---
echo [2/5] 正在設定 Python PATH...
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
        echo [錯誤] 無法寫入使用者 PATH。
        pause
        exit /b 1
    )
    echo [OK] Python 已永久加入使用者 PATH。
) else (
    echo [OK] Python 已存在於使用者 PATH。
)

:: --- Step 3: 下載指定 GitHub 分支 ---
echo [3/5] 正在下載 tickets_hunter 的 0807-version-plus 分支...
if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"
if errorlevel 1 (
    echo [錯誤] 無法建立目錄：%EXTRACT_DIR%
    pause
    exit /b 1
)

curl -L --fail "%ZIP_URL%" -o "%EXTRACT_DIR%\%ZIP_NAME%"
if errorlevel 1 (
    echo [錯誤] 專案 ZIP 下載失敗。
    pause
    exit /b 1
)
echo [OK] 專案下載完成。

:: --- Step 4: 解壓縮專案 ---
echo [4/5] 正在解壓縮專案...
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%EXTRACT_DIR%\%ZIP_NAME%' -DestinationPath '%EXTRACT_DIR%' -Force"
if errorlevel 1 (
    echo [錯誤] 解壓縮失敗。
    pause
    exit /b 1
)

if not exist "%TARGET_PATH%\src\settings.py" (
    echo [錯誤] 找不到啟動程式：%TARGET_PATH%\src\settings.py
    pause
    exit /b 1
)
echo [OK] 專案解壓縮完成。

:: --- Step 5: 安裝相依套件 ---
echo [5/5] 正在安裝 requirements...
cd /d "%TARGET_PATH%"
if not exist "requirement.txt" (
    echo [錯誤] 找不到 requirement.txt。
    pause
    exit /b 1
)

"%PYTHON_EXE%" -m pip install -r requirement.txt
if errorlevel 1 (
    echo [錯誤] requirements 安裝失敗。
    pause
    exit /b 1
)
echo [OK] Requirements 安裝完成。

:: --- 完成初始化後直接啟動 ---
echo.
echo ============================================================
echo  初始化完成，正在啟動 tickets_hunter
echo  工作目錄：%TARGET_PATH%
echo ============================================================
"%PYTHON_EXE%" src\settings.py
set "PROGRAM_EXIT=%ERRORLEVEL%"

echo.
if not "%PROGRAM_EXIT%"=="0" (
    echo [錯誤] 程式結束，錯誤碼：%PROGRAM_EXIT%
) else (
    echo 程式已正常結束。
)
pause
endlocal & exit /b %PROGRAM_EXIT%
