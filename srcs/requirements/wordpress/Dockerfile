FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-cli \
    php-curl \
    php-gd \
    php-intl \
    php-mbstring \
    php-soap \
    php-xml \
    php-xmlrpc \
    php-zip \
    wget \
    curl \
    unzip \
    mariadb-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio web
RUN mkdir -p /var/www/html

# Descargar WordPress
RUN wget https://wordpress.org/latest.tar.gz -P /tmp \
    && tar -xzf /tmp/latest.tar.gz -C /var/www/html --strip-components=1 \
    && rm /tmp/latest.tar.gz

# Copiar configuración PHP-FPM
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Copiar wp-config base (con env vars)
COPY conf/wp-config.php /var/www/html/wp-config.php

# Permisos
RUN chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

EXPOSE 9000

CMD ["php-fpm8.2", "-F"]
