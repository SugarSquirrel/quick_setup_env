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

ZIP_URL="https://github.com/SugarSquirrel/tickets_hunter/archive/refs/heads/main.zip"
ZIP_NAME="tickets_hunter_main.zip"
EXTRACT_DIR="$HOME/tickets_hunter_setup"
TARGET_PATH="${EXTRACT_DIR}/tickets_hunter-main"
SCRIPT_FILE="${TARGET_PATH}/src/nodriver_tixcraft.py"

echo "============================================================"
echo "  tickets_hunter setup - Ubuntu"
echo "============================================================"

# ============================================================
# Step 1: Check python3 and pip
# ============================================================
log_info "[1/4] Checking python3..."
command -v python3 &>/dev/null || log_error "python3 not found. Please install it manually."
log_ok "$(python3 --version) found."

# Ensure pip is available
if ! python3 -m pip --version &>/dev/null; then
    log_warn "pip not found. Installing..."
    sudo apt-get install -y python3-pip || log_error "Failed to install pip."
fi
log_ok "pip ready."

# ============================================================
# Step 2: Download ZIP
# ============================================================
log_info "[2/4] Downloading tickets_hunter (main)..."
mkdir -p "$EXTRACT_DIR"

command -v unzip &>/dev/null || { sudo apt-get install -y unzip || log_error "Failed to install unzip."; }
command -v curl  &>/dev/null || { sudo apt-get install -y curl  || log_error "Failed to install curl."; }

curl -fL "$ZIP_URL" -o "${EXTRACT_DIR}/${ZIP_NAME}" --progress-bar || log_error "Download failed."
log_ok "Downloaded."

# ============================================================
# Step 3: Extract ZIP
# ============================================================
log_info "[3/4] Extracting..."
unzip -q -o "${EXTRACT_DIR}/${ZIP_NAME}" -d "$EXTRACT_DIR" || log_error "Extraction failed."

if [ ! -d "$TARGET_PATH" ]; then
    FOUND=$(find "$EXTRACT_DIR" -maxdepth 1 -type d -name "tickets_hunter*" | head -1)
    [ -n "$FOUND" ] && TARGET_PATH="$FOUND" || log_error "Cannot find extracted folder in ${EXTRACT_DIR}"
    SCRIPT_FILE="${TARGET_PATH}/src/nodriver_tixcraft.py"
    log_warn "Adjusted path: ${TARGET_PATH}"
fi
log_ok "Extracted to: ${TARGET_PATH}"

# ============================================================
# Step 4: pip install requirements
# ============================================================
log_info "[4/4] Installing requirements..."
cd "$TARGET_PATH" || log_error "Cannot cd to ${TARGET_PATH}"
[ -f "requirement.txt" ] || log_error "requirement.txt not found in ${TARGET_PATH}"

python3 -m pip install -r requirement.txt --break-system-packages || log_error "pip install failed."
log_ok "Requirements installed."

# ============================================================
# Patch: fix Chrome sandbox issue for root user
# ============================================================
log_info "[Patch] Checking root Chrome sandbox patch..."

if [ "$(whoami)" = "root" ] || [ "$EUID" -eq 0 ] 2>/dev/null; then
    if [ -f "$SCRIPT_FILE" ]; then
        if grep -q "^        driver = await uc.start(conf)$" "$SCRIPT_FILE"; then
            sed -i 's|^        driver = await uc.start(conf)$|        #driver = await uc.start(conf)|' "$SCRIPT_FILE"
            sed -i 's|^        #driver = await uc.start(conf, sandbox=sandbox|        driver = await uc.start(conf, sandbox=sandbox|' "$SCRIPT_FILE"
            log_ok "Patch applied: sandbox=False enabled for root."
        else
            log_ok "Already patched, skipping."
        fi
    else
        log_warn "nodriver_tixcraft.py not found, skipping patch."
    fi
else
    log_info "Not running as root, sandbox patch not needed."
fi

echo ""
echo "============================================================"
log_ok "Setup complete!"
echo "  Working dir: ${TARGET_PATH}"
echo "  Next step  :"
echo "    cd ${TARGET_PATH}"
echo "    python3 src/settings.py"
echo "============================================================"
