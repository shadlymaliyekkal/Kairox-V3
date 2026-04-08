#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#   KAIROX v3 — One-Shot Installer
#   Author : Shadly Maliyekkal
#   Usage  : bash install.sh
# ─────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${CYAN}[KAIROX]${NC} $*"; }
ok()    { echo -e "${GREEN}[  OK  ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[ WARN ]${NC} $*"; }
fail()  { echo -e "${RED}[ FAIL ]${NC} $*"; }

echo ""
echo -e "${CYAN} ██╗  ██╗ █████╗ ██╗██████╗  ██████╗ ██╗  ██╗${NC}"
echo -e "${CYAN} ██║ ██╔╝██╔══██╗██║██╔══██╗██╔═══██╗╚██╗██╔╝${NC}"
echo -e "${CYAN} █████╔╝ ███████║██║██████╔╝██║   ██║ ╚███╔╝ ${NC}"
echo -e "${CYAN} ██╔═██╗ ██╔══██║██║██╔══██╗██║   ██║ ██╔██╗ ${NC}"
echo -e "${CYAN} ██║  ██╗██║  ██║██║██║  ██║╚██████╔╝██╔╝ ██╗${NC}"
echo -e "${CYAN} ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝${NC}"
echo ""
echo -e "${GREEN}  KAIROX v3 — One-Shot Installer   by Shadly Maliyekkal${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
echo ""

# ── Step 1: Auto-fix Windows line endings on both files ─────
info "Fixing line endings (CRLF → LF) ..."
for f in install.sh kairox; do
    if [ -f "$f" ]; then
        tr -d '\r' < "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
        ok "Fixed: $f"
    fi
done

# ── Step 2: Set executable permissions ──────────────────────
info "Setting permissions ..."
chmod +x kairox install.sh
ok "chmod +x kairox"

# ── Step 3: Check Python 3 ──────────────────────────────────
if ! command -v python3 &>/dev/null; then
    fail "python3 not found! Install it: sudo apt install python3"
    exit 1
fi
ok "python3 found -> $(python3 --version)"

# ── Step 4: Install rich (tries multiple methods) ───────────
info "Installing Python library: rich ..."
if python3 -c "import rich" &>/dev/null; then
    ok "rich already installed"
elif pip3 install rich --break-system-packages -q 2>/dev/null; then
    ok "rich installed (pip3 --break-system-packages)"
elif pip3 install rich -q 2>/dev/null; then
    ok "rich installed (pip3)"
elif pip install rich -q 2>/dev/null; then
    ok "rich installed (pip)"
elif python3 -m pip install rich -q 2>/dev/null; then
    ok "rich installed (python3 -m pip)"
else
    fail "Could not auto-install rich. Try: pip3 install rich"
fi

# ── Step 5: Go tools ────────────────────────────────────────
OS="$(uname -s)"

install_go_tool() {
    local name="$1"
    local pkg="$2"
    if command -v "$name" &>/dev/null; then
        ok "$name already installed"
    elif command -v go &>/dev/null; then
        info "Installing $name ..."
        go install "$pkg@latest" 2>/dev/null && ok "$name installed" || warn "$name install failed — skipping"
    else
        warn "Go not found -> $name skipped (built-in fallback will be used)"
    fi
}

install_go_tool "subfinder"   "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
install_go_tool "httpx"       "github.com/projectdiscovery/httpx/cmd/httpx"
install_go_tool "gau"         "github.com/lc/gau/v2/cmd/gau"
install_go_tool "waybackurls" "github.com/tomnomnom/waybackurls"

# ── Step 6: amass ───────────────────────────────────────────
if command -v amass &>/dev/null; then
    ok "amass already installed"
elif command -v snap &>/dev/null; then
    info "Installing amass via snap ..."
    sudo snap install amass 2>/dev/null && ok "amass installed" || warn "amass snap failed — skipping"
elif command -v brew &>/dev/null; then
    brew install amass 2>/dev/null && ok "amass installed" || warn "amass brew failed — skipping"
else
    warn "amass not installed -> passive DNS fallback will be used"
fi

# ── Step 7: nmap ────────────────────────────────────────────
if command -v nmap &>/dev/null; then
    ok "nmap already installed"
elif [ "$OS" = "Linux" ]; then
    info "Installing nmap ..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y -qq nmap 2>/dev/null && ok "nmap installed" || warn "nmap apt failed"
    elif command -v yum &>/dev/null; then
        sudo yum install -y -q nmap 2>/dev/null && ok "nmap installed" || warn "nmap yum failed"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y -q nmap 2>/dev/null && ok "nmap installed" || warn "nmap dnf failed"
    else
        warn "Cannot auto-install nmap — socket fallback will be used"
    fi
elif [ "$OS" = "Darwin" ]; then
    brew install nmap 2>/dev/null && ok "nmap installed" || warn "nmap brew failed"
fi

# ── Step 8: Add Go bin to PATH if needed ────────────────────
if command -v go &>/dev/null; then
    GOPATH_BIN="$(go env GOPATH)/bin"
    if [[ ":$PATH:" != *":$GOPATH_BIN:"* ]]; then
        info "Adding Go bin to PATH in ~/.bashrc and ~/.zshrc ..."
        echo "export PATH=\$PATH:$GOPATH_BIN" >> ~/.bashrc 2>/dev/null || true
        echo "export PATH=\$PATH:$GOPATH_BIN" >> ~/.zshrc  2>/dev/null || true
        export PATH="$PATH:$GOPATH_BIN"
        ok "PATH updated -> $GOPATH_BIN"
    fi
fi

# ── Done ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}────────────────────────────────────────────────────────${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo ""
echo -e "  Launch KAIROX now:  ${CYAN}./kairox${NC}"
echo ""
