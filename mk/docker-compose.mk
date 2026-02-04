# mk/docker-compose.mk — Docker Compose lifecycle helpers
#
# Required (set before including):
#   COMPOSE_SERVICE     - docker compose service name (e.g., "ano-dev")
#
# Optional:
#   COMPOSE_FILE          - default: docker-compose.yml
#   COMPOSE_BUILD_TARGET  - if set (e.g., "docker-build"), compose-up runs build first
#                           and passes IMAGE_TAG so compose uses the freshly built tag.
#                           Default: empty (no auto-build).

COMPOSE_FILE ?= docker-compose.yml
COMPOSE_BUILD_TARGET ?=
_DC := docker compose -f $(COMPOSE_FILE)

.PHONY: compose-up compose-down compose-shell compose-shell-root compose-logs compose-restart

compose-up: $(COMPOSE_BUILD_TARGET)
	@USER_ID=$$(id -u) GROUP_ID=$$(id -g) USER=$${USER:-developer} IMAGE_TAG=$(IMAGE_TAG) $(_DC) up -d

compose-down:
	@USER_ID=$$(id -u) GROUP_ID=$$(id -g) $(_DC) down

compose-shell:
	@USER_ID=$$(id -u) GROUP_ID=$$(id -g) $(_DC) exec --user $$(id -u):$$(id -g) $(COMPOSE_SERVICE) bash

compose-shell-root:
	@USER_ID=$$(id -u) GROUP_ID=$$(id -g) $(_DC) exec $(COMPOSE_SERVICE) bash

compose-logs:
	@$(_DC) logs -f

compose-restart: compose-down compose-up
