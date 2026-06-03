FROM debian:bookworm

# export PATH="$HOME/go/bin:$PATH"

curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh | bash nodesource_setup.sh

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
		curl \
        ca-certificates \
		sqlite3 \
        golang-go \
		nodejs \


    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 21
EXPOSE 64000-64321

WORKDIR /srv/vsftpd

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# mkdir my-webpack-project
# cd my-webpack-project
# npm init -y
# npm install --save-dev webpack webpack-cli
