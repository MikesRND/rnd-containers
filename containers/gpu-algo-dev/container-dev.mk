# Container image build and release helpers
#
# Tagging Strategy:
# - Development builds: IMAGE_NAME:VERSION-COMMIT_HASH (e.g., mikesrnd/gpu-algo-dev:0.0.5-abc1234)
# - Production builds: IMAGE_NAME:VERSION and IMAGE_NAME:latest (only on main branch)
# - Latest tag is ONLY applied when merging to main branch via CI/CD
#
# Version information is centralized in version.mk (shared with CMake builds)
include version.mk

# Docker-specific configuration
IMAGE_NAME ?= mikesrnd/gpu-algo-dev
BUILD_SOURCE ?= local
IMAGE_TAG := $(VER_VERSION_FULL)
BUILD_TIME_ISO8601 := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

.PHONY: container-dev-help container-build container-tag-latest container-release container-clean container-version container-login version-docker-tags version-docker-labels

container-dev-help:
	@echo "Container Build & Publish Commands:"
	@echo "  container-build         - Build container with VERSION-COMMIT and SEMVER tags"
	@echo "  container-tag-latest    - Tag existing build as :latest (for CI/CD only)"
	@echo "  container-release       - Tag and push to Docker Hub (requires clean main branch)"
	@echo "  container-clean         - Remove local images"
	@echo "  container-version       - Show current version info"
	@echo "  container-login         - Login to Docker Hub"
	@echo ""
	@echo "Docker Version Targets (for CI/CD):"
	@echo "  version-docker-tags     - Print comma-separated Docker tags"
	@echo "  version-docker-labels   - Print Docker OCI labels"
	@echo ""
	@echo "Current build will tag as: $(IMAGE_NAME):$(IMAGE_TAG) and $(IMAGE_NAME):$(VER_SEMVER)"

container-build:
	@echo "Building container image: $(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "  SEMVER: $(VER_SEMVER)"
	@echo "  Commit: $(VER_GIT_COMMIT)"
	@echo "  Branch: $(VER_GIT_BRANCH)"
	docker build \
		--build-arg BUILD_SOURCE=$(BUILD_SOURCE) \
		--build-arg BUILD_TIME=$(BUILD_TIME_ISO8601) \
		--label "org.opencontainers.image.version=$(VER_SEMVER)" \
		--label "org.opencontainers.image.revision=$(VER_GIT_COMMIT)" \
		--label "org.opencontainers.image.created=$(BUILD_TIME_ISO8601)" \
		--label "org.opencontainers.image.source=https://github.com/MikesRND/rnd-containers" \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		-t $(IMAGE_NAME):$(VER_SEMVER) \
		.
	@echo "Build complete: $(IMAGE_NAME):$(IMAGE_TAG)"

container-tag-latest: container-build
	@echo "Tagging $(IMAGE_NAME):$(IMAGE_TAG) as :latest (CI/CD use only)"
	@echo "WARNING: This should only be used in CI/CD pipelines!"
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):latest
	@echo "Tagged as: $(IMAGE_NAME):latest"

container-release: container-build
	@if [ "$(VER_GIT_BRANCH)" != "main" ]; then \
		echo "ERROR: Releases can only be made from main branch"; \
		echo "Current branch: $(VER_GIT_BRANCH)"; \
		exit 1; \
	fi
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "ERROR: Working directory is not clean"; \
		echo "Commit or stash your changes before releasing"; \
		exit 1; \
	fi
	@echo "Pushing tags: $(VER_SEMVER)-$(VER_GIT_COMMIT) and $(VER_SEMVER)"
	docker push $(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(IMAGE_NAME):$(VER_SEMVER)
	@echo "Release complete!"
	@echo "Images available at:"
	@echo "  - docker.io/$(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "  - docker.io/$(IMAGE_NAME):$(VER_SEMVER)"
	@echo ""
	@echo "NOTE: :latest tag is only pushed via CI/CD on main branch"

container-clean:
	@echo "Removing local images..."
	-docker rmi $(IMAGE_NAME):latest 2>/dev/null
	-docker rmi $(IMAGE_NAME):$(VER_SEMVER) 2>/dev/null
	-docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null
	@echo "Clean complete"

container-version: version-info
	@echo "  IMAGE_TAG:    $(IMAGE_TAG)"

# Docker-specific version targets for CI/CD
version-docker-tags:
	@echo "$(IMAGE_NAME):$(IMAGE_TAG),$(IMAGE_NAME):$(VER_SEMVER)"

version-docker-tags-with-latest:
	@echo "$(IMAGE_NAME):$(IMAGE_TAG),$(IMAGE_NAME):$(VER_SEMVER),$(IMAGE_NAME):latest"

version-docker-labels:
	@echo "org.opencontainers.image.version=$(VER_SEMVER)"
	@echo "org.opencontainers.image.revision=$(VER_GIT_COMMIT)"
	@echo "org.opencontainers.image.created=$(BUILD_TIME_ISO8601)"
	@echo "org.opencontainers.image.source=https://github.com/MikesRND/rnd-containers"

container-login:
	@echo "Logging in to Docker Hub as mikesrnd"
	docker login -u mikesrnd