*This project has been created as part of the 42 curriculum by alvmoral.*

# Inception

## Description

Inception is a system administration project focused on building a small containerized web infrastructure with Docker Compose. The goal is to understand how independent services can be built, configured, connected, persisted, and exposed securely without relying on pre-built service images.

The project runs inside a virtual machine and builds every service image from a Debian or Alpine base image. Each service has its own Dockerfile, its own container, and a clear responsibility. The mandatory stack provides a WordPress website served through NGINX over HTTPS, with PHP-FPM running separately from the web server and MariaDB running separately from the application.

The mandatory infrastructure is composed of:

- **NGINX**: the only public entrypoint of the mandatory stack, exposed on port `443` and configured with TLSv1.2/TLSv1.3.
- **WordPress + PHP-FPM**: the application service. It contains WordPress and PHP-FPM only, without NGINX.
- **MariaDB**: the database service. It contains MariaDB only, without NGINX.
- **Docker network**: a dedicated internal bridge network used by the containers to communicate with each other.
- **Docker named volumes**: persistent storage for the database and WordPress files.

The expected public domain for the project is:

```text
https://alvmoral.42.fr
```

The domain must point to the local IP address of the virtual machine through the host's DNS configuration or `/etc/hosts` file.

## Project sources

All project configuration files are stored under the `srcs/` directory, while the root of the repository contains the `Makefile`, the main documentation files, and the local `secrets/` directory.

Expected repository organization:

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── bonus/
            ├── adminer/
            ├── ftp/
            ├── redis/
            ├── static-site/
            └── portainer/
```

The exact bonus directories may differ depending on which optional services are enabled.

## Main design choices

### One service per container

Each container is responsible for a single service. NGINX only handles HTTPS and reverse proxying/static file delivery, WordPress only runs the PHP application through PHP-FPM, and MariaDB only manages the database. This separation makes the infrastructure easier to debug, restart, rebuild, and reason about.

### Custom Dockerfiles

The project builds its own images instead of pulling ready-to-use images from Docker Hub. Only the base Debian or Alpine image is used as a starting point. This makes the installation and configuration steps explicit and forces the project to document how every service is assembled.

### NGINX as the public entrypoint

For the mandatory part, only NGINX exposes a public port. External clients reach the project through HTTPS on port `443`, while WordPress, PHP-FPM, and MariaDB remain inside the private Docker network.

### Persistent named volumes

The database and WordPress files must survive container recreation. For that reason, they are stored in Docker named volumes, mapped to the host under:

```text
/home/alvmoral/data
```

Typical persistent paths:

```text
/home/alvmoral/data/mariadb
/home/alvmoral/data/wordpress
```

### Environment variables and secrets

Non-confidential configuration is stored in `srcs/.env`. Confidential values such as passwords are stored in local secret files under `secrets/` and must not be committed to Git.

## Technical comparisons

### Virtual Machines vs Docker

A virtual machine virtualizes a full operating system. It has its own kernel, virtual hardware, boot process, userspace, and system services. This provides strong isolation but uses more resources.

Docker containers virtualize processes at the operating-system level. Containers share the host kernel but run in isolated namespaces with their own filesystem, network interfaces, processes, and environment. They are lighter and faster to start than virtual machines, but they are not full machines.

In this project, the whole Docker infrastructure runs inside a virtual machine because the subject requires a controlled Linux environment. Inside that VM, Docker is used to isolate and orchestrate the individual services.

### Secrets vs Environment Variables

Environment variables are useful for non-sensitive configuration such as domain names, database names, usernames, hostnames, and service ports. However, environment variables can be inspected from the container environment and should not be treated as secure storage for passwords.

Docker secrets are better suited for confidential values. In this project, passwords are stored in local files under `secrets/` and mounted into the relevant containers. The entrypoint scripts read the values from those files when initializing the services.

Typical rule used in this project:

- `.env`: configuration values.
- `secrets/`: passwords and credentials.

### Docker Network vs Host Network

A Docker bridge network creates an isolated network where containers can communicate by service name. For example, WordPress can connect to MariaDB using the MariaDB service name instead of a hardcoded IP address.

Using the host network would remove this isolation and make containers share the host network namespace. This is not allowed in the project and would make service boundaries less clear.

The project uses a dedicated Docker network so that:

- MariaDB is not exposed directly to the host.
- WordPress can reach MariaDB internally.
- NGINX can reach WordPress/PHP-FPM internally.
- Service names can be used as stable DNS names inside the network.

### Docker Volumes vs Bind Mounts

A bind mount maps a specific host path directly into a container. It is useful during development but tightly couples the container to the host filesystem layout.

A Docker named volume is managed by Docker and identified by a volume name. In this project, named volumes are required for the database and WordPress files. They are still stored under `/home/alvmoral/data` on the host, but Docker Compose manages them as named volumes.

Named volumes are used here because they provide controlled persistence while keeping the service definition explicit in `docker-compose.yml`.

## Services

### Mandatory services

| Service | Role | Publicly exposed? |
|---|---|---|
| `nginx` | HTTPS entrypoint, TLS termination, static delivery/proxying | Yes, port `443` |
| `wordpress` | WordPress application running with PHP-FPM | No |
| `mariadb` | WordPress database | No |

### Bonus services

Depending on the enabled bonus configuration, the project may also include:

| Service | Role |
|---|---|
| `redis` | Cache backend for WordPress |
| `ftp` | FTP access to the WordPress website volume |
| `adminer` | Web database administration tool |
| `static-site` | Simple static website written without PHP |
| `portainer` | Container management interface used as the extra useful service |

The bonus part is only relevant if the mandatory stack is fully functional.

## Instructions

### Prerequisites

The project is expected to run inside a Linux virtual machine with:

- Docker installed.
- Docker Compose available.
- `make` installed.
- The domain `alvmoral.42.fr` pointing to the VM IP address.
- Local secrets created under `secrets/`.
- A valid `srcs/.env` file.

### Configure the domain

On the host machine, add an entry pointing the project domain to the VM IP address.

Example:

```text
127.0.0.1 alvmoral.42.fr
```

or, if the VM has its own host-only/private IP:

```text
192.168.56.110 alvmoral.42.fr
```

Use the IP that actually reaches the VM from your host.

### Prepare data directories

The persistent data must be available under `/home/alvmoral/data` on the VM.

```sh
mkdir -p /home/alvmoral/data/mariadb
mkdir -p /home/alvmoral/data/wordpress
```

### Create configuration files

The `srcs/.env` file stores non-secret configuration. Example structure:

```env
DOMAIN_NAME=alvmoral.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_HOST=mariadb

