# mk/docker-build.mk — Docker image build with versioned tags and OCI labels
#
# Required (set before including):
#   IMAGE_NAME          - e.g., "ano-dev"
#
# Optional (set before including):
#   REGISTRY            - default: docker.io
#   IMAGE_NAMESPACE     - Docker namespace/org
#   DOCKER_BUILD_ARGS   - extra --build-arg flags (default: empty)
#
# Provides targets:
#   docker-build, docker-clean, docker-tags, docker-tags-with-latest, docker-labels

include $(dir $(lastword $(MAKEFILE_LIST)))version.mk

REGISTRY        ?= docker.io
IMAGE_NAMESPACE ?= mikesrnd
IMAGE_SOURCE    ?= https://github.com/$(IMAGE_NAMESPACE)/rnd-containers
_REG_PREFIX     := $(if $(REGISTRY),$(patsubst %/,%,$(REGISTRY))/,)
IMAGE_FULL      := $(_REG_PREFIX)$(IMAGE_NAMESPACE)/$(IMAGE_NAME)
IMAGE_TAG       := $(VER_VERSION_FULL)
DOCKER_BUILD_ARGS ?=

.PHONY: docker-build docker-clean docker-tags docker-tags-with-latest docker-labels

docker-build:
	@echo "Building $(IMAGE_FULL):$(IMAGE_TAG)"
	docker build \
		$(DOCKER_BUILD_ARGS) \
		--label "org.opencontainers.image.version=$(VER_SEMVER)" \
		--label "org.opencontainers.image.revision=$(VER_GIT_COMMIT)" \
		--label "org.opencontainers.image.source=$(IMAGE_SOURCE)" \
		-t $(IMAGE_FULL):$(IMAGE_TAG) \
		-t $(IMAGE_FULL):$(VER_SEMVER) \
		-t $(IMAGE_FULL):latest \
		.
	@echo "Built: $(IMAGE_FULL):$(IMAGE_TAG)"

docker-clean:
	-docker rmi $(IMAGE_FULL):latest 2>/dev/null
	-docker rmi $(IMAGE_FULL):$(VER_SEMVER) 2>/dev/null
	-docker rmi $(IMAGE_FULL):$(IMAGE_TAG) 2>/dev/null

docker-tags:
	@echo "$(IMAGE_FULL):$(IMAGE_TAG),$(IMAGE_FULL):$(VER_SEMVER)"

docker-tags-with-latest:
	@echo "$(IMAGE_FULL):$(IMAGE_TAG),$(IMAGE_FULL):$(VER_SEMVER),$(IMAGE_FULL):latest"

docker-labels:
	@echo "org.opencontainers.image.version=$(VER_SEMVER)"
	@echo "org.opencontainers.image.revision=$(VER_GIT_COMMIT)"
	@echo "org.opencontainers.image.source=$(IMAGE_SOURCE)"
