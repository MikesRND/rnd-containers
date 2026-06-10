# syntax=docker/dockerfile:1
#
# framework-sdk: heavy, cached SDK/toolchain layer for the DAQIRI-only
# (Holoscan-free) "framework-dev" container stack.
#
# Built FROM framework-base (this repo's certs/entrypoint base on a CUDA
# devel image). Owns all expensive, stable content: patched DPDK, DOCA/RDMA
# dependencies, DAQIRI, MatX, and the gpu-algorithms C++ library set. The
# thin framework-dev layer on top only adds dev conveniences, so editing it
# does not trigger a rebuild of this block.

ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

LABEL description="framework-dev SDK layer (patched DPDK, DOCA/RDMA, DAQIRI, MatX, C++ libs)"

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

# Make-level FRAMEWORK_CUDA_ARCHS is mapped to this Docker ARG by the
# top-level Makefile (--build-arg CUDA_ARCHS=$(FRAMEWORK_CUDA_ARCHS)).
# Every CUDA-compiled dependency below (e.g. DAQIRI) consumes it so a
# single knob controls the whole stack's device-code targets.
ARG CUDA_ARCHS
RUN test -n "${CUDA_ARCHS}" || { echo "ERROR: CUDA_ARCHS build-arg is required"; exit 1; }

# DAQIRI / DPDK / DOCA / MatX pins (defaults overridable via --build-arg).
ARG DAQIRI_REPO=https://github.com/MikesRND/daqiri.git
ARG DAQIRI_REF=bedf31ab707c4c66e644ed9a576baa7b7101d4de
ARG DPDK_VERSION=25.11
ARG DOCA_VERSION=3.2.1
ARG MATX_REF=v0.9.4
ARG DEBIAN_FRONTEND=noninteractive
# Auto-populated by BuildKit from --platform (amd64 on an x86 host, arm64 on
# Grace/SBSA). Drives the DOCA repo arch below (x86_64 vs arm64-sbsa). No
# default: do NOT pin it to amd64, or arm64 (DGX Spark / GB10) builds break.
ARG TARGETARCH

ENV CUDA_HOME=/usr/local/cuda
ENV PATH="${CUDA_HOME}/bin:${PATH}"

# =====================================================================
# BEGIN mirrored DAQIRI build block  ---  KEEP IN SYNC WITH UPSTREAM
# ---------------------------------------------------------------------
# Source of truth (pinned):
#   https://github.com/MikesRND/daqiri/blob/bedf31ab707c4c66e644ed9a576baa7b7101d4de/Dockerfile
#
# The package lists, DOCA repo wiring, DPDK build invocation (incl. the
# disable_drivers list and patch loop), and the DAQIRI cmake configure are
# reproduced from DAQIRI's multi-stage Dockerfile, flattened into a single
# stage on top of framework-base.
#
# Intentional, documented divergences from upstream:
#   1. DAQIRI source is `git clone`d at DAQIRI_REF rather than `COPY . .`,
#      because this repo is not the DAQIRI build context. The same clone
#      supplies dpdk_patches/ for the DPDK build.
#   2. DAQIRI's CMAKE_CUDA_ARCHITECTURES (upstream hardcodes all-major) is
#      overridden with the stack-wide ${CUDA_ARCHS} knob.
#   3. Optional upstream stages (rivermax, OpenTelemetry, python bindings)
#      are not mirrored; this stack builds the default dpdk+socket managers.
#   4. DPDK is configured with max_lcores=256 for larger CPU affinity sets.
#
# CONTRACT: changing DAQIRI_REF is NOT a free runtime override. It requires
# re-diffing this block against the Dockerfile at the new ref AND validating
# dpdk_patches/*.patch against the pinned DPDK_VERSION.
# =====================================================================

# ── DAQIRI "base" stage: system deps + recent CMake (kitware) ─────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        infiniband-diags \
        gnupg \
        python3-pip \
        git \
        build-essential \
        clang-format \
    && OS_CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME") \
    && KW_KEYRING="/usr/share/keyrings/kitware-archive-keyring.gpg" \
    && curl -fsSL "https://apt.kitware.com/keys/kitware-archive-latest.asc" \
        | gpg --dearmor -o "$KW_KEYRING" \
    && echo "deb [signed-by=$KW_KEYRING] https://apt.kitware.com/ubuntu/ $OS_CODENAME main" \
        > /etc/apt/sources.list.d/kitware.list \
    && apt-get update \
    && rm "$KW_KEYRING" \
    && CMAKE_VERSION="$(apt-cache madison cmake | awk '$3 ~ /^3[.]/ { print $3; exit }')" \
    && test -n "$CMAKE_VERSION" \
    && apt-get install --no-install-recommends -y \
        kitware-archive-keyring \
        "cmake=${CMAKE_VERSION}" \
        "cmake-data=${CMAKE_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# ── DAQIRI "base-deps" stage: DOCA repo + RDMA/ibverbs deps ───────────
