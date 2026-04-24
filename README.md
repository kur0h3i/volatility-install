# Volatility Install — Instalación aislada para Kali Linux

Script de instalación automática de **Volatility 2** y **Volatility 3** en entornos aislados (virtualenv), sin contaminar el Python del sistema.

---

## Requisitos

| Requisito | Detalle |
|---|---|
| OS | Kali Linux (probado en versiones modernas) |
| Permisos | root / sudo |
| Conexión | Internet (clona repos de GitHub) |
| Shell | bash o zsh |

---

## Instalación rápida

```bash
sudo bash volatility-install.sh
```

Al terminar, recarga tu shell:

```bash
source ~/.zshrc
```

---

## Qué hace el script

El script ejecuta 4 pasos en orden:

### 1. Dependencias base
Instala via `apt` los paquetes necesarios para compilar extensiones nativas:

```
git, python3, python3-venv, python3-dev,
libssl-dev, libcrypt-dev, libffi-dev, build-essential, gcc
```

> Estas librerías son necesarias para compilar módulos como `distorm3` y `yara-python`.

---

### 2. Python 2
Kali moderno no incluye Python 2 por defecto. El script lo instala desde `apt` (`python2` o `python2.7`) junto con sus cabeceras de desarrollo.

También instala `virtualenv` para poder crear entornos Python 2 aislados (Python 3's `venv` no soporta Python 2).

---

### 3. Volatility 2

| Item | Valor |
|---|---|
| Repo | `github.com/volatilityfoundation/volatility` |
| Directorio | `/opt/volatility2` |
| Entorno | `/opt/volatility2/venv` (Python 2) |
| Alias | `vol2` |

**Dependencias instaladas en el venv:**

| Paquete | Uso |
|---|---|
| `pycryptodome` | Descifrado de credenciales y hashes |
| `distorm3` | Desensamblado x86/x64 |
| `yara-python` | Escaneo con reglas YARA |
| `Pillow` | Extracción de imágenes de memoria |
| `openpyxl` | Exportación a Excel |
| `ujson` | Serialización JSON rápida |

> Se usa un `virtualenv` versión 16.7.12 (legacy) porque las versiones modernas de virtualenv no soportan Python 2.

---

### 4. Volatility 3

| Item | Valor |
|---|---|
| Repo | `github.com/volatilityfoundation/volatility3` |
| Directorio | `/opt/volatility3` |
| Entorno | `/opt/volatility3/venv` (Python 3) |
| Alias | `vol3` |

**Dependencias instaladas en el venv:**

| Paquete | Uso |
|---|---|
| `pefile` | Análisis de ejecutables PE (Windows) |
| `yara-python` | Escaneo con reglas YARA |
| `capstone` | Desensamblado multiplataforma |
| `pycryptodome` | Operaciones criptográficas |

---

## Uso tras la instalación

### Volatility 2

```bash
# Listar procesos
vol2 -f memoria.mem --profile=Win7SP1x64 pslist

# Conexiones de red
vol2 -f memoria.mem --profile=Win7SP1x64 netscan

# Ver perfiles disponibles
vol2 --info | grep Profile
```

### Volatility 3

```bash
# Listar procesos
vol3 -f memoria.mem windows.pslist

# Árbol de procesos
vol3 -f memoria.mem windows.pstree

# Conexiones de red
vol3 -f memoria.mem windows.netstat

# Volcados de memoria Linux
vol3 -f memoria.mem linux.pslist
```

---

## Estructura de directorios

```
/opt/
├── volatility2/
│   ├── venv/          ← entorno Python 2 aislado
│   ├── vol.py         ← punto de entrada
│   └── ...
└── volatility3/
    ├── venv/          ← entorno Python 3 aislado
    ├── vol.py         ← punto de entrada
    └── ...
```

---

## Diseño de seguridad

El script usa un wrapper `venv_pip()` que **solo permite instalar paquetes dentro de rutas `/opt/*/venv/`**, abortando si se intenta usar pip fuera de un entorno aislado. Esto evita modificaciones accidentales al Python del sistema.

Los alias se añaden al `.zshrc` del usuario que invocó `sudo` (no al de root), y solo si no existen previamente.