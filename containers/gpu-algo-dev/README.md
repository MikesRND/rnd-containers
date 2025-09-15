# GPU Algorithm Development Container

A GPU-accelerated development container based on NVIDIA Clara Holoscan SDK v3.5.0, equipped with MatX and nvbench libraries for high-performance GPU computing.

## Features

- NVIDIA Clara Holoscan SDK v3.6.0** with MatX

## Quick Start

### Pre-built Image (Docker Hub)

```bash
docker pull mikesrnd/gpu-algo-dev:latest
docker run --runtime=nvidia -it mikesrnd/gpu-algo-dev:latest
```

### Option 2: Local Build 

```bash
# Clone repository
git clone <repo-url>
cd rnd-containers/containers/gpu-algo-dev

# Build container locally
make build

# Run with docker-compose
docker-compose up -d
docker exec -it gpu-algo-dev bash
```

## Available Commands

### Makefile Targets
```bash
make help     # Show available targets
make build    # Build the container image
make tag      # Tag with version and Docker Hub namespace
make push     # Push to Docker Hub (requires docker login)
make release  # Build, tag, and push (full release)
make clean    # Remove local images
make version  # Show current version
```

### Development Workflow
```bash
# Start development environment
docker-compose up -d

# Access the container
docker exec -it gpu-algo-dev bash

# Your code is mounted at /workspace
cd /workspace

```

## Holohub example

To build the advanced networking testbench example from Holohub:

```bash
cd /workspace/holohub
./holohub build --local adv_networking_testbench --language cpp
```

