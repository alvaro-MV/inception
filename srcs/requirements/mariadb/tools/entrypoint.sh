#!/bin/bash
set -e

DB_NAME="${MYSQL_DATABASE}"
DB_USER="${MYSQL_USER}"

ROOT_PASS_FILE="${MYSQL_ROOT_PASSWORD_FILE}"
USER_PASS_FILE="${MYSQL_PASSWORD_FILE}"

if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$ROOT_PASS_FILE" ] || [ -z "$USER_PASS_FILE" ]; then
  echo "Missing required environment variables."
  exit 1
fi

ROOT_PASS="$(cat "$ROOT_PASS_FILE")"
USER_PASS="$(cat "$USER_PASS_FILE")"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

INIT_MARKER="/var/lib/mysql/.inception_initialized"

if [ ! -f "$INIT_MARKER" ]; then
  echo "[MariaDB] Initializing database..."
  chown -R mysql:mysql /var/lib/mysql
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null

  echo "[MariaDB] Starting temporary server..."
  mysqld --user=mysql \
    --datadir=/var/lib/mysql \
    --skip-networking \
    --socket=/run/mysqld/mysqld.sock &
  pid="$!"

  echo "[MariaDB] Waiting for server..."
  for i in {1..30}; do
    if mariadb --protocol=socket -uroot -S /run/mysqld/mysqld.sock -e "SELECT 1" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  echo "[MariaDB] Securing and creating database/user..."
  MYSQL_HOST= mariadb --protocol=socket -uroot -S /run/mysqld/mysqld.sock <<-SQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
    DELETE FROM mysql.user WHERE User='';
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    FLUSH PRIVILEGES;

    CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
      CHARACTER SET utf8mb4
      COLLATE utf8mb4_unicode_ci;

    CREATE USER IF NOT EXISTS '${DB_USER}'@'%'
      IDENTIFIED BY '${USER_PASS}';

    GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';

    FLUSH PRIVILEGES;
SQL

  touch "$INIT_MARKER"
  chown mysql:mysql "$INIT_MARKER"

  echo "[MariaDB] Stopping temporary server..."
  mysqladmin \
    --protocol=socket \
    -uroot \
    -p"${ROOT_PASS}" \
    -S /run/mysqld/mysqld.sock shutdown

  wait "$pid" || true
fi

echo "[MariaDB] Starting MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0