#!/bin/bash
# ============================================================
#  Volatility 2 & 3 — Instalación aislada
# ============================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

log()     { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }
section() { echo -e "\n${BOLD}${BLUE}══ $1 ══${NC}"; }

[ "$EUID" -ne 0 ] && error "Ejecuta como root: sudo bash volatility-install.sh"

ZSHRC="/root/.zshrc"
[ -n "$SUDO_USER" ] && ZSHRC="/home/$SUDO_USER/.zshrc"

add_alias() {
    local name="$1" cmd="$2"
    if ! grep -q "alias $name=" "$ZSHRC" 2>/dev/null; then
        echo "alias $name='$cmd'" >> "$ZSHRC"
        log "Alias '$name' añadido"
    else
        warn "Alias '$name' ya existe, omitiendo"
    fi
}

create_venv() {
    local venv_dir="$1"
    local python_bin="${2:-python3}"

    if [ ! -d "$venv_dir" ]; then
        if [ "$python_bin" = "python2" ]; then
            if ! command -v python2 &>/dev/null && ! command -v python2.7 &>/dev/null; then
                error "Python 2 no encontrado. Ejecuta primero install_python2()."
            fi
            local py2_bin
            py2_bin=$(command -v python2 || command -v python2.7)

            local tmp_venv="/tmp/virtualenv-legacy-venv"
            if [ ! -d "$tmp_venv" ]; then
                python3 -m venv "$tmp_venv"
                "$tmp_venv/bin/pip" install -q setuptools
                "$tmp_venv/bin/pip" install -q "virtualenv==16.7.12"
            fi
            "$tmp_venv/bin/virtualenv" -p "$py2_bin" "$venv_dir"
        else
            python3 -m venv "$venv_dir"
        fi
        log "venv creado → $venv_dir"
    else
        warn "venv ya existe → $venv_dir"
    fi

    "$venv_dir/bin/pip" install --upgrade pip setuptools wheel -q 2>/dev/null || \
        "$venv_dir/bin/pip" install --upgrade pip setuptools -q
}

venv_pip() {
    local venv_pip_bin="$1/bin/pip"; shift
    if [[ "$venv_pip_bin" != /opt/*/venv/bin/pip ]]; then
        error "Intento de usar pip fuera de un venv. Abortando."
    fi
    "$venv_pip_bin" install -q "$@"
}

# ── Dependencias ──────────────────────────────────────────────
install_deps() {
    section "Dependencias"
    apt update -qq
    apt install -y \
        git \
        python3 python3-venv python3-dev \
        libssl-dev libcrypt-dev libffi-dev \
        build-essential gcc
    log "Dependencias instaladas"
}

# ── Python 2 ──────────────────────────────────────────────────
install_python2() {
    section "Python 2"

    apt install -y libcrypt-dev libssl-dev libffi-dev build-essential gcc 2>/dev/null || true

    if command -v python2 &>/dev/null || command -v python2.7 &>/dev/null; then
        warn "Python 2 ya está instalado"
    else
        if apt install -y python2 python2-dev 2>/dev/null; then
            log "Python 2 instalado via apt"
        else
            warn "python2 no disponible en apt, intentando python2.7..."
            apt install -y python2.7 python2.7-dev 2>/dev/null || \
                error "No se pudo instalar Python 2. Volatility 2 no estará disponible."
        fi
    fi

    apt install -y python3-virtualenv virtualenv 2>/dev/null || \
        pip3 install virtualenv --break-system-packages

    local py2_bin
    py2_bin=$(command -v python2 || command -v python2.7 || echo "")
    [ -z "$py2_bin" ] && error "Python 2 no encontrado tras la instalación"
    log "Python 2 → $py2_bin ($("$py2_bin" --version 2>&1))"
}

# ── Volatility 2 ──────────────────────────────────────────────
install_volatility2() {
    section "Volatility 2 (venv Python 2)"

    local INSTALL_DIR="/opt/volatility2"
    local VENV_DIR="$INSTALL_DIR/venv"

    if [ ! -d "$INSTALL_DIR/.git" ]; then
        git clone https://github.com/volatilityfoundation/volatility "$INSTALL_DIR"
    else
        warn "Repo vol2 ya existe"
    fi

    create_venv "$VENV_DIR" python2

    venv_pip "$VENV_DIR" \
        pycryptodome \
        distorm3 \
        yara-python \
        Pillow \
        openpyxl \
        ujson

    cd "$INSTALL_DIR"
    "$VENV_DIR/bin/python" setup.py install -q 2>/dev/null || true
    cd - > /dev/null

    add_alias "vol2" "$VENV_DIR/bin/python $INSTALL_DIR/vol.py"
    log "Volatility 2 listo → $VENV_DIR"
}

# ── Volatility 3 ──────────────────────────────────────────────
install_volatility3() {
    section "Volatility 3 (venv Python 3)"

    local INSTALL_DIR="/opt/volatility3"
    local VENV_DIR="$INSTALL_DIR/venv"

    if [ ! -d "$INSTALL_DIR/.git" ]; then
        git clone https://github.com/volatilityfoundation/volatility3 "$INSTALL_DIR"
    else
        warn "Repo vol3 ya existe"
    fi

    create_venv "$VENV_DIR" python3

    venv_pip "$VENV_DIR" \
        pefile \
        yara-python \
        capstone \
        pycryptodome

    "$VENV_DIR/bin/pip" install -q "$INSTALL_DIR"

    add_alias "vol3" "$VENV_DIR/bin/python $INSTALL_DIR/vol.py"
    log "Volatility 3 listo → $VENV_DIR"
}

# ── MAIN ──────────────────────────────────────────────────────
main() {
    install_deps
    install_python2
    install_volatility2
    install_volatility3

    echo -e "\n${BOLD}${GREEN}══ Volatility instalado ══${NC}"
    echo -e "Recarga la shell: ${CYAN}source $ZSHRC${NC}\n"
    echo -e "  ${CYAN}vol2${NC} -f memoria.mem --profile=Win7SP1x64 pslist"
    echo -e "  ${CYAN}vol3${NC} -f memoria.mem windows.pslist\n"
}

main