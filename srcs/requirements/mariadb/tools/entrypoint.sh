#!/bin/bash
set -e

echo "==> MariaDB entrypoint starting..."

: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"
: "${MYSQL_PASSWORD:?Missing MYSQL_PASSWORD}"

# Permisos por si el volumen viene del host
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

echo "==> Starting MariaDB..."

mariadbd --user=mysql --bind-address=0.0.0.0 &
pid="$!"

# Esperar a que MariaDB esté listo
until mariadb-admin ping >/dev/null 2>&1; do
    sleep 1
done

echo "==> Applying idempotent SQL configuration..."

mariadb <<EOF
-- Database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

-- User
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
  IDENTIFIED BY '${MYSQL_PASSWORD}';

ALTER USER '${MYSQL_USER}'@'%'
  IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

echo "==> MariaDB ready."

# Traer MariaDB a foreground (PID 1)
wait "$pid"
