#!/usr/bin/env bash
set -euo pipefail

CERT_DIR=/etc/ssl/nginx
KEY="${CERT_DIR}/server.key"
CRT="${CERT_DIR}/server.crt"

mkdir -p "$CERT_DIR"
# Crea un cert ECDSA (prime256v1) si no existe (solo para dev)
if [ ! -f "$KEY" ] || [ ! -f "$CRT" ]; then
  echo ">> Generando certificado self-signed (desarrollo)"
  openssl ecparam -genkey -name prime256v1 -out "$KEY"
  openssl req -new -x509 -key "$KEY" -out "$CRT" -days 365 \
    -subj "/CN=localhost"
  chmod 600 "$KEY" "$CRT"
fi

exec "$@"
