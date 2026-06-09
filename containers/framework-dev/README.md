# framework-dev container

DAQIRI-only (Holoscan-free) dev container for GPU framework. Mirrors
DAQIRI's DPDK/DOCA/DAQIRI build on top of this repo's base/entrypoint/
versioning conventions. 

## Layers

- `framework-base` - this repo's `containers/base/Dockerfile` on
  `nvcr.io/nvidia/cuda:13.1.0-devel-ubuntu24.04` (certs + entrypoint).
- `framework-sdk` - heavy cached layer: patched DPDK 25.11, DOCA/RDMA deps,
  DAQIRI (`/opt/daqiri`), MatX, nvbench, GTest, spdlog, Taskflow, Boost,
  Poco, yaml-cpp, build tooling.
- `framework-dev` - thin dev layer: workspace mapping, vrtigo, version-info.

## Build

- From rnd-containers repo root: `make framework-dev`
- Wider coverage (heavier/slower): `make framework-dev FRAMEWORK_CUDA_ARCHS=all`

`FRAMEWORK_CUDA_ARCHS` is a Make-only knob mapped to the Docker `CUDA_ARCHS`
build-arg; it drives every CUDA-compiled dependency (DAQIRI, nvbench). It is
deliberately separate from the top-level `CUDA_ARCHS` used by the legacy
ANO/HoloHub path so the two stacks do not interfere.

The default builds native (real) SASS for exactly the deployment fleet:

| arch       | compute cap | GPUs                                          |
| ---------- | ----------- | --------------------------------------------- |
| `89-real`  | sm_89       | RTX 2000 Ada (Ada Lovelace)                   |
| `90-real`  | sm_90       | H200 NVL (Hopper)                             |
| `120-real` | sm_120      | RTX 5060 (dev host), RTX PRO 2000 Blackwell   |
| `121-real` | sm_121      | DGX Spark / GB10 (Blackwell)                  |

nvcc compiles every kernel once per arch, so this 4-arch list is ~3x less
device compilation (and much less RAM) than CUDA 13.1's ~12-arch `all`. Use
`FRAMEWORK_CUDA_ARCHS=all` for broad coverage at the cost of build time/size.

## Release (multi-arch)

DGX Spark / GB10 has a **Grace (arm64) CPU**, so the published image must be
multi-arch: the device arch (sm_121) is not enough, the host code must also be
aarch64. Because the layered chain (`base -> sdk -> dev`) can't be cross-built
in one `buildx --platform` pass and QEMU emulation of a CUDA/DPDK build is
impractical, each platform is built **natively on its own host**, then a
manifest is assembled:

```sh
# on an amd64 host (e.g. x86 workstation / CI runner):
make framework-release-arch        # builds + pushes :<ver>-amd64

# on an arm64 host (DGX Spark, Grace box, or arm64 CI runner; no GPU needed):
make framework-release-arch        # builds + pushes :<ver>-arm64

# on either host, after BOTH arch tags are pushed:
make framework-manifest            # assembles + pushes :<ver>, :<full>, :latest
```

Consumers then pull a single tag (`framework-dev:<ver>`) and Docker selects
amd64 or arm64 automatically. Tag scheme:

| tag                         | kind                         |
| --------------------------- | ---------------------------- |
| `:<semver>-amd64` / `-arm64`| per-arch (intermediate)      |
| `:<full>-amd64`  / `-arm64` | per-arch, commit-pinned      |
| `:<semver>`, `:<full>`, `:latest` | multi-arch manifest    |

`<full>` = `<semver>-<git-commit>[-dirty]`; release from a clean tree.
Requires a registry login and `docker buildx`.

## Run

- From rnd-containers repo root: `make -C containers/framework-dev compose-up`
  (or `compose-shell` for an interactive shell)
- Service name: `framework-dev` (matches `docker-compose.yml`)
- Workspace auto-mapped to `/workspace/<repo>` via entrypoint drop-in
- Compose runs `privileged` with `network_mode: host` and a `/dev/hugepages`
  mount, as DPDK/GPUDirect require.

## Contents

- DAQIRI installed under `/opt/daqiri` (managers: `dpdk socket`); bench/example
  YAMLs land in `/opt/daqiri/bin` (DAQIRI's install layout).
- Patched upstream DPDK 25.11 under `/usr/local`, configured with
  `max_lcores=256` and exposing `rte_extmem_register_dmabuf` via DAQIRI's
  `dmabuf.patch`.
- MatX (`v1.0.0`), nvbench, GTest, spdlog, Taskflow installed under
  `/usr/local`; Boost, Poco, yaml-cpp via apt.
- No Holoscan SDK, no HoloHub clone, no `holoscan-networking`.

Consumer search paths are exported by the SDK layer:
`CMAKE_PREFIX_PATH=/opt/daqiri:/usr/local`, plus matching `PKG_CONFIG_PATH`
(incl. the multiarch DPDK pkgconfig dir) and `LD_LIBRARY_PATH`.

## DAQIRI sync contract

`framework-sdk/Dockerfile` mirrors DAQIRI's DPDK/DOCA/DAQIRI build block from
a pinned ref. Changing `DAQIRI_REF` is **not** a free override: it requires
re-diffing the mirrored block against DAQIRI's Dockerfile at the new ref and
re-validating `dpdk_patches/*.patch` against the pinned `DPDK_VERSION`. See the
`KEEP IN SYNC WITH UPSTREAM` comment block in the SDK Dockerfile.
