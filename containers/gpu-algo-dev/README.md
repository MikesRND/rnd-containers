# GPU Algorithm Development Container

A GPU-accelerated development container based on NVIDIA Clara Holoscan SDK v3.5.0, equipped with MatX and nvbench libraries for high-performance GPU computing.

## Features

- **NVIDIA Clara Holoscan SDK v3.5.0** with GPU support
- **MatX v0.9.2** for GPU tensor operations  
- **nvbench** for CUDA kernel benchmarking
- **Latest CMake** from Kitware repository (3.30.4+)
- **Development tools**: clang-format, doxygen, Google Test
- **Corporate certificate support** for secure environments
- **Claude Code CLI** and **OpenAI Codex** pre-installed

## Quick Start

### Option 1: Pre-built Image (Docker Hub)
For open environments without corporate proxies:

```bash
docker pull mikesrnd/gpu-algo-dev:latest
docker run --runtime=nvidia -it mikesrnd/gpu-algo-dev:latest
```

### Option 2: Local Build with Certificates
For corporate environments requiring custom certificates:

```bash
# 1. Clone repository
git clone <repo-url>
cd rnd-containers/containers/gpu-algo-dev

# 2. Add your corporate certificates
cp /path/to/corporate-cert.crt certs/
cp /path/to/another-cert.pem certs/

# 3. Build container locally
make build

# 4. Run with docker-compose
docker-compose up -d
docker exec -it gpu-algo-dev bash
```

### Option 3: Docker Compose (Recommended for Development)
```bash
cd containers/gpu-algo-dev
PROJECT_PATH=/path/to/your/code docker-compose up -d
docker exec -it gpu-algo-dev bash
```

## Certificate Management

### Supported Certificate Formats
- `.crt` - X.509 certificate
- `.pem` - Privacy-Enhanced Mail format
- `.cer` - Certificate file

### How It Works
1. **Build Time**: Certificates from `certs/` directory are copied into the container and installed into the system certificate store
2. **Runtime**: Environment variables ensure all tools (Python, curl, Node.js) recognize the certificates
3. **Security**: Certificates are never committed to git or pushed to Docker Hub

### Environment Variables Set
- `REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt`
- `SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt`
- `CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt`
- `NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt`

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

# Use pre-installed tools
cmake --version      # Latest CMake
nvcc --version       # CUDA compiler
python3 --version    # Python with GPU libraries
claude --help        # Claude Code CLI
```

## Libraries and Tools

### GPU Computing
- **CUDA Toolkit** (from base image)
- **MatX v0.9.2**: Header-only tensor operations library
- **nvbench**: CUDA kernel benchmarking framework

### Development Tools
- **CMake 3.30.4+**: Build system
- **clang-format**: Code formatting
- **doxygen + graphviz**: Documentation generation
- **Google Test**: Unit testing framework

### AI Development
- **Claude Code CLI**: AI-powered development assistant
- **OpenAI Codex**: Code generation and analysis

## Troubleshooting

### Certificate Issues
If you encounter SSL/TLS errors:
1. Verify certificates are in `certs/` directory before building
2. Check certificate format (must be .crt, .pem, or .cer)
3. Rebuild container after adding certificates: `make build`

### GPU Access Issues
If GPU is not detected:
1. Ensure NVIDIA Docker runtime is installed
2. Verify `nvidia-smi` works on host
3. Check docker-compose includes `runtime: nvidia`

### Permission Issues
If files have wrong ownership:
```bash
# Fix ownership (run from host)
sudo chown -R $(id -u):$(id -g) /path/to/your/code
```

## Version Information

Current version: **1.0.3**

- Docker Hub: `mikesrnd/gpu-algo-dev:latest`
- Versioned: `mikesrnd/gpu-algo-dev:1.0.3`

## Security Notes

- **Certificates are never published** to Docker Hub or committed to git
- Each user must provide their own certificates for corporate environments
- Pre-built images contain no certificates and work only in open networks