# syntax=docker/dockerfile:1
ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

LABEL description="ANO development container"

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

# Version info (injected at build time)
ARG CONTAINER_VERSION=dev
ARG GIT_COMMIT=unknown
ARG HOLOSCAN_VER=3.6.0
ARG CUDA_VER=12.6

ENV CONTAINER_VERSION=${CONTAINER_VERSION} \
    GIT_COMMIT=${GIT_COMMIT}

# Ensure /workspace exists (base image may not provide it)
RUN mkdir -p /workspace

# Workspace mapping: /mnt/current_folder → /workspace/<repo> symlink at container start
COPY scripts/setup_workspace_mapping.sh /setup_workspace_mapping.sh
RUN chmod +x /setup_workspace_mapping.sh && mkdir -p /etc/entrypoint.d \
    && { echo '#!/bin/bash'; \
         echo 'source /setup_workspace_mapping.sh'; \
         echo 'setup_workspace_mapping || true'; \
       } > /etc/entrypoint.d/10-workspace-mapping.sh \
    && chmod +x /etc/entrypoint.d/10-workspace-mapping.sh

# ── Python 3.11 toolchain (system 3.10 stays untouched) ───
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3.11 python3.11-venv python3.11-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Venv: vrtigo (/opt/venv/vrtigo) ──────────────────────
RUN python3.11 -m venv /opt/venv/vrtigo \
    && cd /workspace \
    && git clone --branch main --depth 1 https://github.com/MikesRND/vrtigo.git \
    && /opt/venv/vrtigo/bin/pip install --no-cache-dir \
        -e /workspace/vrtigo/bindings/python \
        holoscan-cli pytest PyQt6 pyqtgraph scipy setuptools mkdocs

# ── Venv activation helpers ──────────────────────────────
# use-vrtigo: activate vrtigo venv
RUN { echo '#!/bin/bash'; \
      echo '# Usage: source use-vrtigo (or ". use-vrtigo")'; \
      echo 'source /opt/venv/vrtigo/bin/activate'; \
    } > /usr/local/bin/use-vrtigo \
    && chmod +x /usr/local/bin/use-vrtigo

# ── Auto-activate venv (Python 3.11 becomes default python/pip) ──
ENV VIRTUAL_ENV=/opt/venv/vrtigo
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# ── CUDA development toolchain ────────────────────────────
# CUDA apt repo is already configured by upstream cuda:*-base image.
# Install the full toolkit to match what gpu-algo-dev gets from the
# holoscan:*-cuda12-dgpu base (which ships the CUDA devel layer).
# CUDA_VER (e.g. "12.6") → apt suffix "12-6".
ARG CUDA_VER
RUN CUDA_APT_SUFFIX=$(echo "${CUDA_VER}" | tr '.' '-') \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        cuda-toolkit-${CUDA_APT_SUFFIX} \
    && rm -rf /var/lib/apt/lists/* \
    && nvcc --version | grep -q "release ${CUDA_VER}" \
    || { echo "ERROR: nvcc version does not match CUDA_VER=${CUDA_VER}"; exit 1; }

ENV CUDA_HOME=/usr/local/cuda
ENV PATH="${CUDA_HOME}/bin:$PATH"

# ── Development tools + C++ libraries ─────────────────────
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        vim wget \
        clang-format clang-tidy lcov ccache \
        doxygen graphviz \
        libboost-all-dev libpoco-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Holohub clone + setup + system deps ───────────────────
# NOTE: The venv is auto-activated via ENV above, so all pip installs
# (including anything holohub setup runs internally) land in the
# Python 3.11 venv, not system Python 3.10. This is intentional.
RUN cd /workspace \
    && git clone --branch holoscan-sdk-${HOLOSCAN_VER} --depth 1 \
        https://github.com/nvidia-holoscan/holohub.git \
    && chmod +x /workspace/holohub/holohub \
    && /workspace/holohub/holohub setup \
    && echo ". /etc/bash_completion.d/holohub_autocomplete" >> /etc/bash.bashrc

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        pkg-config \
        libgstreamer1.0-0 \
        libgstreamer-plugins-base1.0-0 \
        libgles2 \
        libopengl0 \
        libcairo2-dev \
        libgirepository1.0-dev \
        gobject-introspection \
        libgtk-3-dev \
        libcanberra-gtk-module \
        openjdk-21-jre \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
        -r /workspace/holohub/benchmarks/holoscan_flow_benchmarking/requirements.txt

ENV HOLOSCAN_INPUT_PATH=/workspace/holohub/data

RUN echo 'export JREHOME=$(readlink /etc/alternatives/java | sed -e "s/\/bin\/java//")' >> /etc/bash.bashrc

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

# MOTD version banner (values baked at build time via double-quoted echo)
# - /etc/profile.d/ covers login shells (entrypoint su -)
# - /etc/bash.bashrc covers non-login interactive shells (docker exec bash)
# - _CONTAINER_MOTD_SHOWN guard prevents double-display
RUN { echo '# Container version banner'; \
      echo 'if [ -z "${_CONTAINER_MOTD_SHOWN:-}" ]; then'; \
      echo '    export _CONTAINER_MOTD_SHOWN=1'; \
      echo '    echo ""'; \
      echo "    echo \"  ano-dev ${CONTAINER_VERSION} (${GIT_COMMIT})\""; \
      echo '    echo ""'; \
      echo 'fi'; \
    } > /etc/profile.d/01-container-motd.sh \
    && chmod +x /etc/profile.d/01-container-motd.sh \
    && printf '\n# Container MOTD for non-login interactive shells\nif [ -n "${PS1:-}" ]; then\n    . /etc/profile.d/01-container-motd.sh\nfi\n' \
      >> /etc/bash.bashrc

WORKDIR /workspace
CMD ["bash"]
