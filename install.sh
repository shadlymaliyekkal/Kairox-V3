#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#   KAIROX v3 — One-Shot Installer (Fixed)
#   Author : Shadly Maliyekkal
#   Usage  : bash install.sh
# ─────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[KAIROX]${NC} $*"; }
ok()    { echo -e "${GREEN}[  OK  ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[ WARN ]${NC} $*"; }
fail()  { echo -e "${RED}[ FAIL ]${NC} $*"; }
step()  { echo -e "\n${BOLD}${CYAN}━━━ $* ━━━${NC}"; }

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

OS="$(uname -s)"
ARCH="$(uname -m)"

# ── Step 1: Fix line endings & permissions ──────────────────
step "Fixing files"
for f in install.sh kairox; do
    if [ -f "$f" ]; then
        tr -d '\r' < "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
        chmod +x "$f"
        ok "Fixed + chmod +x: $f"
    fi
done

# ── Step 2: Python 3 check ──────────────────────────────────
step "Python 3"
if ! command -v python3 &>/dev/null; then
    fail "python3 not found!"
    if [ "$OS" = "Linux" ]; then
        info "Trying: sudo apt-get install -y python3 ..."
        sudo apt-get install -y python3 2>/dev/null && ok "python3 installed" || fail "Cannot install python3"
    fi
fi
ok "python3 -> $(python3 --version 2>&1)"

# ── Step 3: pip / rich ──────────────────────────────────────
step "Python rich library"

# Ensure pip is available
if ! command -v pip3 &>/dev/null && ! python3 -m pip --version &>/dev/null 2>&1; then
    info "pip not found, installing ..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y python3-pip 2>/dev/null || true
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y python3-pip 2>/dev/null || true
    elif command -v yum &>/dev/null; then
        sudo yum install -y python3-pip 2>/dev/null || true
    fi
fi

if python3 -c "import rich" &>/dev/null 2>&1; then
    ok "rich already installed"
else
    info "Installing rich ..."
    installed=0
    python3 -m pip install rich --break-system-packages -q 2>/dev/null && installed=1
    [ $installed -eq 0 ] && python3 -m pip install rich -q 2>/dev/null && installed=1
    [ $installed -eq 0 ] && pip3 install rich --break-system-packages -q 2>/dev/null && installed=1
    [ $installed -eq 0 ] && pip3 install rich -q 2>/dev/null && installed=1
    [ $installed -eq 0 ] && pip install rich -q 2>/dev/null && installed=1
    if [ $installed -eq 1 ]; then
        ok "rich installed"
    else
        fail "Could not install rich automatically"
        echo -e "  Try manually: ${CYAN}pip3 install rich${NC} or ${CYAN}pip3 install rich --break-system-packages${NC}"
    fi
fi

# ── Step 4: Install Go if missing ──────────────────────────
step "Go language runtime"

install_go() {
    info "Go not found — installing automatically ..."

    GO_VERSION="1.22.4"

    if [ "$OS" = "Linux" ]; then
        case "$ARCH" in
            x86_64)  GO_ARCH="amd64" ;;
            aarch64|arm64) GO_ARCH="arm64" ;;
            armv6l|armv7l) GO_ARCH="armv6l" ;;
            *)        GO_ARCH="amd64" ;;
        esac
        GO_TAR="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    elif [ "$OS" = "Darwin" ]; then
        case "$ARCH" in
            arm64) GO_ARCH="arm64" ;;
            *)     GO_ARCH="amd64" ;;
        esac
        GO_TAR="go${GO_VERSION}.darwin-${GO_ARCH}.tar.gz"
    else
        warn "Unsupported OS for auto Go install: $OS"
        return 1
    fi

    GO_URL="https://go.dev/dl/${GO_TAR}"
    TMPDIR_GO="/tmp/go_install_$$"
    mkdir -p "$TMPDIR_GO"

    info "Downloading Go ${GO_VERSION} (${GO_ARCH}) ..."
    if command -v wget &>/dev/null; then
        wget -q --show-progress "$GO_URL" -O "$TMPDIR_GO/$GO_TAR" 2>&1
    elif command -v curl &>/dev/null; then
        curl -L --progress-bar "$GO_URL" -o "$TMPDIR_GO/$GO_TAR"
    else
        fail "Neither wget nor curl found. Cannot download Go."
        rm -rf "$TMPDIR_GO"
        return 1
    fi

    if [ ! -f "$TMPDIR_GO/$GO_TAR" ] || [ ! -s "$TMPDIR_GO/$GO_TAR" ]; then
        fail "Go download failed or file empty."
        rm -rf "$TMPDIR_GO"
        return 1
    fi

    info "Extracting Go to /usr/local ..."
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$TMPDIR_GO/$GO_TAR" 2>/dev/null
    rm -rf "$TMPDIR_GO"

    # Add to PATH immediately for this session
    export PATH="$PATH:/usr/local/go/bin"

    if command -v go &>/dev/null; then
        ok "Go installed -> $(go version)"
        return 0
    else
        fail "Go install failed — please install manually from https://go.dev/dl/"
        return 1
    fi
}

if command -v go &>/dev/null; then
    ok "Go already installed -> $(go version)"
else
    install_go
fi

