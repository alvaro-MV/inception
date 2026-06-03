FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        vsftpd \
        db5.3-util \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 21
EXPOSE 64000-64321

WORKDIR /srv/vsftpd

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]