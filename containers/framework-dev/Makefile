# framework-dev — final dev layer of the DAQIRI-only stack.
#
# Unlike ano-dev, this layer is Holoscan-free: no HOLOSCAN_VER guard and no
# holo* tag suffix. The public, versioned image is plain "framework-dev".
# Heavy pins (DAQIRI_REF, DPDK_VERSION, DOCA_VERSION, MATX_REF, CUDA_ARCHS)
# live in the framework-sdk layer, not here.

IMAGE_NAME      := framework-dev
COMPOSE_SERVICE := framework-dev

# SDK base image; exported by the top-level Makefile, with a safe default.
FRAMEWORK_SDK_TAG ?= framework-sdk

# This layer only consumes the SDK base image plus version metadata.
DOCKER_BUILD_ARGS = \
    --build-arg BASE_IMAGE=$(FRAMEWORK_SDK_TAG) \
    --build-arg CONTAINER_VERSION=$(VER_SEMVER) \
    --build-arg GIT_COMMIT=$(VER_GIT_COMMIT)

include ../../mk/docker-build.mk
include ../../mk/docker-compose.mk
include ../../mk/docker-release.mk

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "framework-dev Container (DAQIRI-only)"
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
	@echo "  docker-release-arch  Build+push this host's arch tag (run on amd64 and arm64)"
	@echo "  docker-manifest      Assemble+push multi-arch manifest from per-arch tags"
	@echo ""
	@echo "  version-info   Show version"
