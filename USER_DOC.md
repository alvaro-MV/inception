# Inception User Documentation

## Purpose

This document explains how an end user or administrator can use the Inception stack after it has been configured. It focuses on starting and stopping the project, accessing the website, finding credentials, and checking that the services are running correctly.

## Services provided by the stack

The project provides a small WordPress infrastructure running with Docker Compose.

### Mandatory services

| Service | What it does |
|---|---|
| NGINX | Public HTTPS entrypoint. It receives browser requests on port `443`. |
| WordPress + PHP-FPM | Runs the WordPress application. |
| MariaDB | Stores the WordPress database. |
| Docker network | Allows the containers to communicate internally. |
| Docker volumes | Store database files and WordPress website files persistently. |

### Optional bonus services

If the bonus part is enabled, the stack may also provide:

| Service | What it does |
|---|---|
| Redis | Improves WordPress performance by caching data. |
| FTP server | Gives file access to the WordPress website volume. |
| Adminer | Provides a web interface to inspect or manage the database. |
| Static website | Provides a simple non-PHP static site. |
| Portainer | Provides a web UI to inspect and manage Docker resources. |

Bonus services may expose additional ports or routes depending on the final configuration.

## Starting the project

Go to the root of the repository and run:

```sh
make
```

This command should build the Docker images and start the full stack through Docker Compose.

Depending on the Makefile, the following command may also be available:

```sh
make up
```

## Stopping the project

To stop the containers without necessarily deleting persistent data:

```sh
make down
```

or directly with Docker Compose:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env down
```

Stopping the project does not normally delete the database or WordPress files, because they are stored in Docker named volumes.

## Rebuilding the project

To rebuild the images and restart the stack, use:

```sh
make re
```

A full cleanup command may also exist:

```sh
make fclean
```

Be careful: depending on the Makefile implementation, `fclean` may remove volumes and therefore delete persistent WordPress and MariaDB data.

## Accessing the website

The website is available through HTTPS:

```text
https://alvmoral.42.fr
```

The browser may show a warning because the TLS certificate can be self-signed. This is expected in a local development project.

## Accessing the WordPress administration panel

The WordPress administration panel is available at:

```text
https://alvmoral.42.fr/wp-admin
```

Use the WordPress administrator credentials created during the WordPress initialization step.

Important subject constraint: the administrator username must not contain `admin`, `Admin`, `administrator`, or `Administrator`.

## Accessing bonus administration tools

If Adminer is enabled, it may be available through a route such as:

```text
https://alvmoral.42.fr/adminer
```

Typical Adminer connection values:

```text
System: MariaDB / MySQL
Server: mariadb
Database: value of MYSQL_DATABASE from srcs/.env
Username: value of MYSQL_USER from srcs/.env
Password: value stored in secrets/db_password.txt
```

If Portainer is enabled, it may be available through a route such as:

```text
https://alvmoral.42.fr/portainer
```

or through its own HTTPS port if the bonus configuration exposes one.

## Locating credentials

Credentials are not stored directly inside Dockerfiles and should not be committed to Git.

Configuration values are usually stored in:

```text
srcs/.env
```

Sensitive values are stored locally in:

```text
secrets/
├── credentials.txt
├── db_password.txt
└── db_root_password.txt
```

The exact content depends on the implementation, but the usual meaning is:

| File | Purpose |
|---|---|
| `db_password.txt` | Password for the normal MariaDB/WordPress database user. |
| `db_root_password.txt` | Password for the MariaDB root user. |
| `credentials.txt` | Application-level credentials, for example WordPress or bonus-service credentials. |

Do not share these files and do not push them to the repository.

## Checking that services are running

From the root of the repository:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps
```

You should see the main services running:

```text
nginx
wordpress
mariadb
```

If bonus services are enabled, you may also see:

```text
redis
ftp
adminer
portainer
```

## Checking logs

To check all logs:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs
```

To check one service:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs nginx

docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs wordpress

docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs mariadb
```

## Checking HTTPS

Use `curl`:

```sh
curl -kI https://alvmoral.42.fr
```

A successful response should show an HTTP status from NGINX/WordPress, such as `200`, `301`, or `302`, depending on the route.

## Checking persistent data

The project stores persistent data under:

```text
/home/alvmoral/data
```

Typical folders:

```text
/home/alvmoral/data/mariadb
/home/alvmoral/data/wordpress
```

The database volume stores MariaDB data. The WordPress volume stores website files, plugins, themes, and uploaded media.

## Common problems

### The domain does not resolve

Check that the host machine has an entry for the project domain.

Example:

```text
192.168.56.110 alvmoral.42.fr
```

Use the IP address that reaches the VM.

### The browser shows a certificate warning

This is normal if the project uses a self-signed TLS certificate.

### WordPress cannot connect to the database

Check:

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs mariadb

docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs wordpress
```

Also verify that the database name, user, password, and host match between `.env`, secrets, and WordPress configuration.

### Adminer cannot connect to MariaDB

Use `mariadb` as the database server name, not `localhost`. Inside Docker Compose, service names are used as DNS names.

### Redis cache does not work

Check that the Redis container is running and that WordPress is configured to use the Redis service name, usually `redis`.

### Data disappeared after cleanup

If a cleanup target removes volumes, the database and WordPress files can be deleted. Before running destructive commands, check the Makefile and back up `/home/alvmoral/data` if needed.
