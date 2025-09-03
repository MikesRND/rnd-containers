# NVIDIA Clara Holoscan GPU Development Container
# Based on NVIDIA Clara Holoscan SDK with GPU support for scientific computing
FROM nvcr.io/nvidia/clara-holoscan/holoscan:v3.6.0-dgpu

# Labels for Docker Hub
LABEL maintainer="mikesrnd"
LABEL description="GPU-accelerated development container based on NVIDIA Clara Holoscan SDK with MatX and nvbench"

# Copy entrypoint scripts
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/nvidia_entrypoint_no_exec.sh /opt/nvidia/nvidia_entrypoint_no_exec.sh
RUN chmod +x /entrypoint.sh /opt/nvidia/nvidia_entrypoint_no_exec.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]


# Install holoscan CLI
RUN pip install holoscan-cli && hash -r

# Update package lists
RUN apt-get update

# Install latest CMake from Kitware APT repository
# Required versions: MatX requires CMake 3.26.4+, nvbench requires CMake 3.30.4+
RUN rm -f /usr/local/bin/cmake && \
    apt-get update && \
    apt-get install -y wget gpg && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
    echo 'deb https://apt.kitware.com/ubuntu/ jammy main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    apt-get update && \
    apt-get install -y cmake && \
    cmake --version

# Install development tools and libraries
RUN apt-get install -y \
    python3-venv \
    libgtest-dev \
    build-essential \
    git \
    wget \
    curl \
    clang-format \
    doxygen \
    graphviz \
    nodejs \
    npm \
    libboost-all-dev \
    libpoco-dev

# DEPRECATED: MatX is now included with Holoscan SDK, no need to install separately
    # Install MatX v0.9.2 library for GPU tensor operations
# MatX is a header-only library that provides high-level tensor operations with CUDA backend
# RUN cd /tmp && \
#     git clone --branch v0.9.2 --depth 1 https://github.com/NVIDIA/MatX.git && \
#     cd MatX && \
#     mkdir build && \
#     cd build && \
#     export CPM_SOURCE_CACHE=/usr/local/share/cpm-cache && \
#     mkdir -p /usr/local/share/cpm-cache && \
#     cmake -DMATX_BUILD_TESTS=OFF \
#           -DMATX_BUILD_BENCHMARKS=OFF \
#           -DMATX_BUILD_EXAMPLES=OFF \
#           -DMATX_BUILD_DOCS=OFF \
#           -DCMAKE_INSTALL_PREFIX=/usr/local \
#           .. && \
#     make -j$(nproc) install && \
#     cd / && \
#     rm -rf /tmp/MatX/build && \
#     rm -rf /tmp/MatX/.git

# Install nvbench for CUDA kernel benchmarking
# nvbench provides advanced GPU kernel timing and benchmarking capabilities
RUN mkdir -p /workspace && \
    cd /workspace && \
    git clone --branch main --depth 1 https://github.com/NVIDIA/nvbench.git && \
    cd nvbench && \
    mkdir build && cd build && \
    export CPM_SOURCE_CACHE=/usr/local/share/cpm-cache && \
    cmake -DNVBench_ENABLE_EXAMPLES=OFF \
          -DNVBench_ENABLE_TESTING=OFF \
          -DNVBench_ENABLE_CUPTI=OFF \
          -DCMAKE_CUDA_ARCHITECTURES="86;90" \
          -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DCMAKE_BUILD_TYPE=Release \
          .. && \
    make -j$(nproc) install && \
    find /usr/local -name "*nvbench*" | head -5 && \
    rm -rf build && \
    cd /workspace && \
    chown -R 1000:1000 nvbench

# Install spdlog (header-only C++ logging library) to /workspace/spdlog and copy headers
RUN cd /workspace && \
    git clone --branch v1.x --depth 1 https://github.com/gabime/spdlog.git && \
    cp -r spdlog/include/spdlog /usr/local/include/

# Install Taskflow - A General-purpose Task-parallel Programming Framework
# Taskflow provides modern C++17/20 parallel task programming for CPU and GPU
RUN cd /workspace && \
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
    rm -rf build && \
    cd /workspace && \
    chown -R 1000:1000 taskflow


# Clean up apt cache to reduce image size
RUN rm -rf /var/lib/apt/lists/*

# Default work directory
WORKDIR /workspace

CMD ["bash"]