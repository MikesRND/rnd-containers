# Container image build and release helpers
#
# Tagging Strategy:
# - Development builds: IMAGE_FULL:VERSION-COMMIT_HASH (e.g., mikesrnd/gpu-algo-dev:0.0.5-abc1234)
# - Production builds: IMAGE_FULL:VERSION and IMAGE_FULL:latest (only on main branch)
# - Latest tag is ONLY applied when merging to main branch via CI/CD
#
# Version information is centralized in version.mk (shared with CMake builds)
include version.mk

# Docker registry and image configuration
REGISTRY ?= docker.io
IMAGE_NAMESPACE ?= mikesrnd
IMAGE_NAME ?= gpu-algo-dev
IMAGE_FULL := $(REGISTRY)/$(IMAGE_NAMESPACE)/$(IMAGE_NAME)

# Build configuration
BUILD_SOURCE ?= local
IMAGE_TAG := $(VER_VERSION_FULL)
BUILD_TIME_ISO8601 := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

.PHONY: container-dev-help container-build container-tag-latest container-push-latest container-release container-clean container-version container-login container-tags container-labels

container-dev-help:
	@echo "Container Build & Publish Commands:"
	@echo "  container-build         - Build container with VERSION-COMMIT and SEMVER tags"
	@echo "  container-tag-latest    - Tag existing build as :latest (local only)"
	@echo "  container-push-latest   - Build, tag, and push :latest (manual override)"
	@echo "  container-release       - Tag and push to Docker Hub (requires clean main branch)"
	@echo "  container-clean         - Remove local images"
	@echo "  container-version       - Show current version info"
	@echo "  container-login         - Login to Docker Hub"
	@echo ""
	@echo "Docker Configuration:"
	@echo "  REGISTRY:        $(REGISTRY)"
	@echo "  IMAGE_NAMESPACE: $(IMAGE_NAMESPACE)"
	@echo "  IMAGE_NAME:      $(IMAGE_NAME)"
	@echo "  IMAGE_FULL:      $(IMAGE_FULL)"
	@echo ""
	@echo "Docker Version Targets (for CI/CD):"
	@echo "  container-tags          - Print comma-separated Docker tags"
	@echo "  container-labels        - Print Docker OCI labels"
	@echo ""
	@echo "Current build will tag as: $(IMAGE_FULL):$(IMAGE_TAG) and $(IMAGE_FULL):$(VER_SEMVER)"

container-build:
	@echo "Building container image: $(IMAGE_FULL):$(IMAGE_TAG)"
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
		-t $(IMAGE_FULL):$(IMAGE_TAG) \
		-t $(IMAGE_FULL):$(VER_SEMVER) \
		.
	@echo "Build complete: $(IMAGE_FULL):$(IMAGE_TAG)"

container-tag-latest: container-build
	@echo "Tagging $(IMAGE_FULL):$(IMAGE_TAG) as :latest (CI/CD use only)"
	@echo "WARNING: This should only be used in CI/CD pipelines!"
	docker tag $(IMAGE_FULL):$(IMAGE_TAG) $(IMAGE_FULL):latest
	@echo "Tagged as: $(IMAGE_FULL):latest"

container-push-latest: container-tag-latest
	@echo ""
	@echo "=========================================="
	@echo "WARNING: Manually pushing :latest tag!"
	@echo "=========================================="
	@echo "This bypasses CI/CD workflows."
	@echo "Use only for testing or emergency hotfixes."
	@echo ""
	@echo "Tags to be pushed:"
	@echo "  - $(IMAGE_FULL):$(IMAGE_TAG)"
	@echo "  - $(IMAGE_FULL):$(VER_SEMVER)"
	@echo "  - $(IMAGE_FULL):latest"
	@echo ""
	@read -p "Are you sure you want to push :latest? (yes/no): " confirm && \
	if [ "$$confirm" != "yes" ]; then \
		echo "Cancelled."; \
		exit 1; \
	fi
	@echo "Pushing all tags including :latest..."
	docker push $(IMAGE_FULL):$(IMAGE_TAG)
	docker push $(IMAGE_FULL):$(VER_SEMVER)
	docker push $(IMAGE_FULL):latest
	@echo ""
	@echo "Manual push complete!"
	@echo "Images available at:"
	@echo "  - $(IMAGE_FULL):$(IMAGE_TAG)"
	@echo "  - $(IMAGE_FULL):$(VER_SEMVER)"
	@echo "  - $(IMAGE_FULL):latest"

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
	docker push $(IMAGE_FULL):$(IMAGE_TAG)
	docker push $(IMAGE_FULL):$(VER_SEMVER)
	@echo "Release complete!"
	@echo "Images available at:"
	@echo "  - $(IMAGE_FULL):$(IMAGE_TAG)"
	@echo "  - $(IMAGE_FULL):$(VER_SEMVER)"
	@echo ""
	@echo "NOTE: :latest tag is only pushed via CI/CD on main branch"

container-clean:
	@echo "Removing local images..."
	-docker rmi $(IMAGE_FULL):latest 2>/dev/null
	-docker rmi $(IMAGE_FULL):$(VER_SEMVER) 2>/dev/null
	-docker rmi $(IMAGE_FULL):$(IMAGE_TAG) 2>/dev/null
	@echo "Clean complete"

container-version: version-info
	@echo "  IMAGE_TAG:    $(IMAGE_TAG)"
	@echo "  IMAGE_FULL:   $(IMAGE_FULL)"

# Docker-specific version targets for CI/CD
container-tags:
	@echo "$(IMAGE_FULL):$(IMAGE_TAG),$(IMAGE_FULL):$(VER_SEMVER)"

container-tags-with-latest:
	@echo "$(IMAGE_FULL):$(IMAGE_TAG),$(IMAGE_FULL):$(VER_SEMVER),$(IMAGE_FULL):latest"

container-labels:
	@echo "org.opencontainers.image.version=$(VER_SEMVER)"
	@echo "org.opencontainers.image.revision=$(VER_GIT_COMMIT)"
	@echo "org.opencontainers.image.created=$(BUILD_TIME_ISO8601)"
	@echo "org.opencontainers.image.source=https://github.com/MikesRND/rnd-containers"

container-login:
	@echo "Logging in to $(REGISTRY) as $(IMAGE_NAMESPACE)"
	docker login $(REGISTRY) -u $(IMAGE_NAMESPACE)