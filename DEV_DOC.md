# Inception Developer Documentation

## Purpose

This document explains how a developer can set up, build, launch, inspect, and maintain the Inception project from scratch. It focuses on the development workflow, configuration files, secrets, Docker Compose, volumes, and debugging commands.

## High-level architecture

The project is a Docker Compose infrastructure running inside a Linux virtual machine.

Mandatory services:

```text
Browser
  |
  | HTTPS :443
  v
NGINX
  |
  | FastCGI / internal Docker network
  v
WordPress + PHP-FPM
  |
  | MariaDB protocol / internal Docker network
  v
MariaDB
```

Persistent storage:

```text
MariaDB container  -> Docker named volume -> /home/alvmoral/data/mariadb
WordPress container -> Docker named volume -> /home/alvmoral/data/wordpress
NGINX container     -> reads WordPress files from the WordPress volume
```

The mandatory stack should expose only NGINX on port `443`. Other services communicate through the internal Docker network.

## Prerequisites

Inside the virtual machine, install:

- Docker.
- Docker Compose plugin.
- `make`.
- Basic tools such as `curl`, `openssl`, and a text editor.

Useful checks:

```sh
docker --version

docker compose version

make --version
```

## Initial setup from scratch

### 1. Clone the repository

```sh
git clone <repository-url> inception
cd inception
```

### 2. Create persistent data directories

The subject requires named volumes to store their data under `/home/login/data`. For this project login:

```sh
mkdir -p /home/alvmoral/data/mariadb
mkdir -p /home/alvmoral/data/wordpress
```

Make sure the user running Docker has the required permissions.

### 3. Configure the domain

The domain must point to the VM IP address.

On the host machine, add an entry to `/etc/hosts` or the Windows hosts file.

Example for a VM reachable at `192.168.56.110`:

```text
192.168.56.110 alvmoral.42.fr
```

Then verify resolution:

```sh
ping alvmoral.42.fr
```

### 4. Create `srcs/.env`

`srcs/.env` stores non-confidential configuration.

Example:

```env
DOMAIN_NAME=alvmoral.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_HOST=mariadb

WORDPRESS_URL=https://alvmoral.42.fr
WORDPRESS_TITLE=Inception
WORDPRESS_ADMIN_USER=wp_owner
WORDPRESS_USER=wp_user
```

Do not put passwords in this file.

### 5. Create local secrets

Create a local `secrets/` directory at the repository root:

```sh
mkdir -p secrets
```

Create the secret files required by the Compose file:

```sh
printf 'change_me_db_password\n' > secrets/db_password.txt
printf 'change_me_root_password\n' > secrets/db_root_password.txt
printf 'change_me_application_password\n' > secrets/credentials.txt
```

Use real local values instead of the examples above.

Make sure `secrets/` is ignored by Git:

```gitignore
secrets/
*.pem
*.key
*.crt
```

Do not ignore self-signed public certificates if your project expects them to be part of the build context, but never commit private credentials unless the subject or evaluation explicitly allows test-only placeholders.

## Building and launching

From the root of the repository:

```sh
make
```

The Makefile should call Docker Compose using `srcs/docker-compose.yml`.

Equivalent direct command:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up --build -d
```

Stop the project:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env down
```

Rebuild without cache:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env build --no-cache
```

Launch after rebuild:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d
```

## Expected Compose design

The Compose file should define:

- One service per container.
- One image name matching the corresponding service name.
- A custom Dockerfile for each service.
- A dedicated Docker network.
- Named volumes for MariaDB and WordPress data.
- Restart policies for crash recovery.
- Secrets or mounted secret files for confidential values.

Forbidden or dangerous patterns:

- `network: host`.
- `links:` or `--link`.
- `latest` image tags.
- Passwords in Dockerfiles.
- Infinite loop commands such as `tail -f`, `sleep infinity`, `while true`, or an idle shell used only to keep the container alive.

Each container should run the real service process in the foreground so that it becomes PID 1 or is correctly managed by the container entrypoint.

## Service notes

### NGINX

Role:

- Public HTTPS entrypoint.
- Listens on port `443`.
- Uses TLSv1.2 and/or TLSv1.3 only.
- Serves WordPress through PHP-FPM.
- May proxy or expose bonus routes if configured.

