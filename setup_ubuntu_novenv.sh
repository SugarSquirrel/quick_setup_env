#!/usr/bin/env bash
# ============================================================
# setup_ubuntu_novenv.sh
# Usage: bash setup_ubuntu_novenv.sh
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------- Variables ----------
PYTHON_VERSION="3.10"
VENV_DIR="$HOME/ticketH_venv"
ZIP_URL="https://github.com/bouob/tickets_hunter/archive/refs/tags/v2026.04.23.zip"
ZIP_NAME="tickets_hunter_v2026.04.23.zip"
EXTRACT_DIR="$HOME/tickets_hunter_setup"
TARGET_PATH="${EXTRACT_DIR}/tickets_hunter-2026.04.23"

echo "============================================================"
echo "  tickets_hunter setup - Ubuntu (no conda)"
echo "============================================================"

# ============================================================
# Step 1: Install Python 3.10
# ============================================================
log_info "[1/5] Checking Python 3.10..."

if command -v python3.10 &>/dev/null; then
    log_ok "Python 3.10 already installed: $(python3.10 --version)"
else
    log_warn "Python 3.10 not found. Installing..."
    sudo apt-get update -y
    sudo apt-get install -y python3.10 python3.10-venv python3.10-distutils || log_error "Failed to install Python 3.10."
    log_ok "Python 3.10 installed."
fi

# ============================================================
# Step 2: Create venv (replaces conda env)
# ============================================================
log_info "[2/5] Setting up virtual environment at ${VENV_DIR}..."

if [ -d "$VENV_DIR" ]; then
    log_ok "venv already exists, reusing."
else
    python3.10 -m venv "$VENV_DIR" || log_error "Failed to create venv."
    log_ok "venv created: ${VENV_DIR}"
fi

# Activate venv
source "${VENV_DIR}/bin/activate" || log_error "Failed to activate venv."
log_ok "venv activated: $(python --version)"

# ============================================================
# Step 3: Download ZIP
# ============================================================
log_info "[3/5] Downloading tickets_hunter..."
mkdir -p "$EXTRACT_DIR"

command -v unzip &>/dev/null || { sudo apt-get install -y unzip || log_error "Failed to install unzip."; }

if command -v curl &>/dev/null; then
    curl -fL "$ZIP_URL" -o "${EXTRACT_DIR}/${ZIP_NAME}" --progress-bar || log_error "Download failed."
elif command -v wget &>/dev/null; then
    wget -q --show-progress "$ZIP_URL" -O "${EXTRACT_DIR}/${ZIP_NAME}" || log_error "Download failed."
else
    log_error "Neither curl nor wget found. Run: sudo apt install curl"
fi
log_ok "Downloaded: ${EXTRACT_DIR}/${ZIP_NAME}"

# ============================================================
# Step 4: Extract ZIP
# ============================================================
log_info "[4/5] Extracting..."
unzip -q -o "${EXTRACT_DIR}/${ZIP_NAME}" -d "$EXTRACT_DIR" || log_error "Extraction failed."

if [ ! -d "$TARGET_PATH" ]; then
    FOUND=$(find "$EXTRACT_DIR" -maxdepth 1 -type d -name "tickets_hunter*" | head -1)
    [ -n "$FOUND" ] && TARGET_PATH="$FOUND" || log_error "Cannot find extracted folder in ${EXTRACT_DIR}"
    log_warn "Adjusted path: ${TARGET_PATH}"
fi
log_ok "Extracted."

# ============================================================
# Step 5: pip install requirements
# ============================================================
log_info "[5/5] Installing requirements..."
cd "$TARGET_PATH" || log_error "Cannot cd to ${TARGET_PATH}"
log_ok "Now in: ${TARGET_PATH}"

[ -f "requirement.txt" ] || log_error "requirement.txt not found in ${TARGET_PATH}"

pip install -r requirement.txt || log_error "pip install failed."
log_ok "Requirements installed."

echo ""
echo "============================================================"
log_ok "Setup complete!"
echo "  venv       : ${VENV_DIR}"
echo "  Working dir: ${TARGET_PATH}"
echo ""
echo "  To activate venv next time:"
echo "    source ${VENV_DIR}/bin/activate"
echo "  Next step  : python src/settings.py"
echo "============================================================"
