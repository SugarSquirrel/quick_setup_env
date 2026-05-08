#!/usr/bin/env bash
# ============================================================
# setup_ubuntu.sh
# Usage: bash setup_ubuntu.sh
# ============================================================

# ---------- Color output ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------- Variables ----------
PYTHON_VERSION="3.10.11"
CONDA_ENV_NAME="ticketH"
ZIP_URL="https://github.com/bouob/tickets_hunter/archive/refs/tags/v2026.04.23.zip"
ZIP_NAME="tickets_hunter_v2026.04.23.zip"
EXTRACT_DIR="$HOME/tickets_hunter_setup"
TARGET_PATH="${EXTRACT_DIR}/tickets_hunter-2026.04.23"

echo "============================================================"
echo "  tickets_hunter setup - Ubuntu"
echo "============================================================"

# ============================================================
# Pre-step: Load conda and activate env
# ============================================================
log_info "Loading conda..."

# Source conda from any common install location
CONDA_INIT_SCRIPT=""
for candidate in \
    "$HOME/anaconda3/etc/profile.d/conda.sh" \
    "$HOME/miniconda3/etc/profile.d/conda.sh" \
    "$HOME/miniforge3/etc/profile.d/conda.sh" \
    "/opt/conda/etc/profile.d/conda.sh" \
    "/usr/local/anaconda3/etc/profile.d/conda.sh"; do
    if [ -f "$candidate" ]; then
        CONDA_INIT_SCRIPT="$candidate"
        break
    fi
done

# Fallback: try conda in PATH directly
if [ -z "$CONDA_INIT_SCRIPT" ]; then
    CONDA_BASE=$(conda info --base 2>/dev/null)
    if [ -n "$CONDA_BASE" ] && [ -f "${CONDA_BASE}/etc/profile.d/conda.sh" ]; then
        CONDA_INIT_SCRIPT="${CONDA_BASE}/etc/profile.d/conda.sh"
    fi
fi

[ -z "$CONDA_INIT_SCRIPT" ] && log_error "Cannot find conda.sh. Make sure conda is installed."

source "$CONDA_INIT_SCRIPT"
log_ok "conda loaded: $CONDA_INIT_SCRIPT"

# Check / create env
log_info "Checking conda env '${CONDA_ENV_NAME}'..."
if conda env list | grep -qE "^${CONDA_ENV_NAME}[[:space:]]"; then
    log_ok "Env '${CONDA_ENV_NAME}' already exists."
else
    log_warn "Creating env '${CONDA_ENV_NAME}'..."
    conda create -n "$CONDA_ENV_NAME" --no-default-packages -y || log_error "Failed to create conda env."
    log_ok "Env '${CONDA_ENV_NAME}' created."
fi

conda activate "$CONDA_ENV_NAME"
log_ok "Activated: $(conda info --envs | grep '*' | awk '{print $1}')"

# ============================================================
# Step 1: Install Python 3.10.11
# ============================================================
log_info "[1/4] Checking Python ${PYTHON_VERSION}..."
CURRENT_PY=$(python --version 2>&1 | awk '{print $2}')
if [[ "$CURRENT_PY" == 3.10* ]]; then
    log_ok "Python ${CURRENT_PY} already installed."
else
    log_info "Installing Python ${PYTHON_VERSION}..."
    conda install -n "$CONDA_ENV_NAME" python="${PYTHON_VERSION}" -y || log_error "Python installation failed."
    log_ok "Python ${PYTHON_VERSION} installed."
fi

# ============================================================
# Step 2: Download ZIP
# ============================================================
log_info "[2/4] Downloading tickets_hunter..."
mkdir -p "$EXTRACT_DIR"

# Ensure unzip is available
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
# Step 3: Extract ZIP
# ============================================================
log_info "[3/4] Extracting..."
unzip -q -o "${EXTRACT_DIR}/${ZIP_NAME}" -d "$EXTRACT_DIR" || log_error "Extraction failed."

# Adjust path if folder name differs
if [ ! -d "$TARGET_PATH" ]; then
    FOUND=$(find "$EXTRACT_DIR" -maxdepth 1 -type d -name "tickets_hunter*" | head -1)
    [ -n "$FOUND" ] && TARGET_PATH="$FOUND" || log_error "Cannot find extracted folder in ${EXTRACT_DIR}"
    log_warn "Adjusted path: ${TARGET_PATH}"
fi
log_ok "Extracted."

# ============================================================
# Step 4: cd and pip install requirements
# ============================================================
log_info "[4/4] Installing requirements..."
cd "$TARGET_PATH" || log_error "Cannot cd to ${TARGET_PATH}"
log_ok "Now in: ${TARGET_PATH}"

[ -f "requirement.txt" ] || log_error "requirement.txt not found in ${TARGET_PATH}"

pip install -r requirement.txt || log_error "pip install failed."
log_ok "Requirements installed."

echo ""
echo "============================================================"
log_ok "Setup complete!"
echo "  Conda env : ${CONDA_ENV_NAME}"
echo "  Working dir: ${TARGET_PATH}"
echo "  Next step  : python src/settings.py"
echo "============================================================"
