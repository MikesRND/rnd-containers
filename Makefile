# rnd-containers Makefile — Layer-0 + Layer-1 build automation

# ── Persistent build config (optional) ──────────────────────
-include config.mk

# ── Configuration ────────────────────────────────────────────
HOLOSCAN_VER    ?= 3.11.0
REGISTRY        ?= docker.io
IMAGE_NAMESPACE ?= mikesrnd
IMAGE_SOURCE    ?= https://github.com/$(IMAGE_NAMESPACE)/rnd-containers
PROJECT         ?= ano
CUDA_PATCH      ?= 12.9.1
CUDA_VER        := $(word 1,$(subst ., ,$(CUDA_PATCH))).$(word 2,$(subst ., ,$(CUDA_PATCH)))
CUDA_FLAVOR     ?= devel
CUDA_ARCHS      ?= all
UBUNTU_VER      ?= 22

_HOLO_TAG   := holo$(HOLOSCAN_VER)

# Upstream NVIDIA CUDA image
BASE_IMAGE ?= nvcr.io/nvidia/cuda:$(CUDA_PATCH)-$(CUDA_FLAVOR)-ubuntu$(UBUNTU_VER).04

# Registry prefix: normalize trailing slash (works with or without user-supplied slash)
_REG := $(if $(REGISTRY),$(patsubst %/,%,$(REGISTRY))/,)

# Flavor suffix: empty for base, -devel or -runtime otherwise
_FLAVOR := $(if $(filter base,$(CUDA_FLAVOR)),,-$(CUDA_FLAVOR))

# Version tag component shared by local and push names: cuda12.6-ubu22[-devel]
_VTAG := cuda$(CUDA_VER)-ubu$(UBUNTU_VER)$(_FLAVOR)

# ── Local image tags (flat, for docker images | grep) ────────
BASE_TAG      ?= base-$(_VTAG)
HOLOHUB_TAG   ?= holohub-$(PROJECT)-$(_HOLO_TAG)
ANO_TOOLS_TAG ?= ano-tools-$(_HOLO_TAG)

# Export variables for the ano-dev sub-make
export HOLOSCAN_VER
export _HOLO_TAG
export HOLOHUB_TAG
export ANO_TOOLS_TAG
export CUDA_VER
export CUDA_ARCHS
export REGISTRY
export IMAGE_NAMESPACE
export IMAGE_SOURCE

# Version vars (VER_SEMVER / VER_VERSION_FULL / VER_GIT_COMMIT) for the
# framework release tags. Track the framework-dev image version so top-level
# release tags match what the framework-dev sub-make produces. Must precede the
# framework vars/targets that reference VER_*.
VERSION_FILE := containers/framework-dev/VERSION
include mk/version.mk

# ── Framework (DAQIRI-only, Holoscan-free) stack ─────────────
# Independent of the ANO/HoloHub layers above. Targets the DAQIRI-aligned
# CUDA 13.1 / Ubuntu 24.04 platform and mirrors DAQIRI's DPDK/DOCA/DAQIRI
# build. FRAMEWORK_CUDA_ARCHS is a stack-level knob (separate from the
# legacy CUDA_ARCHS) mapped to the Docker CUDA_ARCHS build-arg.
FRAMEWORK_BASE_IMAGE ?= nvcr.io/nvidia/cuda:13.1.0-devel-ubuntu24.04
FRAMEWORK_BASE_TAG   ?= framework-base-cuda13.1-ubu24-devel
FRAMEWORK_SDK_TAG    ?= framework-sdk

# Default device-code targets: native (real) SASS for exactly the deployment
# fleet, so every target GPU loads a precompiled cubin (no JIT, no reliance on
# minor-version forward compatibility).
#
#   arch      compute cap   GPUs
#   --------  -----------   ----------------------------------------------
#   89-real   sm_89         RTX 2000 Ada (Ada Lovelace)
#   90-real   sm_90         H200 NVL (Hopper)
#   120-real  sm_120        RTX 5060 (this host), RTX PRO 2000 Blackwell
#   121-real  sm_121        DGX Spark / GB10 (Blackwell)
#
# Build speed: nvcc compiles every kernel once PER arch, so this 4-arch list
# is ~3x less device compilation (and much less RAM) than the ~12-arch CUDA
# 13.1 `all`. Override for wider coverage at the cost of build time/size, e.g.
#   make framework-dev FRAMEWORK_CUDA_ARCHS=all
# (Adding/removing a GPU family? edit the list to match its compute cap.)
FRAMEWORK_CUDA_ARCHS ?= 89-real;90-real;120-real;121-real

