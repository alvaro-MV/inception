FROM debian:bookworm

COPY conf/vsftpd.conf /etc/vsftpd.conf

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN apt-get update && apt-get install -y --no-install-recommends \
	apt-get install vsftpd \
	&& rm -rf /var/lib/apt/lists/*


EXPOSE 21
EXPOSE 64000-64321

WORKDIR /srv/ftp/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]