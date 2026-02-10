# ano-dev container

Dev container for GPU Algorithms work aligned to a specific Holoscan and Holohub (advanced networking) release.

## Build
- From rnd-containers repo root: `make ano-dev`
- Required vars (can be set via `make configure` -> `config.mk`): `HOLOSCAN_VER`, `CUDA_VER`; optional `VER_SEMVER`, `VER_GIT_COMMIT` for labels.

## Run
- From rnd-containers repo root: `make -C containers/ano-dev compose-up` (or `compose-shell` for an interactive shell)
- Service name: `ano-dev` (matches `docker-compose.yml`)
- Workspace auto-mapped to `/workspace/<repo>` via entrypoint drop-in

## Contents
- Holoscan SDK deb installed under `/opt/nvidia/holoscan`
- Holohub cloned at `holoscan-sdk-${HOLOSCAN_VER}` and `holohub setup` pre-run
- CUDA toolkit `${CUDA_VER}`, GCC 13 as default, Python 3.12 venv with holoscan-cli
- Source builds: GTest, nvbench, spdlog (header-only copy), Taskflow

## Usage
- Compose service name: `ano-dev` (see `docker-compose.yml`)
- Workspace auto-mapped to `/workspace/<repo>` via entrypoint drop-in
- Entry shell MOTD shows container version and git commit

## Holoscan Networking
- The `holoscan-networking` deb is **not** installed.
- Advanced networking comes from the holohub clone at `holoscan-sdk-${HOLOSCAN_VER}` and is built/setup via `holohub setup`, keeping source and SDK versions aligned.
