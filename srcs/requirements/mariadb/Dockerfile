FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copiar configuración
COPY conf/my.cnf /etc/mysql/my.cnf

# Script de arranque
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /var/run/mysqld /var/log/mysql && \
    chown -R mysql:mysql /var/run/mysqld /var/log/mysql /var/lib/mysql && \
    chmod 755 /var/log/mysql && \
    chmod 777 /var/run/mysqld

# Directorio de datos (volumen)
VOLUME /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