# ── Step 5: Set up GOPATH / PATH ───────────────────────────
step "Go PATH setup"

# Set GOPATH default if not set
if [ -z "$GOPATH" ]; then
    export GOPATH="$HOME/go"
fi
GOBIN="$GOPATH/bin"
mkdir -p "$GOBIN"

# Add /usr/local/go/bin and GOPATH/bin to PATH in shell configs
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$RC" ] || [ "$RC" = "$HOME/.bashrc" ]; then
        touch "$RC"
        if ! grep -q "/usr/local/go/bin" "$RC" 2>/dev/null; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> "$RC"
            ok "Added /usr/local/go/bin to $RC"
        fi
        if ! grep -q "GOPATH/bin\|go/bin" "$RC" 2>/dev/null; then
            echo 'export PATH=$PATH:$HOME/go/bin' >> "$RC"
            ok "Added ~/go/bin to $RC"
        fi
    fi
done

# Apply for current session
export PATH="$PATH:/usr/local/go/bin:$GOBIN"
ok "PATH updated for this session: /usr/local/go/bin and $GOBIN"

# ── Step 6: Install Go-based tools ─────────────────────────
step "Go recon tools"

install_go_tool() {
    local name="$1"
    local pkg="$2"
    local desc="$3"

    if command -v "$name" &>/dev/null; then
        ok "$name already installed -> $(command -v $name)"
        return 0
    fi

    if ! command -v go &>/dev/null; then
        warn "Go not available — skipping $name"
        return 1
    fi

    info "Installing $name ($desc) ..."
    # Show output so user can see progress
    if go install "$pkg@latest" 2>&1; then
        # refresh PATH lookup
        hash -r 2>/dev/null || true
        if command -v "$name" &>/dev/null; then
            ok "$name installed -> $(command -v $name)"
        else
            # binary might be in GOBIN but not in PATH yet
            if [ -f "$GOBIN/$name" ]; then
                ok "$name installed -> $GOBIN/$name"
            else
                warn "$name binary not found after install (check $GOBIN)"
            fi
        fi
    else
        warn "$name install failed — will use built-in fallback"
    fi
}

install_go_tool "subfinder"   "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"  "subdomain enum"
install_go_tool "httpx"       "github.com/projectdiscovery/httpx/cmd/httpx"             "live host probe"
install_go_tool "gau"         "github.com/lc/gau/v2/cmd/gau"                            "URL harvesting"
install_go_tool "waybackurls" "github.com/tomnomnom/waybackurls"                        "Wayback URLs"

# ── Step 7: amass ───────────────────────────────────────────
step "amass (OSINT)"
if command -v amass &>/dev/null; then
    ok "amass already installed"
elif command -v snap &>/dev/null; then
    info "Installing amass via snap ..."
    sudo snap install amass 2>/dev/null && ok "amass installed" || warn "amass snap failed — DNS fallback will be used"
elif command -v brew &>/dev/null; then
    info "Installing amass via brew ..."
    brew install amass 2>/dev/null && ok "amass installed" || warn "amass brew failed"
elif command -v go &>/dev/null; then
    info "Installing amass via go install ..."
    go install github.com/owasp-amass/amass/v4/...@latest 2>&1 && ok "amass installed" || warn "amass go install failed"
else
    warn "amass not installed — passive DNS fallback will be used"
fi

# ── Step 8: nmap ────────────────────────────────────────────
step "nmap (port scanner)"
if command -v nmap &>/dev/null; then
    ok "nmap already installed -> $(nmap --version | head -1)"
elif [ "$OS" = "Linux" ]; then
    info "Installing nmap ..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y nmap 2>/dev/null && ok "nmap installed" || warn "nmap apt failed"
    elif command -v yum &>/dev/null; then
        sudo yum install -y nmap 2>/dev/null && ok "nmap installed" || warn "nmap yum failed"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y nmap 2>/dev/null && ok "nmap installed" || warn "nmap dnf failed"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm nmap 2>/dev/null && ok "nmap installed" || warn "nmap pacman failed"
    else
        warn "Cannot auto-install nmap — socket fallback will be used"
    fi
elif [ "$OS" = "Darwin" ]; then
    brew install nmap 2>/dev/null && ok "nmap installed" || warn "nmap brew failed"
fi

# ── Step 9: Summary ─────────────────────────────────────────
echo ""
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
echo -e "${BOLD}${GREEN}  TOOL STATUS SUMMARY${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"

for t in go python3 subfinder httpx gau waybackurls amass nmap curl; do
    if command -v "$t" &>/dev/null || [ -f "$GOBIN/$t" ]; then
        echo -e "  ${GREEN}✔${NC}  $t"
    else
        echo -e "  ${YELLOW}✘${NC}  $t  (missing — fallback active)"
    fi
done

echo ""
echo -e "${GREEN}────────────────────────────────────────────────────────${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo ""
echo -e "  ${BOLD}Launch KAIROX:${NC}  ${CYAN}./kairox${NC}"
echo ""
echo -e "  ${YELLOW}NOTE:${NC} If Go tools aren't found after this, run:"
echo -e "        ${CYAN}source ~/.bashrc${NC}  then  ${CYAN}./kairox${NC}"
echo ""