# DAQIRI / DPDK / DOCA / MatX pins (consumed by framework-sdk).
# NOTE: DAQIRI_REF is co-versioned with DPDK_VERSION and the mirrored SDK
# Dockerfile block; bumping it requires re-syncing that block. See
# containers/framework-sdk/Dockerfile.
DAQIRI_REPO   ?= https://github.com/NVIDIA/daqiri.git
DAQIRI_REF    ?= a89bd4aa54dd217c97eeef903569aec998568f5c
DPDK_VERSION  ?= 25.11
DOCA_VERSION  ?= 3.2.1
# v0.9.4 matches the MatX version bundled in Holoscan (ano stack) — keep the
# two stacks on the same MatX release. See ano-dev /opt/nvidia/holoscan/NOTICE.
MATX_REF      ?= v0.9.4

# ── buildx/QEMU release registry tags (single-host multi-arch path) ──────────
# Registry-qualified reference images for the pushed base/SDK layers. A
# multi-arch buildx runs on the docker-container driver and resolves FROM
# per-arch from a registry, so each layer is pushed before the next builds on it.
FRAMEWORK_BASE_RELEASE_IMAGE ?= $(_REG)$(IMAGE_NAMESPACE)/framework-base
FRAMEWORK_SDK_RELEASE_IMAGE  ?= $(_REG)$(IMAGE_NAMESPACE)/framework-sdk
# Stable reference tag the SDK builds FROM (decoupled from the dev semver).
FRAMEWORK_BASE_RELEASE_TAG   ?= cuda13.1-ubu24-devel-base1
# Deliberate literal SDK version. Bump whenever ANY SDK input changes:
# FRAMEWORK_BASE_RELEASE_TAG, DAQIRI_REF, DPDK_VERSION, DOCA_VERSION, MATX_REF,
# FRAMEWORK_CUDA_ARCHS, FRAMEWORK_ARM64_CUDA_ARCHS (lean arm64 SDK), or
# containers/framework-sdk/Dockerfile. (Use `make framework-sdk-version`.)
FRAMEWORK_SDK_VERSION        ?= 0.1.0-sdk1
FRAMEWORK_SDK_REF            ?= $(FRAMEWORK_SDK_RELEASE_IMAGE):$(FRAMEWORK_SDK_VERSION)         # multi-arch SDK (both-arch dev)
FRAMEWORK_SDK_REF_ARM64      ?= $(FRAMEWORK_SDK_RELEASE_IMAGE):$(FRAMEWORK_SDK_VERSION)-arm64   # lean arm64 SDK (Spark dev)
# Spark-lean default device archs for the arm64-only SDK (GB10 only). Override
# for a wider (non-Spark) arm64 SDK.
FRAMEWORK_ARM64_CUDA_ARCHS   ?= 121-real
BUILDX_PLATFORMS             ?= linux/amd64,linux/arm64
BUILDX_BUILDER               ?= framework-builder

# Export for the framework-dev sub-make (only the SDK base tag is needed).
export FRAMEWORK_SDK_TAG

# ──────────────────────────────────────────────────────────────
.PHONY: all base holohub-dpdk holohub-gpunetio holohub-rivermax \
        ano-tools ano-dev framework-base framework-sdk framework-dev \
        framework-release-arch framework-manifest \
        framework-buildx-setup framework-base-release-multiarch \
        framework-sdk-release-multiarch framework-sdk-release-arm64 \
        framework-release-multiarch framework-release-arm64 \
        framework-release-amd64 framework-stack-release-multiarch \
        framework-sdk-version \
        clean help configure show-config

all: base holohub-dpdk ## Build layer-0 + layer-1 dpdk (default)

# ── Build targets ────────────────────────────────────────────
base: ## Build layer-0 base image
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		-t $(BASE_TAG) \
		-f containers/base/Dockerfile .

holohub-dpdk: base ## Build holohub with dpdk (default target)
	docker build \
		--build-arg BASE_TAG=$(BASE_TAG) \
		--build-arg HOLOSCAN_DEB_REMOTE_VERSION=$(HOLOSCAN_VER) \
		-t $(HOLOHUB_TAG)-dpdk \
		-f containers/ano/holohub/Dockerfile \
		containers/ano/holohub/

holohub-gpunetio: base ## Build holohub with gpunetio target
	docker build \
		--build-arg BASE_TAG=$(BASE_TAG) \
		--build-arg HOLOSCAN_DEB_REMOTE_VERSION=$(HOLOSCAN_VER) \
		--target gpunetio \
		-t $(HOLOHUB_TAG)-gpunetio \
		-f containers/ano/holohub/Dockerfile \
		containers/ano/holohub/

