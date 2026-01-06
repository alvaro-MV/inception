# ./requirements/nginx/Dockerfile
FROM debian:bookworm-slim

LABEL maintainer="tú <you@example.com>"
ENV DEBIAN_FRONTEND=noninteractive

# Versiones visibles (opcional)
ENV NGINX_PACKAGES="nginx-full" \
    TZ=UTC

# 1) Usuario/grupo de servicio (no-root) UID/GID 101 para coherencia
RUN set -eux; \
    groupadd --system --gid 101 nginx; \
    useradd  --system --uid 101 --gid 101 --home /nonexistent --shell /usr/sbin/nologin nginx

# 2) Paquetes mínimos + limpieza
RUN set -eux; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
      ca-certificates openssl curl tzdata \
      $NGINX_PACKAGES; \
    rm -rf /var/lib/apt/lists/*

# 3) Logs a stdout/stderr (para `docker logs`)
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

# 4) Estructura: conf y contenido estático
#    - nginx.conf (global)
#    - conf.d/default.conf (servidor TLS)
#    - página estática de test
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY html/ /var/www/html/

# 5) Entrypoint: genera certificado self-signed si no existe
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh \
 && chown -R nginx:nginx /var/www/html

EXPOSE 443
STOPSIGNAL SIGQUIT

# Nginx como PID 1 (sin "daemon")
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

