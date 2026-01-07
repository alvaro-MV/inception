# 🐳 Inception – Dockerized WordPress Infrastructure

This project implements a **containerized web infrastructure** using **Docker and Docker Compose**, following the requirements of the **42 Inception project**.

The stack consists of:

* **Nginx** as a reverse proxy (**HTTPS only**)
* **WordPress** running with **PHP-FPM**
* **MariaDB** as the database backend
* **Persistent volumes** for database and WordPress files
* A custom **Docker network** for internal communication

All services are built from **custom Dockerfiles** (no pre-built images).

## 🧱 Architecture Overview

```
Browser (HTTPS 443)
        ↓
      NGINX
        ↓ FastCGI
   WordPress (PHP-FPM :9000)
        ↓
     MariaDB
```

### Key points

* Only **port 443** is exposed to the host
* Internal communication happens over a **Docker bridge network**
* PHP is executed **only** by PHP-FPM (not by Nginx)
* MariaDB is **not exposed** outside Docker
* TLS is enabled using **self-signed certificates**

## 📦 Services

### 🔐 Nginx

* Acts as HTTPS reverse proxy
* Handles TLS (TLSv1.2 / TLSv1.3)
* Forwards PHP requests to WordPress via FastCGI

### 📝 WordPress

* Runs on PHP 8.2 with PHP-FPM
* Connects to MariaDB using environment variables
* Files stored in a persistent volume

### 🗄️ MariaDB

* Custom initialization via entrypoint
* Database and user created automatically
* Data stored in a persistent volume

## 📁 Project Structure

```
srcs/
├── docker-compose.yml
├── .env
├── requirements/
│   ├── nginx/
│   │   ├── Dockerfile
│   │   ├── conf/nginx.conf
│   │   └── certs/
│   ├── wordpress/
│   │   ├── Dockerfile
│   │   └── conf/
│   │       ├── wp-config.php
│   │       └── www.conf
│   └── mariadb/
│       ├── Dockerfile
│       └── conf/
│           └── entrypoint.sh
```

## 🔐 TLS Certificates (Required)

This project uses **self-signed TLS certificates**, which are valid for the Inception project.

### 📍 Certificate location

Certificates must be placed in:

```
srcs/requirements/nginx/certs/
```

### 🛠️ Create certificates

Run the following command **from the root of the project**:

```bash
mkdir -p srcs/requirements/nginx/certs

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout srcs/requirements/nginx/certs/privkey.pem \
  -out srcs/requirements/nginx/certs/fullchain.pem \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=Inception/CN=login.42.fr"
```

⚠️ Browsers will warn about the certificate — this is expected.

## ⚙️ Environment Variables

The project uses a `.env` file to centralize configuration. Add one in the srcs/ directory. From now
on we consider that the .env file is the following one:

```env
COMPOSE_PROJECT_NAME=inception

DOMAIN_NAME=login.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=wp_password
MYSQL_ROOT_PASSWORD=root_password

MARIADB_VOLUME_PATH=/home/alvar/data/db
WORDPRESS_VOLUME_PATH=/home/alvar/data/wp

MYSQL_HOST=mariadb
```

## 🚀 How to Run the Project

### 1️⃣ Clone the repository

```bash
git clone <repository_url>
cd Inception/srcs
```

### 2️⃣ Prepare volumes (Linux / WSL2)

```bash
mkdir -p /home/alvar/data/db /home/alvar/data/wp
sudo chown -R 999:999 /home/alvar/data/db
sudo chown -R www-data:www-data /home/alvar/data/wp
```

### 3️⃣ Configure domain resolution

#### 🔹 Linux

Edit `/etc/hosts`:

```
127.0.0.1 login.42.fr
```

#### 🔹 Windows (WSL2)

Edit **as Administrator**:

```
C:\Windows\System32\drivers\etc\hosts
```

Add:

```
127.0.0.1 login.42.fr
```

### 4️⃣ Build and start containers

```bash
docker compose up --build
```

### 5️⃣ Access WordPress

Open your browser:

```
https://login.42.fr
```

Accept the certificate warning and complete the WordPress installation.

## 🧪 Useful Commands

```bash
# Show containers
docker ps

# Logs
docker compose logs mariadb
docker compose logs wordpress
docker compose logs nginx

# Enter containers
docker compose exec wordpress bash
docker compose exec mariadb mariadb -u wp_user -p wordpress
```

## 🧹 Reset WordPress (clean install)

```bash
docker compose down
sudo rm -rf /home/alvar/data/wp/*
docker compose up --build
```

This is acceptable during setup in Inception.

## 🛡️ Security Notes

* No credentials are hardcoded in images
* Secrets are passed via environment variables
* MariaDB is not exposed
* Nginx serves HTTPS only
* PHP execution is isolated to PHP-FPM

## ✅ Inception Compliance Checklist

* [x] Custom Dockerfiles only
* [x] No `latest` tags
* [x] TLS enabled
* [x] Only port 443 exposed
* [x] PHP-FPM used
* [x] Persistent volumes
* [x] Docker network isolation

## 🏁 Final Notes

This project is fully compliant with the **42 Inception subject** and demonstrates a clean, production-style Docker architecture.


Cosas a hacer:

- [1]  cambiar de logic.fr a alvmoral.fr

- [2]  poner el arbol de directorios como dice el subject 

- [3]  Hacer los 3 READMES que dice el subject

- [4]  EL Makefle

- [5]  wait en entrypoint.sh: esta bien?

- [6]  Los secretos de Docker: de que va la vaina.

- [7]  Que relacion existe entre el contenedor de nginx y el volume de wordpress? (Figura del subject)

- [8]  Ver si la version de debian es la correcta

- [9]  Explicar docker-network

- [10] docker volume inspect 

- [11] Crear dos usuarios en wordpress.