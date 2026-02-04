# rnd-containers Makefile — Layer-0 + Layer-1 build automation

# ── Configuration ────────────────────────────────────────────
REGISTRY    ?=
PROJECT     ?= ano
CUDA_VER    ?= 12.6
CUDA_PATCH  ?= 12.6.3
CUDA_FLAVOR ?= base
UBUNTU_VER  ?= 22

# Upstream NVIDIA CUDA image
BASE_IMAGE ?= nvcr.io/nvidia/cuda:$(CUDA_PATCH)-$(CUDA_FLAVOR)-ubuntu$(UBUNTU_VER).04

# Registry prefix: normalize trailing slash (works with or without user-supplied slash)
_REG := $(if $(REGISTRY),$(patsubst %/,%,$(REGISTRY))/,)

# Flavor suffix: empty for base, -devel or -runtime otherwise
_FLAVOR := $(if $(filter base,$(CUDA_FLAVOR)),,-$(CUDA_FLAVOR))

# Version tag component shared by local and push names: cuda12.6-ubu22[-devel]
_VTAG := cuda$(CUDA_VER)-ubu$(UBUNTU_VER)$(_FLAVOR)

# ── Local image tags (flat, for docker images | grep) ────────
BASE_TAG    ?= base-$(_VTAG)
HOLOHUB_TAG ?= holohub-$(PROJECT)

# ──────────────────────────────────────────────────────────────
.PHONY: all base holohub-dpdk holohub-gpunetio holohub-rivermax \
        ano-dev clean help

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
		-t $(HOLOHUB_TAG)-dpdk \
		-f containers/ano/holohub/Dockerfile \
		containers/ano/holohub/

holohub-gpunetio: base ## Build holohub with gpunetio target
	docker build \
		--build-arg BASE_TAG=$(BASE_TAG) \
		--target gpunetio \
		-t $(HOLOHUB_TAG)-gpunetio \
		-f containers/ano/holohub/Dockerfile \
		containers/ano/holohub/

holohub-rivermax: base ## Build holohub with rivermax target
	docker build \
		--build-arg BASE_TAG=$(BASE_TAG) \
		--target rivermax \
		-t $(HOLOHUB_TAG)-rivermax \
		-f containers/ano/holohub/Dockerfile \
		containers/ano/holohub/

ano-dev: holohub-dpdk ## Build ano-dev container
	$(MAKE) -C containers/ano-dev docker-build

# ── Utilities ────────────────────────────────────────────────
clean: ## Remove built images
	docker rmi -f $(BASE_TAG) \
		$(HOLOHUB_TAG)-dpdk \
		$(HOLOHUB_TAG)-gpunetio \
		$(HOLOHUB_TAG)-rivermax 2>/dev/null || true
	$(MAKE) -C containers/ano-dev docker-clean 2>/dev/null || true

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
