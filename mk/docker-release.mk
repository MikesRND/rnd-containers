# mk/docker-release.mk - arch-suffixed release helpers (native or cross-build)
#
# Include AFTER mk/docker-build.mk (needs IMAGE_FULL, IMAGE_TAG, IMAGE_SOURCE,
# DOCKER_BUILD_ARGS, and the VER_* vars).
#
# Model: build ONE platform at a time, tag it arch-suffixed, and push that. By
# default ARCH is the host arch (native build). Set ARCH=arm64 on an amd64 host
# to cross-build via QEMU — this is how the offline DGX Spark / GB10 (arm64)
# image is produced from the amd64 workstation. The build uses `docker buildx
# build --platform linux/$(ARCH) --load` on the DEFAULT buildx builder, which IS
# the host daemon: it reuses the daemon's corporate CA/proxy trust (a
# docker-container builder does not) and can see local images, so the base->sdk
# ->dev chain resolves FROM local arch-suffixed tags without a registry.
#
# CUDA itself is never recompiled — only our framework-sdk work (DAQIRI nvcc +
# DPDK source build) runs emulated under QEMU.
#
# An optional docker-manifest step can later assemble a consumer-facing multi-
# arch tag from per-arch tags, once a host of each arch has pushed.
#
# Release runbook:
#   native:      make <stack>-release-arch                 # pushes :<ver>-<host arch>
#   cross-build: make <stack>-release-arch ARCH=arm64      # pushes :<ver>-arm64
#   manifest:    make <stack>-manifest                     # assembles :<ver>
#
# Tag scheme (IMAGE_FULL = e.g. docker.io/mikesrnd/framework-dev):
#   per-arch (pushed):                :<full>-amd64  :<semver>-amd64  (+ arm64)
#   multi-arch manifest (consumers):  :<full>        :<semver>
#
# Release tags are NEVER pushed as :latest — consumers pin explicit version
# tags. (Local docker-build may still tag :latest locally; it is never pushed.)

# Map the build host machine to a docker arch name.
_UNAME_M  := $(shell uname -m)
HOST_ARCH ?= $(if $(filter aarch64 arm64,$(_UNAME_M)),arm64,$(if $(filter x86_64 amd64,$(_UNAME_M)),amd64,$(_UNAME_M)))

# Arch to build/tag/push. Defaults to the host arch (native); override to
# arm64 on an amd64 host to cross-build via QEMU.
ARCH ?= $(HOST_ARCH)

# Platforms expected to compose the multi-arch manifest.
RELEASE_PLATFORMS ?= amd64 arm64

.PHONY: docker-build-arch docker-push-arch docker-release-arch docker-manifest

# Build $(ARCH) with arch-suffixed versioned tags. Uses buildx on the default
# builder with --load so the result lands in the local image store (and chains
# FROM local images); --platform makes ARCH=arm64 cross-build under QEMU.
docker-build-arch:
	@echo "Building $(IMAGE_FULL):$(VER_SEMVER)-$(ARCH) (platform: linux/$(ARCH))"
	docker buildx build \
		--platform linux/$(ARCH) --load \
		$(DOCKER_BUILD_ARGS) \
		--label "org.opencontainers.image.version=$(VER_SEMVER)" \
		--label "org.opencontainers.image.revision=$(VER_GIT_COMMIT)" \
		--label "org.opencontainers.image.source=$(IMAGE_SOURCE)" \
		-t $(IMAGE_FULL):$(IMAGE_TAG)-$(ARCH) \
		-t $(IMAGE_FULL):$(VER_SEMVER)-$(ARCH) \
		.

docker-push-arch:
	docker push $(IMAGE_FULL):$(IMAGE_TAG)-$(ARCH)
	docker push $(IMAGE_FULL):$(VER_SEMVER)-$(ARCH)

docker-release-arch: docker-build-arch docker-push-arch

# Assemble the consumer-facing multi-arch manifest from the per-arch tags.
# Run only after docker-release-arch has completed on every RELEASE_PLATFORMS host.
docker-manifest:
	docker buildx imagetools create \
		-t $(IMAGE_FULL):$(VER_SEMVER) \
		-t $(IMAGE_FULL):$(IMAGE_TAG) \
		$(foreach p,$(RELEASE_PLATFORMS),$(IMAGE_FULL):$(VER_SEMVER)-$(p))
