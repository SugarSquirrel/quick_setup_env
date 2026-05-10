# tickets_hunter Setup Guide

## 檔案總覽

| 檔案 | 適用平台 | 用途 |
|------|----------|------|
| `setup_windows.bat` | Windows | 安裝 Python 3.10 + tickets_hunter + 套件 |
| `setup_chrome.bat` | Windows | 靜默安裝 Google Chrome |
| `setup_ubuntu_conda.sh` | Ubuntu | 安裝 tickets_hunter（Conda ticketH 環境） |
| `setup_ubuntu_novenv.sh` | Ubuntu | 安裝 tickets_hunter（系統 Python，無虛擬環境） |

---

## Windows — `setup_windows.bat`

### 事前準備
無需任何準備，CMD 內建 `curl`，直接可用。

### 執行方式
開啟 CMD 貼上：
```cmd
curl -L "https://raw.githubusercontent.com/SugarSquirrel/quick_setup_env/main/setup_windows.bat" -o "%TEMP%\setup.bat" && "%TEMP%\setup.bat"
```

### 完成後手動執行
```cmd
cd %USERPROFILE%\tickets_hunter_setup\tickets_hunter-main
python src\settings.py
```

---

## Windows — `setup_chrome.bat`

### 事前準備
無需任何準備。

### 執行方式
開啟 CMD 貼上：
```cmd
curl -L "https://raw.githubusercontent.com/SugarSquirrel/quick_setup_env/main/setup_chrome.bat" -o "%TEMP%\setup_chrome.bat" && "%TEMP%\setup_chrome.bat"
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
cd ~/tickets_hunter_setup/tickets_hunter-main
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
cd ~/tickets_hunter_setup/tickets_hunter-main
python3.10 src/settings.py
```

---

## 腳本做了什麼

### setup_windows.bat
1. 檢查並安裝 Python 3.10.11（若尚未安裝）
2. 將 Python 永久寫入使用者 PATH 環境變數
3. 下載 tickets_hunter（main branch）
4. 解壓縮至 `%USERPROFILE%\tickets_hunter_setup\tickets_hunter-main`
5. 執行 `pip install -r requirement.txt`

### setup_chrome.bat
1. 檢查 Chrome 是否已安裝
2. 從 Google 官方下載最新版安裝程式
3. 靜默安裝，全程無需手動操作

### setup_ubuntu_conda.sh / setup_ubuntu_novenv.sh
1. 安裝 Python 3.10（若尚未安裝）
2. 下載 tickets_hunter（main branch）
3. 解壓縮至 `~/tickets_hunter_setup/tickets_hunter-main`
4. 執行 `pip install -r requirement.txt`