Typical checks:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs nginx

curl -kI https://alvmoral.42.fr

openssl s_client -connect alvmoral.42.fr:443 -tls1_2

openssl s_client -connect alvmoral.42.fr:443 -tls1_3
```

### WordPress + PHP-FPM

Role:

- Installs/configures WordPress.
- Runs PHP-FPM.
- Does not contain NGINX.
- Connects to MariaDB through the Docker network.
- Uses the WordPress volume for website files.

Typical checks:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs wordpress

docker exec -it wordpress sh
```

Inside the container, useful paths may include:

```text
/var/www/html
/usr/local/bin/wp
```

depending on the final implementation.

### MariaDB

Role:

- Initializes the WordPress database.
- Creates the required database user.
- Creates a second WordPress user at application level through the WordPress setup.
- Stores database files in the MariaDB named volume.

Typical checks:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs mariadb

docker exec -it mariadb sh
```

From inside the MariaDB container:

```sh
mariadb -u root -p
```

or, depending on the installed client:

```sh
mysql -u root -p
```

### Redis bonus

Role:

- Provides cache for WordPress.
- WordPress connects to it through the Docker network using the Redis service name.

Checks:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs redis

docker exec -it redis redis-cli ping
```

Expected result:

```text
PONG
```

### FTP bonus

Role:

- Provides FTP access to the WordPress website volume.
- The FTP local root should point to the WordPress files volume.

Checks:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs ftp
```

Common configuration points:

- Passive port range must match exposed ports.
- The FTP user must have permissions on the mounted WordPress volume.
- The chroot directory must exist.
- Boolean values in `vsftpd.conf` must be clean, with no hidden carriage returns or invalid trailing characters.

### Adminer bonus

Role:

- Provides a web UI to connect to MariaDB.

Connection values:

```text
Server: mariadb
Database: MYSQL_DATABASE from srcs/.env
Username: MYSQL_USER from srcs/.env
Password: secrets/db_password.txt
```

### Static site bonus

Role:

- Provides a simple static website written without PHP.
- Can be served by NGINX or by its own static server container, depending on the final implementation.

### Portainer bonus

Role:

- Provides a web UI to inspect and manage Docker containers, images, networks, and volumes.
- This service is useful during development and defense because it gives a visual overview of the stack.

If used as the free-choice bonus service, justify it as a practical administration and monitoring interface for a Docker-based project.

## Managing containers

List containers:

```sh
docker ps

docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps
```

View logs:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs

docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs nginx

docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs wordpress

docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs mariadb
```

Restart one service:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env restart nginx
```

Open a shell inside a container:

```sh
docker exec -it nginx sh

docker exec -it wordpress sh

docker exec -it mariadb sh
```

Use `bash` only if it is installed in that image. Debian images may have it; Alpine images often use `sh`.

## Managing images

List images:

```sh
docker images
```

Rebuild one service:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env build nginx
```

Rebuild all services:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env build --no-cache
```

## Managing volumes

List volumes:

```sh
docker volume ls
```

Inspect volumes:

```sh
docker volume inspect srcs_mariadb

docker volume inspect srcs_wordpress
```

Volume names may change depending on the Compose project name.

Check host data:

```sh
ls -la /home/alvmoral/data

ls -la /home/alvmoral/data/mariadb

ls -la /home/alvmoral/data/wordpress
```

Remove containers without deleting volumes:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env down
```

