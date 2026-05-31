#!/usr/bin/env bash
set -euo pipefail

CERT_DIR=/etc/nginx/certs
KEY="${CERT_DIR}/server.key"
CRT="${CERT_DIR}/server.crt"

mkdir -p "$CERT_DIR"

if [ ! -f "$KEY" ] || [ ! -f "$CRT" ]; then
  echo ">> Generando certificado self-signed"

  openssl ecparam -genkey -name prime256v1 -out "$KEY"

  openssl req -new -x509 \
    -key "$KEY" \
    -out "$CRT" \
    -days 365 \
    -subj "/CN=alvmoral.42.fr"

  chmod 600 "$KEY" "$CRT"
fi

exec nginx -g "daemon off;"