# volatility-install.sh

Instala **Volatility 2** y **Volatility 3** en Kali Linux, cada uno en su propio virtualenv bajo `/opt/`.

## Uso

```bash
sudo bash volatility-install.sh          # instalación normal
sudo bash volatility-install.sh --force  # forzar reinstalación
```

Recarga la shell al terminar:

```bash
source ~/.zshrc
```

## Comandos

```bash
vol2 -f memoria.mem --profile=Win7SP1x64 pslist
vol3 -f memoria.mem windows.pslist
```

```
