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

### Container Management (User Workflow)
```bash
make help                  # Show all available commands
make container-up          # Start the container
make container-down        # Stop the container
make container-shell       # Open shell in running container (as user)
make container-shell-root  # Open shell in running container (as root)
make container-logs        # View container logs
make container-pull        # Pull the latest image from Docker Hub
```

### Container Build & Release (Developer Workflow)

#### Build Commands
```bash
make container-build        # Build with SEMVER-COMMIT and SEMVER tags
                            # e.g., 0.0.6-abc1234 and 0.0.6
                            # Does NOT tag as :latest

make container-tag-latest   # Tag existing build as :latest (local only)
                            # WARNING: CI/CD use only!

make container-version      # Show current version, commit, branch, and tag info
make container-clean        # Remove local images
```

#### Release Workflows

**Automated Release (Recommended):**
```bash
make container-release      # Push versioned images to Docker Hub
                            # Must be on clean main branch
                            # Pushes: SEMVER-COMMIT and SEMVER tags
                            # NOTE: :latest tag only pushed via CI/CD
```

**Manual Latest Push (Emergency/Testing):**
```bash
make container-login        # Login to Docker Hub
make container-push-latest  # Build, tag as :latest, and push ALL tags
                            # WARNING: Bypasses CI/CD
                            # Interactive confirmation required
                            # Pushes: SEMVER-COMMIT, SEMVER, and :latest
```

### Image Tagging Strategy

**Development Builds** (local - `make container-build`):
- Tags created: `SEMVER-COMMIT_HASH` and `SEMVER`
  - e.g., `mikesrnd/gpu-algo-dev:0.0.5-abc1234` and `mikesrnd/gpu-algo-dev:0.0.5`
- Single build, multiple tags (no rebuild needed)
- Does NOT include `:latest` tag

**Production Builds** (CI/CD on main branch):
- Tags created: `SEMVER-COMMIT_HASH`, `SEMVER`, and `:latest`
  - e.g., `0.0.5-abc1234`, `0.0.5`, `latest`
- Triggered automatically when PR is merged to main
- Single build with all three tags applied simultaneously
- GitHub Actions workflow publishes to Docker Hub

**Why this matters:**
- Every build is traceable to exact commit via SEMVER-COMMIT_HASH tag
- SEMVER tag (semantic version like 1.2.3) allows easy reference to latest patch of a version
- `:latest` tag only updated via CI/CD on main branch
- No separate rebuilds for different tags - same image, multiple references
- No accidental overwrites of production `:latest` from local machines

### Development Workflow

#### Using Pre-built Images
```bash
# Pull specific version
IMAGE_TAG=0.0.5-abc1234 make container-pull

# Or pull latest stable
make container-pull  # defaults to :latest

# Start container
make container-up

# Access the container
make container-shell
```

#### Local Development Build
```bash
# Build local version (tagged with your current commit)
make container-build

# Check what tag will be used
make container-version

# Override image tag for docker-compose
export IMAGE_TAG=0.0.6-abc1234
make container-up

# Access the container
make container-shell

# Your code is mounted at /mnt/current_folder
cd /mnt/current_folder
```

### Using a Different Registry

To use a different registry (e.g., GitHub Container Registry):

```bash
# Set registry and namespace
export REGISTRY=ghcr.io
export IMAGE_NAMESPACE=myorg
export IMAGE_NAME=gpu-algo-dev

# Build and tag
make container-build

# Or use with docker-compose
make container-up
```

All registry configuration variables:
- `REGISTRY` - Container registry (default: `docker.io`)
- `IMAGE_NAMESPACE` - Namespace/organization (default: `mikesrnd`)
- `IMAGE_NAME` - Image name (default: `gpu-algo-dev`)
- `IMAGE_TAG` - Version tag (auto-generated or override)

## Holohub example

To build the advanced networking testbench example from Holohub:

```bash
cd /workspace/holohub
./holohub build --local adv_networking_testbench --language cpp
```