WORKDIR /opt
RUN if [ "${TARGETARCH}" = "amd64" ]; then \
        DOCA_ARCH="x86_64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        DOCA_ARCH="arm64-sbsa"; \
    else \
        echo "Unknown architecture: $TARGETARCH"; \
        exit 1; \
    fi \
    && DISTRO=$(. /etc/os-release && echo ${ID}${VERSION_ID}) \
    && DOCA_REPO_LINK=https://linux.mellanox.com/public/repo/doca/${DOCA_VERSION}/${DISTRO}/${DOCA_ARCH} \
    && echo "Using DOCA_REPO_LINK=${DOCA_REPO_LINK}" \
    && LOCAL_GPG_KEY_PATH="/usr/share/keyrings/mellanox-archive-keyring.gpg" \
    && curl -fsSL ${DOCA_REPO_LINK}/GPG-KEY-Mellanox.pub | gpg --dearmor | tee ${LOCAL_GPG_KEY_PATH} > /dev/null \
    && echo "deb [signed-by=${LOCAL_GPG_KEY_PATH}] ${DOCA_REPO_LINK} ./" | tee /etc/apt/sources.list.d/mellanox.list

RUN apt-get update && apt-get install -y --no-install-recommends \
        libibverbs-dev \
        librdmacm-dev \
        libmlx5-1 \
        ibverbs-utils \
        python3-dev \
        pybind11-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --break-system-packages \
        pytest \
        pyyaml \
        scapy

# ── Clone DAQIRI at the pinned ref (supplies dpdk_patches + source) ───
RUN git clone "${DAQIRI_REPO}" /workspace/daqiri \
    && cd /workspace/daqiri \
    && git checkout "${DAQIRI_REF}" \
    && git submodule update --init --recursive

# ── DAQIRI "dpdk" stage: build patched upstream DPDK from source ──────
ARG DPDK_BUILD_DIR=/opt/dpdk-build
ARG DPDK_INSTALL_PREFIX=/usr/local

