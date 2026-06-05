FROM debian:bookworm


COPY tools/entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

COPY tools/portainer portainer


EXPOSE 8000
EXPOSE 9443
EXPOSE 9000  

WORKDIR /

ENTRYPOINT ["/usr/bin/entrypoint.sh"]