WORDPRESS_TITLE=Inception
WORDPRESS_URL=https://alvmoral.42.fr
WORDPRESS_ADMIN_USER=wp_owner
WORDPRESS_USER=wp_user
```

Do not store passwords directly in `.env`.

Create the required secret files locally:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/credentials.txt
```

Make sure `secrets/` is ignored by Git.

### Build and start

From the repository root:

```sh
make
```

Typical Makefile targets:

```sh
make          # Build and start the project
make up       # Start the stack
make down     # Stop containers
make clean    # Stop containers and remove non-persistent objects
make fclean   # Full cleanup, including volumes if implemented that way
make re       # Rebuild from scratch
```

The exact behavior depends on the implementation of the Makefile, but the default target should set up the whole application using `srcs/docker-compose.yml`.

### Check the stack

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps
```

Useful checks:

```sh
docker ps

docker logs nginx

docker logs wordpress

docker logs mariadb

curl -kI https://alvmoral.42.fr
```

### Access the website

Open:

```text
https://alvmoral.42.fr
```

WordPress administration panel:

```text
https://alvmoral.42.fr/wp-admin
```

Optional bonus routes may include:

```text
https://alvmoral.42.fr/adminer
https://alvmoral.42.fr/portainer
```

The exact route depends on the NGINX configuration and enabled bonus services.

## Credentials

Credentials must be kept outside the Git repository.

Recommended layout:

```text
secrets/
├── credentials.txt
├── db_password.txt
└── db_root_password.txt
```

The files should contain only the secret value needed by the corresponding service. They are mounted into containers and read by entrypoint scripts.

Never commit real passwords, API keys, database dumps, TLS private keys, or generated credentials.

## Useful commands

### Containers

```sh
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps

docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs nginx

docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs wordpress

docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs mariadb
```

### Volumes

```sh
docker volume ls

docker volume inspect srcs_mariadb

docker volume inspect srcs_wordpress
```

Volume names may differ depending on the Compose project name.

### Network

```sh
docker network ls

docker network inspect srcs_inception
```

Network names may differ depending on the Compose project name.

### TLS

```sh
openssl s_client -connect alvmoral.42.fr:443 -tls1_2

openssl s_client -connect alvmoral.42.fr:443 -tls1_3
```

These commands are useful to verify that the HTTPS endpoint accepts TLSv1.2 and/or TLSv1.3.

## Resources

Classic references used to understand and build this project:

- Docker documentation: containers, images, volumes, networks, Dockerfile instructions, and Compose files.
- Docker Compose documentation: service definitions, named volumes, networks, secrets, and restart policies.
- NGINX documentation: server blocks, TLS configuration, reverse proxying, FastCGI, and static file serving.
- WordPress documentation: installation, `wp-config.php`, database configuration, administration panel, and WP-CLI usage.
- PHP-FPM documentation: FastCGI process manager configuration and pool settings.
- MariaDB documentation: database initialization, users, grants, bind address, and service startup.
- OpenSSL documentation: self-signed certificates and TLS testing.
- 42 Inception subject: project constraints, mandatory services, bonus services, and validation documentation requirements.

### AI usage

AI was used as a documentation assistant for this project. More specifically, it helped with:

- Organizing the documentation structure.
- Drafting explanations of Docker concepts in plain English.
- Comparing related concepts such as virtual machines vs Docker, secrets vs environment variables, Docker networks vs host networking, and volumes vs bind mounts.
- Producing checklists and command examples for users and developers.
- Reviewing possible troubleshooting sections.

AI was not used as a substitute for understanding the project. All generated explanations, commands, and design descriptions must be reviewed, tested, and understood by the project author before submission or defense.

## Defense notes

Important points to be able to explain during evaluation:

- A container is not a virtual machine.
- PID 1 matters inside containers.
- Containers should run a real foreground process, not `tail -f`, `sleep infinity`, `bash`, or `while true` loops.
- Each service has its own image and container.
- The mandatory stack exposes only NGINX on port `443`.
- WordPress connects to MariaDB through the Docker network.
- MariaDB and WordPress data persist through named volumes.
- Passwords must not be present in Dockerfiles or committed files.
- The `latest` tag must not be used.
- `network: host`, `--link`, and Compose `links:` are forbidden.