Remove containers and volumes:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env down -v
```

Warning: `down -v` deletes Docker volumes. Use it only when you intentionally want to reset persistent data.

## Managing networks

List networks:

```sh
docker network ls
```

Inspect the project network:

```sh
docker network inspect srcs_inception
```

Network names may change depending on the Compose project name.

From a container, service names should resolve internally:

```sh
docker exec -it wordpress sh
```

Then, inside the WordPress container:

```sh
getent hosts mariadb
getent hosts redis
```

`redis` only applies if the Redis bonus service is enabled.

## Data persistence

The project persists two main types of data:

### Database data

Stored in the MariaDB named volume and mapped to:

```text
/home/alvmoral/data/mariadb
```

This includes WordPress tables, users, posts, pages, options, and plugin data.

### WordPress files

Stored in the WordPress named volume and mapped to:

```text
/home/alvmoral/data/wordpress
```

This includes WordPress core files, themes, plugins, and uploaded media.

Containers can be rebuilt without losing these files as long as volumes are not removed.

## Git hygiene

Do not commit:

- Real passwords.
- Secret files.
- Database data.
- WordPress uploaded media generated during testing.
- TLS private keys if they contain real private material.
- Temporary logs or local debugging files.

Recommended `.gitignore` entries:

```gitignore
secrets/
*.log
*.tmp
.env.local
.DS_Store
```

Do not ignore `srcs/.env` if the subject requires it to be present, but keep it free of secrets.

## Troubleshooting

### Container keeps restarting

Check logs:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs <service>
```

Common causes:

- Entrypoint exits immediately.
- Required secret file is missing.
- Configuration file has invalid syntax.
- Service tries to connect before its dependency is ready.
- The foreground process is not started correctly.

### NGINX returns Bad Gateway

A `502 Bad Gateway` usually means NGINX cannot reach PHP-FPM.

Check:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs nginx

docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs wordpress
```

Verify:

- WordPress/PHP-FPM container is running.
- NGINX upstream points to the correct service name and port.
- PHP-FPM is listening on the expected port, usually `9000`.
- Both services share the same Docker network.

### NGINX returns Gateway Timeout

A `504 Gateway Timeout` usually means NGINX reached the upstream but did not get a response in time.

Possible causes:

- WordPress is waiting for MariaDB.
- MariaDB is down.
- PHP-FPM is overloaded or blocked.
- WordPress initialization is still running.

Check WordPress and MariaDB logs.

### WordPress says Error establishing a database connection

Verify:

- MariaDB container is running.
- Database user and password match.
- WordPress uses the service name `mariadb` as database host.
- The database has been initialized.
- The secret files are readable inside the container.

### MariaDB initialization does not repeat

MariaDB only initializes a new database when the data directory is empty. If the volume already contains data, initialization scripts may be skipped.

To force a fresh initialization, remove the MariaDB volume or clean `/home/alvmoral/data/mariadb`, but only if you are sure you want to delete the existing database.

### FTP cannot write files

Check:

- The FTP user maps to the correct local user.
- The mounted WordPress volume has write permissions.
- `local_root` points to the correct directory.
- The chroot directory exists.
- Passive ports are correctly exposed.

### Adminer cannot connect

Use the Docker service name as server:

```text
mariadb
```

Do not use `localhost`, because inside the Adminer container `localhost` means the Adminer container itself.

### Portainer asks for login again

If Portainer already initialized its data directory, the initial admin password flag may not recreate or overwrite the existing user. Remove the Portainer data volume only if you intentionally want to reset its state.

## Validation checklist

Before peer evaluation, check:

- The project runs inside a virtual machine.
- `Makefile` is at the repository root.
- `README.md`, `USER_DOC.md`, and `DEV_DOC.md` are at the repository root.
- `srcs/docker-compose.yml` exists.
- `srcs/.env` exists and contains no passwords.
- `secrets/` exists locally and is ignored by Git.
- Each mandatory service has its own Dockerfile.
- Images are built locally from Debian or Alpine bases.
- No mandatory service uses a ready-made Docker Hub image except allowed base images.
- No service uses the `latest` tag.
- NGINX is the only mandatory public entrypoint and exposes port `443`.
- TLSv1.2 and/or TLSv1.3 is configured.
- WordPress runs with PHP-FPM and without NGINX.
- MariaDB runs without NGINX.
- MariaDB and WordPress use named volumes.
- Named volume data is stored under `/home/alvmoral/data`.
- A Docker network is defined and used.
- `network: host`, `links:`, and `--link` are not used.
- Containers restart on crash.
- No container is kept alive with `tail -f`, `sleep infinity`, `while true`, or an idle shell.
- WordPress database contains two WordPress users, one being the administrator.
- The administrator username does not contain forbidden admin-related substrings.
- `https://alvmoral.42.fr` opens the website.
- `https://alvmoral.42.fr/wp-admin` opens the WordPress administration panel.
