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

# ── CUDA development toolchain ────────────────────────────
# Guard: fail fast if CUDA_VER was not passed via --build-arg.
ARG CUDA_VER
RUN test -n "${CUDA_VER}" || { echo "ERROR: CUDA_VER build-arg is required"; exit 1; } \
    && CUDA_APT_SUFFIX=$(echo "${CUDA_VER}" | tr '.' '-') \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        cuda-toolkit-${CUDA_APT_SUFFIX} \
    && rm -rf /var/lib/apt/lists/* \
    && nvcc --version | grep -q "release ${CUDA_VER}" \
    || { echo "ERROR: nvcc version does not match CUDA_VER=${CUDA_VER}"; exit 1; }

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
# Guard: fail fast if HOLOSCAN_VER was not passed via --build-arg.
ARG HOLOSCAN_VER
RUN test -n "${HOLOSCAN_VER}" || { echo "ERROR: HOLOSCAN_VER build-arg is required"; exit 1; } \
    && mkdir -p /workspace \
    && cd /workspace \
    && git clone --branch holoscan-sdk-${HOLOSCAN_VER} --depth 1 \
        https://github.com/nvidia-holoscan/holohub.git \
    && chmod +x /workspace/holohub/holohub \
    && /workspace/holohub/holohub setup \
    && echo ". /etc/bash_completion.d/holohub_autocomplete" >> /etc/bash.bashrc

ENV HOLOSCAN_INPUT_PATH=/workspace/holohub/data

# ── mlnx-dpdk + ANO operator (ConnectX-7 / H200 support) ─
# mlnx-dpdk-dev is pinned implicitly by DOCA_VERSION (3.2.1) configured in layer 1.
# --allow-downgrades handles possible libibverbs version differences from layer 1.
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-downgrades \
        mlnx-dpdk-dev \
    && rm -rf /var/lib/apt/lists/*

# Ensure pkg-config finds mlnx-dpdk (installed to /opt/mellanox/dpdk/)
ENV PKG_CONFIG_PATH="/opt/mellanox/dpdk/lib/x86_64-linux-gnu/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

# Build holoscan-networking package from HoloHub (DPDK backend).
# Top-level build generates CMake export targets (holoscan-networkingConfig.cmake)
# so downstream projects can use find_package(holoscan-networking).
# Installs libs, headers, cmake configs, and example apps to /opt/nvidia/holoscan/.
RUN cd /workspace/holohub \
    && cmake -B build \
        -DPKG_holoscan-networking=ON \
        -DANO_MGR=dpdk \
        -DCMAKE_BUILD_TYPE=Release \
        -DHOLOHUB_BUILD_PYTHON=OFF \
        -DHOLOHUB_DOWNLOAD_DATASETS=OFF \
        -DBUILD_TESTING=OFF \
    && cmake --build build -j$(nproc) \
    && cmake --install build --prefix /opt/nvidia/holoscan \
    && rm -rf build

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
        -DCMAKE_CUDA_ARCHITECTURES="80;86;89;90" \
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

# ── ccache environment ────────────────────────────────────
ENV CCACHE_DIR=/workspace/.ccache
ENV CMAKE_C_COMPILER_LAUNCHER=ccache
ENV CMAKE_CXX_COMPILER_LAUNCHER=ccache
ENV CMAKE_CUDA_COMPILER_LAUNCHER=ccache