RUN apt-get update && apt-get install -y --no-install-recommends \
        ninja-build \
        pkgconf \
        meson \
        python3-pyelftools \
        libnuma-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://fast.dpdk.org/rel/dpdk-${DPDK_VERSION}.tar.xz -o /tmp/dpdk-${DPDK_VERSION}.tar.xz \
    && tar xf /tmp/dpdk-${DPDK_VERSION}.tar.xz -C /tmp \
    && cd /tmp/dpdk-${DPDK_VERSION} \
    && for patch in /workspace/daqiri/dpdk_patches/*.patch; do \
         patch_name="$(basename "${patch}")"; \
         echo "Applying DPDK patch: ${patch_name}"; \
         if [[ "${patch_name}" == "dmabuf.patch" ]]; then \
           git apply \
             --exclude=.mailmap \
             --exclude=doc/guides/rel_notes/release_26_03.rst \
             "${patch}"; \
         else \
           git apply "${patch}"; \
         fi; \
       done \
    && meson setup ${DPDK_BUILD_DIR} \
        --prefix=${DPDK_INSTALL_PREFIX} \
        -Dmax_lcores=256 \
        -Dtests=false \
        -Dplatform=generic \
        -Denable_docs=false \
        -Ddisable_drivers=baseband/*,bus/ifpga/*,common/cpt,common/dpaax,common/iavf,common/octeontx,common/octeontx2,crypto/nitrox,net/ark,net/atlantic,net/avp,net/axgbe,net/bnx2x,net/bnxt,net/cxgbe,net/e1000,net/ena,net/enic,net/fm10k,net/hinic,net/hns3,net/i40e,net/ixgbe,vdpa/ifc,net/igc,net/liquidio,net/mana,net/netvsc,net/nfp,net/qede,net/sfc,net/thunderx,net/vdev_netvsc,net/vmxnet3,regex/octeontx2 \
    && cd ${DPDK_BUILD_DIR} \
    && ninja \
    && meson install \
    && ldconfig \
    && rm -rf /tmp/dpdk-${DPDK_VERSION} /tmp/dpdk-${DPDK_VERSION}.tar.xz ${DPDK_BUILD_DIR}

# MLNX OFED utilities + firmware tools (DAQIRI dpdk stage tail).
RUN apt-get update && apt-get install -y --no-install-recommends \
        mlnx-ofed-kernel-utils \
        mft \
    && rm -rf /var/lib/apt/lists/*

# ── DAQIRI "daqiri-build" stage: configure/build/install to /opt/daqiri
# CUDA arch overridden with the stack-wide ${CUDA_ARCHS} (see divergence #2).
RUN cd /workspace/daqiri \
    && rm -rf build \
    && cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/daqiri \
        -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
        -DBUILD_SHARED_LIBS=ON \
        -DDAQIRI_BUILD_PYTHON=OFF \
        -DDAQIRI_ENABLE_OTEL_METRICS=OFF \
        -DDAQIRI_MGR="dpdk socket" \
    && cmake --build build -j "$(nproc)" \
    && cmake --install build \
    && rm -rf build

# =====================================================================
# END mirrored DAQIRI build block
# =====================================================================

# ── gpu-algorithms dev tooling + C++ libraries (NOT from DAQIRI) ──────
# CUDA math libraries (cublas/cufft/cusolver/curand) used by MatX are
# already present in the CUDA devel base image.
RUN apt-get update && apt-get install -y --no-install-recommends \
        vim \
        wget \
        gdb \
        clang-tidy \
        lcov \
        ccache \
        doxygen \
        graphviz \
        libboost-all-dev \
        libpoco-dev \
        libyaml-cpp-dev \
    && rm -rf /var/lib/apt/lists/*

# ── MatX (header-only; installs find_package(matx) CONFIG package) ────
RUN git clone --branch ${MATX_REF} --depth 1 https://github.com/NVIDIA/MatX.git /tmp/MatX \
    && cmake -S /tmp/MatX -B /tmp/MatX/build \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DMATX_BUILD_EXAMPLES=OFF \
        -DMATX_BUILD_TESTS=OFF \
        -DMATX_BUILD_BENCHMARKS=OFF \
        -DMATX_BUILD_DOCS=OFF \
    && cmake --install /tmp/MatX/build \
    && rm -rf /tmp/MatX

# ── Source builds: GTest, spdlog, Taskflow ───────────────────────────
RUN mkdir -p /tmp/builds \
    && cd /tmp/builds \
    \
    # GTest v1.17.0
    && git clone --branch v1.17.0 --depth 1 https://github.com/google/googletest.git \
    && cd googletest \
    && cmake -B build \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_GMOCK=ON \
        -DBUILD_SHARED_LIBS=OFF \
    && cmake --build build -j$(nproc) \
    && cmake --install build \
    && cd /tmp/builds \
    \
    # spdlog v1.x (header-only)
    && git clone --branch v1.x --depth 1 https://github.com/gabime/spdlog.git \
    && cp -r spdlog/include/spdlog /usr/local/include/ \
    \
    # Taskflow (master)
    && git clone --branch master --depth 1 https://github.com/taskflow/taskflow.git \
    && cd taskflow \
    && cmake -B build \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_BUILD_TYPE=Release \
        -DTF_BUILD_TESTS=OFF \
        -DTF_BUILD_EXAMPLES=OFF \
        -DTF_BUILD_BENCHMARKS=OFF \
    && cmake --build build -j$(nproc) \
    && cmake --install build \
    \
    # Cleanup
    && cd / \
    && rm -rf /tmp/builds

# ── Consumer search paths (DAQIRI + /usr/local installs) ─────────────
# DPDK (meson) installs its pkgconfig under the multiarch libdir, which is
# arch-specific (x86_64-linux-gnu on amd64, aarch64-linux-gnu on Grace/arm64).
# Both triplets are listed; a nonexistent dir is simply ignored.
ENV CMAKE_PREFIX_PATH=/opt/daqiri:/usr/local
ENV PKG_CONFIG_PATH=/opt/daqiri/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/aarch64-linux-gnu/pkgconfig
ENV LD_LIBRARY_PATH=/opt/daqiri/lib:/usr/local/lib:/usr/local/lib/x86_64-linux-gnu:/usr/local/lib/aarch64-linux-gnu

WORKDIR /workspace
CMD ["bash"]
