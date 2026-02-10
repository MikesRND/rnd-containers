# Layered Builds for `ano-dev`

## Layers
The `ano-dev` stack is built in four layers, each with a clear responsibility and configurable inputs.

### Layer 0 — Base + Cert Injection
- Starts from a parameterized CUDA/Ubuntu base image.
- Injects trusted certificates so downstream builds and runtime downloads work in secured networks.
- Example image name: `base-cuda13.1-ubu22` (tag derived from CUDA/Ubuntu settings).

### Layer 1 — Holoscan Application Layer
- Builds the Holoscan-specific runtime for the project.
- Holoscan SDK version is selectable via `HOLOSCAN_VER` (e.g., `3.11.0` → tag `holo3.11.0`).
- Example image name: `holohub-ano-holo3.11.0-dpdk` (target variant determines the suffix).

### Layer 2 — SDK/Toolchain Layer (`ano-tools`)
- Adds compilers (GCC 13), CUDA toolkit, C++ source-built libraries, holohub setup, and the ANO operator.
- Creates the Python 3.12 venv and installs SDK-level pip packages.
- Content is pinned to specific versions and changes only when SDK/compiler versions bump.
- Example image name: `ano-tools-holo3.11.0`.

### Layer 3 — User/Dev Layer (`ano-dev`)
- Adds project tooling, vrtigo, MOTD/versioning, and developer conveniences.
- Tags mirror the Holoscan tag so the SDK version is visible in the final image name.
- Example image name: `ano-dev-holo3.11.0:0.1.4-d16c45f` (semantic + git-based tagging).

## Build Flow

```
make ano-dev
  └─ make ano-tools
       └─ make holohub-dpdk
            └─ make base
```

## Customizing the Holoscan SDK Version
- Run `make configure` once to generate `config.mk`, then edit that file to set `HOLOSCAN_VER` (and other defaults like registry/namespace). Subsequent `make` commands will pick up your saved SDK version.

## EntryPoint Hooks (Addendum)
- The final image uses a layered entrypoint system (`scripts/entrypoint.sh` plus `/etc/entrypoint.d` hook scripts).
- Each hook runs in order at container start, enabling per-layer or per-feature initialization without editing a single monolithic script.
