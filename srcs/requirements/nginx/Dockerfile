FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/nginx/sites-enabled/default

RUN mkdir -p /etc/nginx/certs

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY certs/fullchain.pem /etc/nginx/certs/
COPY certs/privkey.pem /etc/nginx/certs/

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]