# tickets_hunter Setup Guide

## 檔案總覽

| 檔案 | 適用平台 | 環境管理 |
|------|----------|----------|
| `setup_windows.bat` | Windows | 系統 Python（無虛擬環境） |
| `setup_ubuntu_conda.sh` | Ubuntu | Conda（ticketH 環境） |
| `setup_ubuntu_novenv.sh` | Ubuntu | 系統 Python（無虛擬環境） |

---

## Windows — `setup_windows.bat`

### 事前準備（只需做一次）
開啟 PowerShell，執行以下指令解除腳本執行限制：
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

### 執行方式
在 PowerShell 貼上：
```powershell
irm "https://raw.githubusercontent.com/SugarSquirrel/quick_setup_env/main/setup_windows.bat" -OutFile "$env:TEMP\setup.bat"; & "$env:TEMP\setup.bat"
```

### 完成後手動執行
```cmd
cd %USERPROFILE%\tickets_hunter_setup\tickets_hunter-2026.04.23
python src\settings.py
```

---

## Ubuntu — `setup_ubuntu_conda.sh`（Conda 版）

### 事前準備
需已安裝 Anaconda 或 Miniconda。

### 執行方式
```bash
curl -L "https://raw.githubusercontent.com/SugarSquirrel/quick_setup_env/main/setup_ubuntu_conda.sh" -o setup_ubuntu_conda.sh && bash setup_ubuntu_conda.sh
```

### 完成後手動執行
```bash
conda activate ticketH
cd ~/tickets_hunter_setup/tickets_hunter-2026.04.23
python src/settings.py
```

---

## Ubuntu — `setup_ubuntu_novenv.sh`（無虛擬環境版）

### 事前準備
無需任何準備，腳本會自動安裝所需套件。

### 執行方式
```bash
curl -L "https://raw.githubusercontent.com/SugarSquirrel/quick_setup_env/main/setup_ubuntu_novenv.sh" -o setup_ubuntu_novenv.sh && bash setup_ubuntu_novenv.sh
```

### 完成後手動執行
```bash
cd ~/tickets_hunter_setup/tickets_hunter-2026.04.23
python3.10 src/settings.py
```

---

## 腳本做了什麼

1. 安裝 Python 3.10（若尚未安裝）
2. 下載 tickets_hunter v2026.04.23
3. 解壓縮至 `~/tickets_hunter_setup`（Linux）或 `%USERPROFILE%\tickets_hunter_setup`（Windows）
4. 執行 `pip install -r requirement.txt`
