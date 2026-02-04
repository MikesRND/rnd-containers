# Layered Builds for `ano-dev`

## Layers
The `ano-dev` stack is built in three layers, each with a clear responsibility and configurable inputs.

### Layer 1 — Base + Cert Injection
- Starts from a parameterized CUDA/Ubuntu base image.
- Injects trusted certificates so downstream builds and runtime downloads work in secured networks.
- Example image name: `base-cuda12.6-ubu22` (tag derived from CUDA/Ubuntu settings).

### Layer 2 — Holoscan Application Layer
- Builds the Holoscan-specific runtime for the project.
- Holoscan SDK version is selectable via `HOLOSCAN_VER` (e.g., `3.4.0` → tag `holo3.4`).
- Example image name: `holohub-ano-holo3.4-dpdk` (target variant determines the suffix).

### Layer 3 — User/Dev Layer
- Adds project tooling, MOTD/versioning, and developer conveniences.
- Tags mirror the Holoscan tag so the SDK version is visible in the final image name.
- Example image name: `ano-dev-holo3.4:0.1.0-abc1234` (semantic + git-based tagging).

## Customizing the Holoscan SDK Version
- Run `make configure` once to generate `config.mk`, then edit that file to set `HOLOSCAN_VER` (and other defaults like registry/namespace). Subsequent `make` commands will pick up your saved SDK version.

## EntryPoint Hooks (Addendum)
- The final image uses a layered entrypoint system (`scripts/entrypoint.sh` plus `/etc/entrypoint.d` hook scripts).
- Each hook runs in order at container start, enabling per-layer or per-feature initialization without editing a single monolithic script.

