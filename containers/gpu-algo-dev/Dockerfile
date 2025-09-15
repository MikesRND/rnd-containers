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

# Install APT Packages
RUN pip install --no-cache-dir holoscan-cli && hash -r && \
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
        cmake && \
    rm -rf /var/lib/apt/lists/*

# Source Builds
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

# Default work directory
WORKDIR /workspace

CMD ["bash"]