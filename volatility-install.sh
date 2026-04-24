install_python2() {
    section "Python 2"

    # Cabeceras de compilación — siempre, aunque python2 ya esté presente
    apt install -y libcrypt-dev libssl-dev libffi-dev build-essential gcc 2>/dev/null || true

    # Instalar binario si falta
    if ! command -v python2 &>/dev/null && ! command -v python2.7 &>/dev/null; then
        if apt install -y python2 python2-dev 2>/dev/null; then
            log "Python 2 instalado via apt"
        else
            warn "python2 no disponible en apt, intentando python2.7..."
            apt install -y python2.7 python2.7-dev 2>/dev/null || \
                error "No se pudo instalar Python 2. Volatility 2 no estará disponible."
        fi
    else
        warn "Binario Python 2 ya presente — instalando/actualizando headers de desarrollo"
        apt install -y python2-dev 2>/dev/null || \
        apt install -y python2.7-dev 2>/dev/null || \
            warn "python2-dev no disponible via apt (puede que ya esté instalado)"
    fi

    # Verificar que Python.h existe — es lo que falla al compilar extensiones C
    local py_inc
    py_inc=$(python2 -c "import sysconfig; print(sysconfig.get_path('include'))" 2>/dev/null || \
             python2.7 -c "import sysconfig; print(sysconfig.get_path('include'))" 2>/dev/null || echo "")

    if [ -z "$py_inc" ] || [ ! -f "$py_inc/Python.h" ]; then
        # Fallback: buscar Python.h manualmente
        local found_h
        found_h=$(find /usr/include -name "Python.h" 2>/dev/null | grep -i python2 | head -1 || true)
        [ -z "$found_h" ] && error "Python.h no encontrado. Instala python2.7-dev manualmente: apt install python2.7-dev"
        log "Python.h encontrado → $found_h"
    else
        log "Python.h verificado → $py_inc/Python.h"
    fi

    apt install -y python3-virtualenv virtualenv 2>/dev/null || \
        pip3 install virtualenv --break-system-packages

    local py2_bin
    py2_bin=$(command -v python2 || command -v python2.7 || echo "")
    [ -z "$py2_bin" ] && error "Python 2 no encontrado tras la instalación"
    log "Python 2 → $py2_bin ($("$py2_bin" --version 2>&1))"
}
