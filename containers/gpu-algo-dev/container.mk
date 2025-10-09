# Lightweight container helpers for user workflows
#
# =============================================================================
# CONFIGURE FOR YOUR PROJECT
#   Update DOCKER_COMPOSE_FILE to point to your docker-compose.yml file
#   Update DOCKER_SERVICE_NAME to the service name in your docker-compose.yml
# =============================================================================
DOCKER_COMPOSE_FILE ?= docker-compose.yml
DOCKER_SERVICE_NAME ?= gpu-algo-dev
# =============================================================================


DOCKER_COMPOSE ?= docker compose -f $(DOCKER_COMPOSE_FILE)

.PHONY: container-help container-pull container-up container-down container-shell container-shell-root container-logs container-restart

container-help:
	@echo "Container Management Commands:"
	@echo "  container-pull       - Pull the latest Docker image"
	@echo "  container-up         - Start the container"
	@echo "  container-down       - Stop and remove the container"
	@echo "  container-shell      - Open interactive shell in running container (as user)"
	@echo "  container-shell-root - Open interactive shell in running container (as root)"
	@echo "  container-logs       - Show container logs"
	@echo "  container-restart    - Stop and start container"

container-pull:
	@USER_ID=$$(id -u) GROUP_ID=$$(id -g) $(DOCKER_COMPOSE) pull

container-up:
	@USER_ID=$$(id -u) GROUP_ID=$$(id -g) USER=$${USER:-developer} $(DOCKER_COMPOSE) up -d

container-down:
	@USER_ID=$$(id -u) GROUP_ID=$$(id -g) $(DOCKER_COMPOSE) down

container-shell:
	@USER_ID=$$(id -u) GROUP_ID=$$(id -g) $(DOCKER_COMPOSE) exec --user $$(id -u):$$(id -g) $(DOCKER_SERVICE_NAME) bash

container-shell-root:
	@USER_ID=$$(id -u) GROUP_ID=$$(id -g) $(DOCKER_COMPOSE) exec $(DOCKER_SERVICE_NAME) bash

container-logs:
	@$(DOCKER_COMPOSE) logs -f

container-restart: container-down container-up
