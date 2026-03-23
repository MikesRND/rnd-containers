# syntax=docker/dockerfile:1
ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

LABEL description="ANO SDK/toolchain layer (compilers, CUDA toolkit, C++ libraries)"

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

# ── Python 3.12 toolchain (system 3.10 stays untouched) ───
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Venv: vrtigo (/opt/venv/vrtigo) ──────────────────────
# Create the venv and auto-activate it via ENV so all subsequent
# pip installs (including holohub setup) land here, not system Python.
RUN python3.12 -m venv /opt/venv/vrtigo

ENV VIRTUAL_ENV=/opt/venv/vrtigo
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# SDK/dev pip packages (project-specific packages are installed in Layer 3)
RUN pip install --no-cache-dir holoscan-cli pytest setuptools

# ── CUDA development toolchain (provided by devel base image) ─
ARG CUDA_ARCHS
RUN test -n "${CUDA_ARCHS}" || { echo "ERROR: CUDA_ARCHS build-arg is required"; exit 1; }

ENV CUDA_HOME=/usr/local/cuda
ENV PATH="${CUDA_HOME}/bin:$PATH"

# ── GCC 13 toolchain (C++20 <format> support) ────────────
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gcc-13 g++-13 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 130 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-13 \
    && rm -rf /var/lib/apt/lists/*

# ── Development tools + C++ libraries ─────────────────────
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        vim \
        wget \
        gdb \
        clang-format \
        clang-tidy \
        lcov \
        ccache \
        doxygen \
        graphviz \
        libboost-all-dev \
        libpoco-dev \
        libyaml-cpp-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Holohub clone + setup + system deps ───────────────────
# NOTE: The venv is auto-activated via ENV above, so all pip installs
# (including anything holohub setup runs internally) land in the
# Python 3.12 venv, not system Python 3.10. This is intentional.
# Guard: fail fast if HOLOSCAN_VER / CUDA_VER were not passed via --build-arg.
ARG HOLOSCAN_VER
ARG CUDA_VER
# Pin libnvinfer-safe-headers-dev to match what holohub setup will select.
# Without this, apt prefers a newer +cuda13.x build from the same repo,
# which breaks libnvinfer-dev's exact-version dependency.
# Match on CUDA major line (e.g. +cuda12.) so the pin stays aligned with
# upstream even if NVIDIA publishes newer 12.x TensorRT builds.
RUN test -n "${HOLOSCAN_VER}" || { echo "ERROR: HOLOSCAN_VER build-arg is required"; exit 1; } \
    && test -n "${CUDA_VER}" || { echo "ERROR: CUDA_VER build-arg is required"; exit 1; } \
    && mkdir -p /workspace \
    && CUDA_MAJOR="$(echo "${CUDA_VER}" | cut -d. -f1)" \
    && apt-get update \
    && apt-cache madison libnvinfer10 > /tmp/nvinfer_madison.txt \
    && TRT_VER="$(grep -m1 -F "+cuda${CUDA_MAJOR}." /tmp/nvinfer_madison.txt \
        | cut -d'|' -f2 | tr -d ' ')" \
    && rm -f /tmp/nvinfer_madison.txt \
    && test -n "${TRT_VER}" \
       || { echo "ERROR: no libnvinfer10 version matching +cuda${CUDA_MAJOR}.*" >&2; \
            apt-cache madison libnvinfer10 >&2; exit 1; } \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-downgrades \
         "libnvinfer-safe-headers-dev=${TRT_VER}" \
    && cd /workspace \
    && git clone --branch holoscan-sdk-${HOLOSCAN_VER} --depth 1 \
        https://github.com/nvidia-holoscan/holohub.git \
    && chmod +x /workspace/holohub/holohub \
    && /workspace/holohub/holohub setup \
    && rm -rf /var/lib/apt/lists/* \
    && echo ". /etc/bash_completion.d/holohub_autocomplete" >> /etc/bash.bashrc

ENV HOLOSCAN_INPUT_PATH=/workspace/holohub/data

# ── ANO operator (ConnectX-7 / H200 support) ─────────────
# holoscan-networking links against upstream DPDK 24.11.3 built from
# source in Layer 1 (dpdk stage), installed to /usr/local.
# mlnx-dpdk-dev is NOT needed for the dpdk backend.

# Build holoscan-networking package and networking example apps from HoloHub.
# Top-level build generates CMake export targets (holoscan-networkingConfig.cmake)
# so downstream projects can use find_package(holoscan-networking).
# Installs libs, headers, cmake configs, and example apps to /opt/nvidia/holoscan/.
# Fix: adv_networking_bench hardcodes compute_70 which CUDA 13+ dropped.
RUN cd /workspace/holohub \
    && sed -i 's/set(CMAKE_CUDA_ARCHITECTURES "70;80;90")/set(CMAKE_CUDA_ARCHITECTURES "'"${CUDA_ARCHS}"'")/' \
        applications/adv_networking_bench/cpp/CMakeLists.txt \
    && cmake -B build \
        -DPKG_holoscan-networking=ON \
        -DAPP_adv_networking_bench=ON \
        -DAPP_basic_networking_ping=ON \
        -DANO_MGR=dpdk \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
        -DHOLOHUB_BUILD_PYTHON=OFF \
        -DHOLOHUB_DOWNLOAD_DATASETS=OFF \
        -DBUILD_TESTING=OFF \
    && cmake --build build -j$(nproc) \
    && mkdir -p build/python/lib/holohub \
    && cmake --install build --prefix /opt/nvidia/holoscan \
    && rm -rf build

# ── Holoscan-networking rebuild helper ──────────────────────
COPY scripts/rebuild-holoscan-networking.sh /usr/local/bin/rebuild-holoscan-networking
RUN chmod +x /usr/local/bin/rebuild-holoscan-networking

# ── Source builds (GTest, nvbench, spdlog, Taskflow) ──────
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
    # nvbench (pinned commit)
    && git clone https://github.com/NVIDIA/nvbench.git \
    && cd nvbench \
    && git checkout dc59f98ecd4a75b322be5f71b7ecf6b6c7c65a6f \
    && cmake -B build \
        -DNVBench_ENABLE_EXAMPLES=OFF \
        -DNVBench_ENABLE_TESTING=OFF \
        -DNVBench_ENABLE_CUPTI=OFF \
        -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_BUILD_TYPE=Release \
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

