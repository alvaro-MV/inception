FROM debian:bookworm


COPY tools/entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

COPY tools/portainer /portainer
COPY tools/docker /docker
COPY tools/public /public
COPY tools/mustache-templates /mustache-templates

EXPOSE 8000
EXPOSE 9443
EXPOSE 9000  

WORKDIR /

ENTRYPOINT ["/usr/bin/entrypoint.sh"]