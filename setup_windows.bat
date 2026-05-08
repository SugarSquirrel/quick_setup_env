@echo off
:: ============================================================
:: setup_windows.bat
:: 自動化安裝 Python 3.10.20 並部署 tickets_hunter
:: 適用平台：Windows
:: ============================================================

setlocal EnableDelayedExpansion

:: ---------- 設定變數 ----------
set PYTHON_VERSION=3.10.20
set PYTHON_INSTALLER=python-3.10.20-amd64.exe
set PYTHON_URL=https://www.python.org/ftp/python/3.10.20/python-3.10.20-amd64.exe
set ZIP_URL=https://github.com/bouob/tickets_hunter/archive/refs/tags/v2026.04.23.zip
set ZIP_NAME=tickets_hunter_v2026.04.23.zip
set EXTRACT_DIR=%USERPROFILE%\tickets_hunter_setup
set TARGET_SUBDIR=tickets_hunter-2026.04.23

echo ============================================================
echo  tickets_hunter 自動安裝腳本 - Windows
echo ============================================================
echo.

:: ---------- 步驟 1：檢查 Python 版本 ----------
echo [步驟 1/5] 檢查 Python 3.10.20 是否已安裝...

python --version 2>nul | findstr "3.10.20" >nul
if %ERRORLEVEL% == 0 (
    echo   [OK] Python 3.10.20 已安裝，跳過安裝步驟。
    goto DOWNLOAD_ZIP
)

echo   未偵測到 Python 3.10.20，開始下載安裝程式...
echo   下載來源：%PYTHON_URL%

:: 使用 PowerShell 下載 Python 安裝程式
powershell -Command "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%TEMP%\%PYTHON_INSTALLER%'" 
if %ERRORLEVEL% neq 0 (
    echo   [錯誤] Python 安裝程式下載失敗！請檢查網路連線。
    pause
    exit /b 1
)

echo   下載完成，開始靜默安裝（安裝至使用者目錄）...
:: /quiet        = 靜默安裝
:: InstallAllUsers=0  = 僅安裝給目前使用者（不需管理員）
:: PrependPath=1 = 自動加入 PATH
"%TEMP%\%PYTHON_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1
if %ERRORLEVEL% neq 0 (
    echo   [錯誤] Python 安裝失敗！
    pause
    exit /b 1
)
echo   [OK] Python 3.10.20 安裝完成。

:: 重新整理 PATH（讓新安裝的 python 可被偵測到）
call refreshenv 2>nul || (
    :: 若沒有 refreshenv，手動加入常見路徑
    set "PATH=%LOCALAPPDATA%\Programs\Python\Python310;%LOCALAPPDATA%\Programs\Python\Python310\Scripts;%PATH%"
)

:DOWNLOAD_ZIP
:: ---------- 步驟 2：建立工作目錄並下載 ZIP ----------
echo.
echo [步驟 2/5] 下載 tickets_hunter 壓縮檔...

if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"

powershell -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%EXTRACT_DIR%\%ZIP_NAME%'"
if %ERRORLEVEL% neq 0 (
    echo   [錯誤] ZIP 下載失敗！請檢查網路連線。
    pause
    exit /b 1
)
echo   [OK] 下載完成：%EXTRACT_DIR%\%ZIP_NAME%

:: ---------- 步驟 3：解壓縮 ----------
echo.
echo [步驟 3/5] 解壓縮檔案至 %EXTRACT_DIR%...

powershell -Command "Expand-Archive -Path '%EXTRACT_DIR%\%ZIP_NAME%' -DestinationPath '%EXTRACT_DIR%' -Force"
if %ERRORLEVEL% neq 0 (
    echo   [錯誤] 解壓縮失敗！
    pause
    exit /b 1
)
echo   [OK] 解壓縮完成。

:: ---------- 步驟 4：切換到目標目錄 ----------
echo.
echo [步驟 4/5] 切換工作目錄...

set TARGET_PATH=%EXTRACT_DIR%\%TARGET_SUBDIR%

if not exist "%TARGET_PATH%" (
    echo   [錯誤] 找不到目標路徑：%TARGET_PATH%
    echo   請確認解壓縮後的資料夾結構是否正確。
    pause
    exit /b 1
)

cd /d "%TARGET_PATH%"
echo   [OK] 已切換至：%TARGET_PATH%

:: ---------- 步驟 5：執行 settings.py ----------
echo.
echo [步驟 5/5] 執行 python src\settings.py...
echo ============================================================
echo.

python src\settings.py
if %ERRORLEVEL% neq 0 (
    echo.
    echo   [警告] settings.py 執行過程中出現錯誤（exit code: %ERRORLEVEL%）
)

echo.
echo ============================================================
echo  所有步驟完成！工作目錄：%TARGET_PATH%
echo ============================================================
pause
endlocal
