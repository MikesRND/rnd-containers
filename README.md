# R&D Containers Repository

This repository contains Docker containers used for Research & Development projects, with a focus on GPU-accelerated computing and scientific applications.

## Available Containers

### gpu-algo-dev
A GPU-accelerated development container based on NVIDIA Clara Holoscan SDK v3.5.0, equipped with MatX and nvbench libraries for high-performance GPU computing.

**Features:**
- NVIDIA Clara Holoscan SDK v3.5.0 with GPU support
- MatX v0.9.2 for GPU tensor operations
- nvbench for CUDA kernel benchmarking
- Latest CMake from Kitware repository
- Development tools: clang-format, doxygen, Google Test
- Dynamic user creation for seamless host integration
- Corporate certificate support

## Quick Start

### Building Locally

```bash
cd containers/gpu-algo-dev
make build
```

### Using Docker Compose

```bash
cd containers/gpu-algo-dev
docker-compose up -d
docker exec -it gpu-algo-dev bash
```

### Publishing to Docker Hub

```bash
cd containers/gpu-algo-dev
make release  # Builds, tags, and pushes to Docker Hub
```

## Versioning Strategy

Containers follow semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes or significant base image updates
- **MINOR**: New features, libraries, or tools added
- **PATCH**: Bug fixes and minor updates

Each container maintains its own version in its Makefile.

### Tagging Convention
- `gpu-algo-dev:latest` - Latest stable version
- `gpu-algo-dev:1.0.0` - Specific version
- `gpu-algo-dev:1.0` - Latest patch of minor version
- `gpu-algo-dev:1` - Latest minor/patch of major version

## Certificate Management

### Using Pre-built Images (Docker Hub)
Pre-built images are available without certificates for use in open environments:
```bash
docker pull mikesrnd/gpu-algo-dev:latest
docker run --runtime=nvidia -it mikesrnd/gpu-algo-dev:latest
```

### Corporate Environments (Local Build Required)
For corporate networks requiring custom certificates:

1. **Add your certificates:**
   ```bash
   cd containers/gpu-algo-dev/certs/
   cp /path/to/your-corporate-cert.crt .
   cp /path/to/another-cert.pem .
   ```

2. **Build locally:**
   ```bash
   cd containers/gpu-algo-dev
   make build
   # OR using docker-compose
   docker-compose up -d
   ```

3. **Supported certificate formats:** `.crt`, `.pem`, `.cer`

### Certificate Security
- **Certificates are NEVER published to Docker Hub**
- Local `certs/` directory is excluded from git and Docker builds for public images
- Each user must add their own certificates locally before building

## Docker Hub Integration

Images are published to Docker Hub under the `mikesrnd` namespace.

### Manual Publishing
```bash
docker login
cd containers/gpu-algo-dev
make push
```

### Automated Publishing
GitHub Actions automatically publishes containers when tags are pushed:
```bash
git tag gpu-algo-dev-v1.0.1
git push origin gpu-algo-dev-v1.0.1
```

### Required Secrets for CI/CD
Set these in GitHub repository settings:
- `DOCKER_HUB_USERNAME`: Your Docker Hub username
- `DOCKER_HUB_ACCESS_TOKEN`: Docker Hub access token

## Container Structure

```
containers/
├── gpu-algo-dev/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── Makefile
│   ├── scripts/
│   │   ├── entrypoint.sh
│   │   └── nvidia_entrypoint_no_exec.sh
│   └── certs/
│       └── .gitkeep
└── [future containers...]
```

## Contributing

1. Create a new directory under `containers/` for each new container
2. Include a Dockerfile, docker-compose.yml, and Makefile
3. Update this README with container details
4. Test locally before pushing
5. Tag releases appropriately for CI/CD

## License

This repository is licensed under the MIT License. See LICENSE file for details.

## Support

For issues or questions, please open an issue in the GitHub repository.