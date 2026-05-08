#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIGURA ESTO
# =========================
OLD_USER="usuario_antiguo"
NEW_USER="alvaro"
NEW_HOME="/home/alvaro"

# Pon "true" si quieres borrar el usuario antiguo y su home.
# OJO: destructivo.
DELETE_OLD_USER=false

# Pon "true" si quieres que el nuevo usuario pueda usar sudo sin contraseña.
NOPASSWD_SUDO=false

# Grupos típicos útiles en Ubuntu/Debian + VirtualBox
EXTRA_GROUPS="sudo,adm,cdrom,dip,plugdev,lpadmin,vboxsf"

# =========================
# COMPROBACIONES
# =========================
if [[ "$EUID" -ne 0 ]]; then
    echo "Error: ejecuta este script con sudo."
    exit 1
fi

if [[ "$NEW_USER" == "$OLD_USER" ]]; then
    echo "Error: OLD_USER y NEW_USER no pueden ser iguales."
    exit 1
fi

echo "[1/7] Creando grupos si existen / preparando..."

# Crear grupo vboxsf si no existe, por si VirtualBox Guest Additions lo usa
if ! getent group vboxsf >/dev/null; then
    groupadd vboxsf || true
fi

echo "[2/7] Creando usuario nuevo: $NEW_USER"

if id "$NEW_USER" >/dev/null 2>&1; then
    echo "Usuario $NEW_USER ya existe."
else
    useradd \
        --create-home \
        --home-dir "$NEW_HOME" \
        --shell /bin/bash \
        "$NEW_USER"
fi

echo "[3/7] Ajustando home y permisos"

mkdir -p "$NEW_HOME"
chown -R "$NEW_USER:$NEW_USER" "$NEW_HOME"
chmod 700 "$NEW_HOME"

echo "[4/7] Añadiendo grupos útiles"

usermod -aG "$EXTRA_GROUPS" "$NEW_USER"

echo "[5/7] Configurando sudo"

if [[ "$NOPASSWD_SUDO" == true ]]; then
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$NEW_USER"
else
    echo "$NEW_USER ALL=(ALL:ALL) ALL" > "/etc/sudoers.d/90-$NEW_USER"
fi

chmod 440 "/etc/sudoers.d/90-$NEW_USER"
visudo -cf "/etc/sudoers.d/90-$NEW_USER"

echo "[6/7] Pidiendo contraseña para $NEW_USER"

passwd "$NEW_USER"

echo "[7/7] Gestionando usuario antiguo: $OLD_USER"

if id "$OLD_USER" >/dev/null 2>&1; then
    # Le quitamos sudo y grupos de privilegio
    gpasswd -d "$OLD_USER" sudo 2>/dev/null || true
    gpasswd -d "$OLD_USER" adm 2>/dev/null || true
    gpasswd -d "$OLD_USER" vboxsf 2>/dev/null || true

    # Bloqueamos la cuenta antigua
    passwd -l "$OLD_USER" || true

    if [[ "$DELETE_OLD_USER" == true ]]; then
        echo "Borrando usuario antiguo y su home..."
        deluser --remove-home "$OLD_USER"
    else
        echo "Usuario antiguo bloqueado, pero no borrado."
    fi
else
    echo "El usuario antiguo $OLD_USER no existe. Nada que hacer."
fi

echo
echo "======================================"
echo "Listo."
echo "Nuevo usuario: $NEW_USER"
echo "Home: $NEW_HOME"
echo "Grupos:"
id "$NEW_USER"
echo "======================================"