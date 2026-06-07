# mk/docker-release.mk - multi-arch release helpers (per-host build + manifest)
#
# Include AFTER mk/docker-build.mk (needs IMAGE_FULL, IMAGE_TAG, IMAGE_SOURCE,
# DOCKER_BUILD_ARGS, and the VER_* vars).
#
# Model: a layered image chain (base -> sdk -> dev) cannot be cross-built for
# multiple platforms in one `buildx --platform` invocation, and QEMU emulation
# of a CUDA/DPDK build is impractical. So each platform is built NATIVELY on
# its own host and pushed under an arch-suffixed tag; a final manifest step
# assembles the consumer-facing multi-arch tags from those per-arch tags.
#
# Release runbook:
#   on an amd64 host:  make <stack>-release-arch   # pushes :<ver>-amd64
#   on an arm64 host:  make <stack>-release-arch   # pushes :<ver>-arm64
#   on either host:    make <stack>-manifest       # assembles :<ver>, :latest
#
# Tag scheme (IMAGE_FULL = e.g. docker.io/mikesrnd/framework-dev):
#   per-arch (intermediate, pushed):  :<full>-amd64  :<semver>-amd64  (+ arm64)
#   multi-arch manifest (consumers):  :<full>        :<semver>        :latest

# Map the build host machine to a docker arch name.
_UNAME_M  := $(shell uname -m)
HOST_ARCH ?= $(if $(filter aarch64 arm64,$(_UNAME_M)),arm64,$(if $(filter x86_64 amd64,$(_UNAME_M)),amd64,$(_UNAME_M)))

# Platforms expected to compose the multi-arch manifest.
RELEASE_PLATFORMS ?= amd64 arm64

.PHONY: docker-build-arch docker-push-arch docker-release-arch docker-manifest

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
		-t $(IMAGE_FULL):latest \
		$(foreach p,$(RELEASE_PLATFORMS),$(IMAGE_FULL):$(VER_SEMVER)-$(p))
