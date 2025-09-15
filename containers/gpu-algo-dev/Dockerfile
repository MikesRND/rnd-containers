# NVIDIA Clara Holoscan GPU Development Container
# Based on NVIDIA Clara Holoscan SDK with GPU support for scientific computing

###################
# Build stage
###################
FROM nvcr.io/nvidia/clara-holoscan/holoscan:v3.6.0-dgpu AS build

# Install development tools and libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-venv \
        libgtest-dev \
        build-essential \
        git \
        curl \
        clang-format \
        doxygen \
        graphviz \
        nodejs \
        npm \
        libboost-all-dev \
        libpoco-dev \
        libspdlog-dev && \
    rm -rf /var/lib/apt/lists/*

# Build nvbench for CUDA kernel benchmarking
RUN mkdir -p /workspace && cd /workspace && \
    git clone --branch main --depth 1 https://github.com/NVIDIA/nvbench.git && \
    cd nvbench && mkdir build && cd build && \
    export CPM_SOURCE_CACHE=/tmp/cpm-cache && \
    cmake -DNVBench_ENABLE_EXAMPLES=OFF \
          -DNVBench_ENABLE_TESTING=OFF \
          -DNVBench_ENABLE_CUPTI=OFF \
          -DCMAKE_CUDA_ARCHITECTURES="86;90" \
          -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc) install && \
    cd / && rm -rf /workspace/nvbench /tmp/cpm-cache

# Build Taskflow - task-parallel programming framework
RUN cd /tmp && \
    git clone --branch v3.10.0 --depth 1 https://github.com/taskflow/taskflow.git && \
    cd taskflow && mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DCMAKE_BUILD_TYPE=Release \
          -DTF_BUILD_TESTS=OFF \
          -DTF_BUILD_EXAMPLES=OFF \
          -DTF_BUILD_BENCHMARKS=OFF .. && \
    make -j$(nproc) install && \
    cd / && rm -rf /tmp/taskflow

###################
# Runtime stage
###################
FROM nvcr.io/nvidia/clara-holoscan/holoscan:v3.6.0-dgpu

# Copy entrypoint scripts
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/nvidia_entrypoint_no_exec.sh /opt/nvidia/nvidia_entrypoint_no_exec.sh
RUN chmod +x /entrypoint.sh /opt/nvidia/nvidia_entrypoint_no_exec.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Copy compiled libraries and headers from build stage
COPY --from=build /usr/local /usr/local

# Install holoscan CLI
RUN pip install --no-cache-dir holoscan-cli && hash -r

# Remove unused package lists and clean APT cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Default work directory
WORKDIR /workspace

CMD ["bash"]
