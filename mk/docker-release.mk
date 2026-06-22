# mk/docker-release.mk - multi-arch release helpers
#
# Include AFTER mk/docker-build.mk (needs IMAGE_FULL, IMAGE_TAG, IMAGE_SOURCE,
# DOCKER_BUILD_ARGS, and the VER_* vars).
#
# Two supported release paths:
#
# 1. NATIVE per-host (docker-release-arch + docker-manifest). Each platform is
#    built natively on its own host with plain `docker build` and pushed under
#    an arch-suffixed tag; a final manifest step assembles the consumer-facing
#    multi-arch tag from those per-arch tags. Fastest when you have a host of
#    every target arch.
#
# 2. SINGLE-HOST buildx/QEMU (docker-release-multiarch[-arch]). One host cross-
#    builds other arches under QEMU emulation and pushes a multi-arch (or single
#    cross-built arch) image directly. Slower under emulation, but the only way
#    to produce an arm64 image from an amd64 host for an offline target (e.g. the
#    DGX Spark / GB10, which has no build-time internet). CUDA itself is never
#    recompiled — only our framework-sdk work (DAQIRI nvcc + DPDK source build)
#    runs emulated.
#
# Release runbook (native):
#   on an amd64 host:  make <stack>-release-arch   # pushes :<ver>-amd64
#   on an arm64 host:  make <stack>-release-arch   # pushes :<ver>-arm64
#   on either host:    make <stack>-manifest       # assembles :<ver>
#
# Tag scheme (IMAGE_FULL = e.g. docker.io/mikesrnd/framework-dev):
#   per-arch (intermediate, pushed):  :<full>-amd64  :<semver>-amd64  (+ arm64)
#   multi-arch manifest (consumers):  :<full>        :<semver>
#
# Release tags are NEVER pushed as :latest — consumers pin explicit version
# tags. (Local docker-build may still tag :latest locally; it is never pushed.)

# Map the build host machine to a docker arch name.
_UNAME_M  := $(shell uname -m)
HOST_ARCH ?= $(if $(filter aarch64 arm64,$(_UNAME_M)),arm64,$(if $(filter x86_64 amd64,$(_UNAME_M)),amd64,$(_UNAME_M)))

# Platforms expected to compose the multi-arch manifest.
RELEASE_PLATFORMS ?= amd64 arm64

# buildx/QEMU multi-arch defaults (overridable).
BUILDX_PLATFORMS ?= linux/amd64,linux/arm64
BUILDX_BUILDER   ?= framework-builder

.PHONY: docker-build-arch docker-push-arch docker-release-arch docker-manifest \
        docker-release-multiarch docker-release-multiarch-arch

# Build this host's native arch with arch-suffixed versioned tags.
docker-build-arch:
	@echo "Building $(IMAGE_FULL):$(VER_SEMVER)-$(HOST_ARCH) (host arch: $(HOST_ARCH))"
	docker build \
		$(DOCKER_BUILD_ARGS) \
		--label "org.opencontainers.image.version=$(VER_SEMVER)" \
		--label "org.opencontainers.image.revision=$(VER_GIT_COMMIT)" \
		--label "org.opencontainers.image.source=$(IMAGE_SOURCE)" \
		-t $(IMAGE_FULL):$(IMAGE_TAG)-$(HOST_ARCH) \
		-t $(IMAGE_FULL):$(VER_SEMVER)-$(HOST_ARCH) \
		.

docker-push-arch:
	docker push $(IMAGE_FULL):$(IMAGE_TAG)-$(HOST_ARCH)
	docker push $(IMAGE_FULL):$(VER_SEMVER)-$(HOST_ARCH)

docker-release-arch: docker-build-arch docker-push-arch

# Assemble the consumer-facing multi-arch manifest from the per-arch tags.
# Run only after docker-release-arch has completed on every RELEASE_PLATFORMS host.
docker-manifest:
	docker buildx imagetools create \
		-t $(IMAGE_FULL):$(VER_SEMVER) \
		-t $(IMAGE_FULL):$(IMAGE_TAG) \
		$(foreach p,$(RELEASE_PLATFORMS),$(IMAGE_FULL):$(VER_SEMVER)-$(p))

# ── buildx/QEMU single-host multi-arch release ───────────────────────────────
# Cross-build all BUILDX_PLATFORMS in one buildx invocation and push directly.
# Runs on the docker-container driver (set up via the stack's buildx-setup
# target); FROM is resolved per-arch from a registry, so the base/SDK this builds
# on top of must already be pushed as a multi-arch tag (see BASE_IMAGE_MULTIARCH
# in the consuming Makefile). Pushes clean version tags only — guard ensures the
# platform set really is multi-arch so single-arch content can't land on them.
docker-release-multiarch:
	@printf '%s\n' '$(BUILDX_PLATFORMS)' | grep -q ',' || { echo "ERROR: $@ needs multi-arch BUILDX_PLATFORMS (got '$(BUILDX_PLATFORMS)'); use a -arch target for a single arch"; exit 1; }
	docker buildx build \
		$(if $(BUILDX_BUILDER),--builder $(BUILDX_BUILDER),) \
		--platform $(BUILDX_PLATFORMS) \
		$(DOCKER_BUILD_ARGS) \
		--label "org.opencontainers.image.version=$(VER_SEMVER)" \
		--label "org.opencontainers.image.revision=$(VER_GIT_COMMIT)" \
		--label "org.opencontainers.image.source=$(IMAGE_SOURCE)" \
		-t $(IMAGE_FULL):$(IMAGE_TAG) \
		-t $(IMAGE_FULL):$(VER_SEMVER) \
		--push .

# Cross-build a SINGLE arch via buildx and push arch-suffixed tags only.
# Caller sets BUILDX_PLATFORM (e.g. linux/arm64) and ARCH (e.g. arm64).
docker-release-multiarch-arch:
	@test -n "$(BUILDX_PLATFORM)" || { echo "BUILDX_PLATFORM is required"; exit 1; }
	@test -n "$(ARCH)" || { echo "ARCH is required"; exit 1; }
	docker buildx build \
		$(if $(BUILDX_BUILDER),--builder $(BUILDX_BUILDER),) \
		--platform $(BUILDX_PLATFORM) \
		$(DOCKER_BUILD_ARGS) \
		--label "org.opencontainers.image.version=$(VER_SEMVER)" \
		--label "org.opencontainers.image.revision=$(VER_GIT_COMMIT)" \
		--label "org.opencontainers.image.source=$(IMAGE_SOURCE)" \
		-t $(IMAGE_FULL):$(IMAGE_TAG)-$(ARCH) \
		-t $(IMAGE_FULL):$(VER_SEMVER)-$(ARCH) \
		--push .
