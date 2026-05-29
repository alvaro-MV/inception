COMPOSE_CONFIG_PATH = ./srcs/docker-compose.yml

up:
	docker compose --file $(COMPOSE_CONFIG_PATH) up -d

down:
	docker compose --file $(COMPOSE_CONFIG_PATH) down

up-%:
	docker compose --file $(COMPOSE_CONFIG_PATH) up -d $*

down-%:
	docker compose --file $(COMPOSE_CONFIG_PATH) down $*

build:
	docker compose --file $(COMPOSE_CONFIG_PATH) build

build-%:
	docker compose --file $(COMPOSE_CONFIG_PATH) build $*

upb:
	docker compose --file $(COMPOSE_CONFIG_PATH) up -d --build

upb-%:
	docker compose --file $(COMPOSE_CONFIG_PATH) up -d --build $*

clean:
	docker compose --file $(COMPOSE_CONFIG_PATH) clean

stop:
	docker compose --file $(COMPOSE_CONFIG_PATH) stop

ps:
	docker compose --file $(COMPOSE_CONFIG_PATH) ps

restart:
	docker compose --file $(COMPOSE_CONFIG_PATH) restart

.PHONY: up, clean, stop, restart, ps