holohub-rivermax: base ## Build holohub with rivermax target
	docker build \
		--build-arg BASE_TAG=$(BASE_TAG) \
		--build-arg HOLOSCAN_DEB_REMOTE_VERSION=$(HOLOSCAN_VER) \
		--target rivermax \
		-t $(HOLOHUB_TAG)-rivermax \
		-f containers/ano/holohub/Dockerfile \
		containers/ano/holohub/

ano-tools: holohub-dpdk ## Build layer-2 SDK image
	docker build \
		--build-arg BASE_IMAGE=$(HOLOHUB_TAG)-dpdk \
		--build-arg HOLOSCAN_VER=$(HOLOSCAN_VER) \
		--build-arg CUDA_VER=$(CUDA_VER) \
		--build-arg CUDA_ARCHS="$(CUDA_ARCHS)" \
		-t $(ANO_TOOLS_TAG) \
		-f containers/ano-tools/Dockerfile \
		containers/ano-tools/

ano-dev: ano-tools ## Build ano-dev container
	$(MAKE) -C containers/ano-dev docker-build

# ── Framework (DAQIRI-only) build chain ──────────────────────
framework-base: ## Build framework layer-0 base (certs/entrypoint, CUDA 13.1/ubu24)
	docker build \
		--build-arg BASE_IMAGE=$(FRAMEWORK_BASE_IMAGE) \
		-t $(FRAMEWORK_BASE_TAG) \
		-f containers/base/Dockerfile .

framework-sdk: framework-base ## Build framework SDK layer (DPDK/DOCA/DAQIRI/MatX + C++ libs)
	docker build \
		--build-arg BASE_IMAGE=$(FRAMEWORK_BASE_TAG) \
		--build-arg CUDA_ARCHS="$(FRAMEWORK_CUDA_ARCHS)" \
		--build-arg DAQIRI_REPO=$(DAQIRI_REPO) \
		--build-arg DAQIRI_REF=$(DAQIRI_REF) \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
		--build-arg DOCA_VERSION=$(DOCA_VERSION) \
		--build-arg MATX_REF=$(MATX_REF) \
		-t $(FRAMEWORK_SDK_TAG) \
		-f containers/framework-sdk/Dockerfile \
		containers/framework-sdk/

framework-dev: framework-sdk ## Build framework-dev container (DAQIRI-only, Holoscan-free)
	$(MAKE) -C containers/framework-dev docker-build

# Multi-arch release: build natively on each platform host, then assemble a
# manifest. amd64 (Spark/GB10 is arm64) and arm64 are built on their own hosts.
framework-release-arch: framework-sdk ## Build+push this host's arch image (run on amd64 AND arm64 hosts)
	$(MAKE) -C containers/framework-dev docker-release-arch

framework-manifest: ## Assemble+push the multi-arch manifest (after release-arch on all hosts)
	$(MAKE) -C containers/framework-dev docker-manifest

# ── buildx/QEMU single-host multi-arch release ───────────────
# Cross-build arm64 (and amd64) from one host under QEMU, for offline targets
# like the DGX Spark/GB10. The pinned base+SDK are built+pushed once per SDK pin
# change (heavy under emulation); routine dev releases only rebuild the thin
# framework-dev layer on top of the pushed SDK.
framework-buildx-setup: ## Install QEMU emulators + ensure the buildx builder exists (idempotent)
	docker run --privileged --rm tonistiigi/binfmt --install all
	docker buildx inspect $(BUILDX_BUILDER) >/dev/null 2>&1 || \
		docker buildx create --name $(BUILDX_BUILDER) --driver docker-container
	docker buildx inspect $(BUILDX_BUILDER) --bootstrap
# Note (WSL2): binfmt_misc registration may not survive a Docker/WSL restart —
# re-run this target if cross-arch builds suddenly fail to start.

