#!/usr/bin/env bash
set -euo pipefail

cd /var/www/html

DB_PASS="$(cat "$MYSQL_PASSWORD_FILE")"
ADMIN_PASS="$(cat "$WP_ADMIN_PASSWORD_FILE")"
USER_PASS="$(cat "$WP_USER_PASSWORD_FILE")"

echo "==> Waiting for MariaDB..."

until mysqladmin ping \
  -h"${MYSQL_HOST}" \
  -u"${MYSQL_USER}" \
  -p"${DB_PASS}" \
  --silent; do
    sleep 2
done

echo "==> MariaDB is ready."

if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "==> Installing WordPress..."

  wp core install \
    --url="https://${DOMAIN_NAME}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${ADMIN_PASS}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root

  echo "==> Creating second user..."

  wp user create \
    "${WP_USER}" \
    "${WP_USER_EMAIL}" \
    --user_pass="${USER_PASS}" \
    --role=author \
    --allow-root
else
  echo "==> WordPress already installed."
fi

REDIS_MARKER="/var/www/html/.redis_configured"

if [ ! -f "$REDIS_MARKER" ]; then
  echo "[WP] Setting up Redis cache..."
  wp plugin install redis-cache --activate --path=/var/www/html --allow-root || true
  wp config set WP_REDIS_HOST redis --type=constant --path=/var/www/html --allow-root
  wp config set WP_REDIS_PORT 6379 --raw --type=constant --path=/var/www/html --allow-root
  wp redis enable --path=/var/www/html --allow-root || true
  touch "$REDIS_MARKER"
  chown www-data:www-data "$REDIS_MARKER"
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F