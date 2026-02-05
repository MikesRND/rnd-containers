HOLOSCAN_VER    ?= 3.11.0
_HOLO_TAG       := holo$(HOLOSCAN_VER)
HOLOHUB_TAG     ?= holohub-ano-$(_HOLO_TAG)

IMAGE_NAME           := ano-dev$(if $(_HOLO_TAG),-$(_HOLO_TAG),)
COMPOSE_SERVICE      := ano-dev
COMPOSE_BUILD_TARGET :=

# Pass version info into Docker build for MOTD
DOCKER_BUILD_ARGS = \
    --build-arg BASE_IMAGE=$(HOLOHUB_TAG)-dpdk \
    --build-arg CONTAINER_VERSION=$(VER_SEMVER) \
    --build-arg GIT_COMMIT=$(VER_GIT_COMMIT) \
    --build-arg HOLOSCAN_VER=$(HOLOSCAN_VER) \
    --build-arg CUDA_VER=$(CUDA_VER)

include ../../mk/docker-build.mk
include ../../mk/docker-compose.mk

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "ano-dev Container"
	@echo ""
	@echo "  docker-build   Build image"
	@echo "  docker-clean   Remove local images"
	@echo "  docker-tags    Print image tags (CI)"
	@echo "  docker-labels  Print OCI labels (CI)"
	@echo ""
	@echo "  compose-up     Start container (run docker-build first if needed)"
	@echo "  compose-down   Stop container"
	@echo "  compose-shell  Shell into container"
	@echo "  compose-logs   Follow logs"
	@echo ""
	@echo "  version-info   Show version"