framework-base-release-multiarch: ## buildx build+push multi-arch framework-base reference tag
	@printf '%s\n' '$(BUILDX_PLATFORMS)' | grep -q ',' || { echo "ERROR: $@ needs multi-arch BUILDX_PLATFORMS (got '$(BUILDX_PLATFORMS)'); use a -arch target for a single arch"; exit 1; }
	docker buildx build \
		--builder $(BUILDX_BUILDER) \
		--platform $(BUILDX_PLATFORMS) \
		--build-arg BASE_IMAGE=$(FRAMEWORK_BASE_IMAGE) \
		--label "org.opencontainers.image.version=$(VER_SEMVER)" \
		--label "org.opencontainers.image.revision=$(VER_GIT_COMMIT)" \
		--label "org.opencontainers.image.source=$(IMAGE_SOURCE)" \
		-t $(FRAMEWORK_BASE_RELEASE_IMAGE):$(FRAMEWORK_BASE_RELEASE_TAG) \
		-t $(FRAMEWORK_BASE_RELEASE_IMAGE):$(VER_VERSION_FULL) \
		--push \
		-f containers/base/Dockerfile .

framework-sdk-release-multiarch: ## buildx build+push BOTH-arch SDK (heavy: emulated nvcc+DPDK)
	@printf '%s\n' '$(BUILDX_PLATFORMS)' | grep -q ',' || { echo "ERROR: $@ needs multi-arch BUILDX_PLATFORMS (got '$(BUILDX_PLATFORMS)'); use a -arch target for a single arch"; exit 1; }
	docker buildx build \
		--builder $(BUILDX_BUILDER) \
		--platform $(BUILDX_PLATFORMS) \
		--build-arg BASE_IMAGE=$(FRAMEWORK_BASE_RELEASE_IMAGE):$(FRAMEWORK_BASE_RELEASE_TAG) \
		--build-arg CUDA_ARCHS="$(FRAMEWORK_CUDA_ARCHS)" \
		--build-arg DAQIRI_REPO=$(DAQIRI_REPO) \
		--build-arg DAQIRI_REF=$(DAQIRI_REF) \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
		--build-arg DOCA_VERSION=$(DOCA_VERSION) \
		--build-arg MATX_REF=$(MATX_REF) \
		--label "org.opencontainers.image.version=$(VER_SEMVER)" \
		--label "org.opencontainers.image.revision=$(VER_GIT_COMMIT)" \
		--label "org.opencontainers.image.source=$(IMAGE_SOURCE)" \
		-t $(FRAMEWORK_SDK_RELEASE_IMAGE):$(FRAMEWORK_SDK_VERSION) \
		-t $(FRAMEWORK_SDK_RELEASE_IMAGE):$(VER_VERSION_FULL)-sdk \
		--push \
		-f containers/framework-sdk/Dockerfile containers/framework-sdk/

framework-sdk-release-arm64: ## buildx build+push Spark-lean arm64-only SDK (GB10 archs by default)
	docker buildx build \
		--builder $(BUILDX_BUILDER) \
		--platform linux/arm64 \
		--build-arg BASE_IMAGE=$(FRAMEWORK_BASE_RELEASE_IMAGE):$(FRAMEWORK_BASE_RELEASE_TAG) \
		--build-arg CUDA_ARCHS="$(FRAMEWORK_ARM64_CUDA_ARCHS)" \
		--build-arg DAQIRI_REPO=$(DAQIRI_REPO) \
		--build-arg DAQIRI_REF=$(DAQIRI_REF) \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
		--build-arg DOCA_VERSION=$(DOCA_VERSION) \
		--build-arg MATX_REF=$(MATX_REF) \
		--label "org.opencontainers.image.version=$(VER_SEMVER)" \
		--label "org.opencontainers.image.revision=$(VER_GIT_COMMIT)" \
		--label "org.opencontainers.image.source=$(IMAGE_SOURCE)" \
		-t $(FRAMEWORK_SDK_RELEASE_IMAGE):$(FRAMEWORK_SDK_VERSION)-arm64 \
		--push \
		-f containers/framework-sdk/Dockerfile containers/framework-sdk/

framework-release-multiarch: ## Routine both-arch dev release on the multi-arch SDK (fast)
	$(MAKE) -C containers/framework-dev docker-release-multiarch \
		BASE_IMAGE_MULTIARCH=$(FRAMEWORK_SDK_REF) \
		BUILDX_PLATFORMS=$(BUILDX_PLATFORMS) \
		BUILDX_BUILDER=$(BUILDX_BUILDER)

framework-release-arm64: ## Spark arm64 dev release (defaults to the lean arm64 SDK)
	$(MAKE) -C containers/framework-dev docker-release-multiarch-arch \
		BUILDX_PLATFORM=linux/arm64 ARCH=arm64 \
		BASE_IMAGE_MULTIARCH=$(FRAMEWORK_SDK_REF_ARM64) \
		BUILDX_BUILDER=$(BUILDX_BUILDER)

