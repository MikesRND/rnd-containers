# NVIDIA Clara Holoscan GPU Development Container
# Based on NVIDIA Clara Holoscan SDK with GPU support for scientific computing
FROM nvcr.io/nvidia/clara-holoscan/holoscan:v3.6.0-dgpu

# Labels for Docker Hub
LABEL maintainer="mikesrnd"
LABEL description="GPU-accelerated development container"

# Copy entrypoint scripts
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/nvidia_entrypoint_no_exec.sh /opt/nvidia/nvidia_entrypoint_no_exec.sh
RUN chmod +x /entrypoint.sh /opt/nvidia/nvidia_entrypoint_no_exec.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# ----------------------------------------------------
# Certificate Handling
# ----------------------------------------------------
    
# Install any corporate certificates if they exist in container/certs
COPY certs /tmp/certs/
RUN if [ -n "$(find /tmp/certs -name '*.crt' -o -name '*.pem' -o -name '*.cer' 2>/dev/null | head -1)" ]; then \
        mkdir -p /usr/local/share/ca-certificates && \
        find /tmp/certs \( -name '*.crt' -o -name '*.pem' -o -name '*.cer' \) -exec cp {} /usr/local/share/ca-certificates/ \; && \
        update-ca-certificates && \
        echo "Corporate certificates installed: $(find /tmp/certs -name '*.crt' -o -name '*.pem' -o -name '*.cer' | wc -l) certificate(s)"; \
    else \
        echo "No corporate certificates to install"; \
    fi && \
    rm -rf /tmp/certs

# Set certificate environment variables for Python/pip and other tools
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt



# ----------------------------------------------------
# Install Core APT Packages
# ----------------------------------------------------
RUN pip install --no-cache-dir holoscan-cli && \
    hash -r && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-venv \
        build-essential \
        git \
        wget \
        curl \
        clang-format \
        libboost-all-dev \
        libpoco-dev \
        doxygen \
        graphviz \
        cmake && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------
# Source Builds
# ----------------------------------------------------
RUN mkdir -p /tmp/builds /usr/local/share/cpm-cache && \
    export CPM_SOURCE_CACHE=/usr/local/share/cpm-cache && \
    \
    # Build GTest v1.17.0 - Google Test C++ framework from GitHub
    # Latest stable version with proper CMake install targets
    git clone --branch v1.17.0 --depth 1 https://github.com/google/googletest.git && \
    cd googletest && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DCMAKE_BUILD_TYPE=Release \
          -DBUILD_GMOCK=ON \
          -DBUILD_SHARED_LIBS=OFF \
          .. && \
    make -j$(nproc) install && \
    cd /tmp/builds && \
    \
    # Build nvbench - NVIDIA CUDA kernel benchmarking library
    # Advanced GPU kernel timing and performance measurement
    git clone --branch main --depth 1 https://github.com/NVIDIA/nvbench.git && \
    cd nvbench && \
    mkdir build && cd build && \
    cmake -DNVBench_ENABLE_EXAMPLES=OFF \
          -DNVBench_ENABLE_TESTING=OFF \
          -DNVBench_ENABLE_CUPTI=OFF \
          -DCMAKE_CUDA_ARCHITECTURES="80;86;89;90" \
          -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DCMAKE_BUILD_TYPE=Release \
          .. && \
    make -j$(nproc) install && \
    cd /tmp/builds && \
    \
    # Install spdlog - Fast C++ logging library (header-only)
    git clone --branch v1.x --depth 1 https://github.com/gabime/spdlog.git && \
    cp -r spdlog/include/spdlog /usr/local/include/ && \
    cd /tmp/builds && \
    \
    # Build Taskflow - General-purpose task-parallel programming framework
    git clone --branch master --depth 1 https://github.com/taskflow/taskflow.git && \
    cd taskflow && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DCMAKE_BUILD_TYPE=Release \
          -DTF_BUILD_TESTS=OFF \
          -DTF_BUILD_EXAMPLES=OFF \
          -DTF_BUILD_BENCHMARKS=OFF \
          .. && \
    make -j$(nproc) install && \
    \
    # Clean up all build artifacts and temporary files
    cd / && \
    rm -rf /tmp/builds /usr/local/share/cpm-cache && \
    pip cache purge

# ----------------------------------------------------    
# Holohub Stuff
# ----------------------------------------------------
RUN true && \
    # Clone holohub into workspace
    cd /workspace && \
    git clone --branch holoscan-sdk-3.6.0 --depth 1 https://github.com/nvidia-holoscan/holohub.git && \
    # Run holohub setup
    chmod +x /workspace/holohub/holohub && \
    /workspace/holohub/holohub setup && \
    echo ". /etc/bash_completion.d/holohub_autocomplete" >> /etc/bash.bashrc && \
    pip install --no-cache-dir meson && \
    if ! grep -q "VERSION_ID=\"22.04\"" /etc/os-release; then \
        pip install setuptools; \
    fi && \
    # Install required system packages first
    apt-get update && \
    apt-get install -y --no-install-recommends \
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
        openjdk-21-jre && \
    pip install --no-cache-dir -r /workspace/holohub/benchmarks/holoscan_flow_benchmarking/requirements.txt && \
    hash -r && \
    echo 'export JREHOME=$(readlink /etc/alternatives/java | sed -e "s/\/bin\/java//")' >> /etc/bash.bashrc && \
    rm -rf /var/lib/apt/lists/*

ENV HOLOSCAN_INPUT_PATH=/workspace/holohub/data

# ----------------------------------------------------    
# Advanced Network Stuff
# ----------------------------------------------------
ARG TARGETARCH="amd64"
ARG DOCA_VERSION=2.8.0
ARG CACHEBUST=1
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /opt

# Configure the DOCA APT repository
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


# APT installs
# - cublas, cufft, cusolver, curand dev libs: for matx
# - ninja-build: for cmake build
# - pkgconf: to import dpdk and doca in CMake
# - mlnx-dpdk-dev: for dpdk and gpunetio backends
# - libdoca-sdk-dma-dev: for gpunetio backend (dependency of doca-gpunetio module)
# - libdoca-sdk-gpunetio-dev: for gpunetio backend (doca-gpunetio module)
# - libdoca-sdk-eth-dev: for gpunetio backend (doca-eth module)
# - libdoca-sdk-flow-dev: for gpunetio backend (doca-flow module)
# - mlnx-ofed-kernel-utils: utilities, including ibdev2netdev used by tune_system.py
# - ibverbs-utils: utilities
# - python3-pyelftools: used by some mlnx tools
# - python3-dev: for building python bindings
RUN apt-get update && apt-get install -y --no-install-recommends \
        libcublas-dev-12-6 \
        libcufft-dev-12-6 \
        libcusolver-dev-12-6 \
        libcurand-dev-12-6 \
        ninja-build \
        pkgconf \
        mlnx-dpdk-dev \
        libdoca-sdk-dma-dev \
        libdoca-sdk-gpunetio-dev \
        libdoca-sdk-eth-dev \
        libdoca-sdk-flow-dev \
        mlnx-ofed-kernel-utils \
        ibverbs-utils \
        python3-pyelftools \
    && rm -rf /var/lib/apt/lists/*


# ----------------------------------------------------    
# Wrap-up
# ----------------------------------------------------

# Default work directory
WORKDIR /workspace

CMD ["bash"]