framework-release-amd64: ## amd64-only dev release on the multi-arch SDK
	$(MAKE) -C containers/framework-dev docker-release-multiarch-arch \
		BUILDX_PLATFORM=linux/amd64 ARCH=amd64 \
		BASE_IMAGE_MULTIARCH=$(FRAMEWORK_SDK_REF) \
		BUILDX_BUILDER=$(BUILDX_BUILDER)

framework-stack-release-multiarch: ## Deliberate full both-arch refresh: base -> sdk -> dev (ordered)
	$(MAKE) framework-base-release-multiarch
	$(MAKE) framework-sdk-release-multiarch
	$(MAKE) framework-release-multiarch

framework-sdk-version: ## Print the SDK pin set (bump FRAMEWORK_SDK_VERSION when any of these change)
	@echo "FRAMEWORK_SDK_VERSION=$(FRAMEWORK_SDK_VERSION)"
	@echo "FRAMEWORK_BASE_RELEASE_TAG=$(FRAMEWORK_BASE_RELEASE_TAG)"
	@echo "DAQIRI_REF=$(DAQIRI_REF)"
	@echo "DPDK_VERSION=$(DPDK_VERSION)"
	@echo "DOCA_VERSION=$(DOCA_VERSION)"
	@echo "MATX_REF=$(MATX_REF)"
	@echo "FRAMEWORK_CUDA_ARCHS=$(FRAMEWORK_CUDA_ARCHS)"
	@echo "FRAMEWORK_ARM64_CUDA_ARCHS=$(FRAMEWORK_ARM64_CUDA_ARCHS)"

# ── Utilities ────────────────────────────────────────────────
clean: ## Remove built images
	docker rmi -f $(BASE_TAG) \
		$(HOLOHUB_TAG)-dpdk \
		$(HOLOHUB_TAG)-gpunetio \
		$(HOLOHUB_TAG)-rivermax \
		$(ANO_TOOLS_TAG) 2>/dev/null || true
	$(MAKE) -C containers/ano-dev docker-clean 2>/dev/null || true

configure: ## Persist build settings to config.mk
	@echo "# Generated by: make configure" > config.mk
	@echo "HOLOSCAN_VER    := $(HOLOSCAN_VER)"    >> config.mk
	@echo "REGISTRY        := $(REGISTRY)"        >> config.mk
	@echo "IMAGE_NAMESPACE := $(IMAGE_NAMESPACE)" >> config.mk
	@echo "IMAGE_SOURCE    := $(IMAGE_SOURCE)"    >> config.mk
	@echo "CUDA_PATCH      := $(CUDA_PATCH)"      >> config.mk
	@echo "CUDA_ARCHS      := $(CUDA_ARCHS)"      >> config.mk
	@echo "Saved config.mk"

show-config: ## Print effective build settings
	@echo "Effective build configuration:"
	@echo "  HOLOSCAN_VER    = $(HOLOSCAN_VER)"
	@echo "  _HOLO_TAG       = $(_HOLO_TAG)"
	@echo "  REGISTRY        = $(REGISTRY)"
	@echo "  IMAGE_NAMESPACE = $(IMAGE_NAMESPACE)"
	@echo "  IMAGE_SOURCE    = $(IMAGE_SOURCE)"
	@echo "  HOLOHUB_TAG     = $(HOLOHUB_TAG)"
	@echo "  ANO_TOOLS_TAG   = $(ANO_TOOLS_TAG)"
	@echo "  BASE_IMAGE      = $(BASE_IMAGE)"
	@echo "  CUDA_VER        = $(CUDA_VER)"
	@echo "  BASE_TAG        = $(BASE_TAG)"
	@echo "  CUDA_ARCHS      = $(CUDA_ARCHS)"
	@echo "  --- framework (DAQIRI-only) ---"
	@echo "  FRAMEWORK_BASE_IMAGE = $(FRAMEWORK_BASE_IMAGE)"
	@echo "  FRAMEWORK_BASE_TAG   = $(FRAMEWORK_BASE_TAG)"
	@echo "  FRAMEWORK_SDK_TAG    = $(FRAMEWORK_SDK_TAG)"
	@echo "  FRAMEWORK_CUDA_ARCHS = $(FRAMEWORK_CUDA_ARCHS)"
	@echo "  DAQIRI_REF           = $(DAQIRI_REF)"
	@echo "  DPDK_VERSION         = $(DPDK_VERSION)"
	@echo "  DOCA_VERSION         = $(DOCA_VERSION)"
	@echo "  MATX_REF             = $(MATX_REF)"

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
