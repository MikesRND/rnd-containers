# ano-dev Version Info

## v0.1.8

**Base:** `nvcr.io/nvidia/cuda:13.1.0-base-ubuntu22.04`

### DPDK / Networking Stack

| Component | Version | Notes |
|---|---|---|
| DPDK | 24.11.3 | Upstream, built from source in Layer 1 |
| DOCA repo | 3.2.1 | APT repo for mlnx-ofed-kernel-utils |
| OFED | 25.10 | Via mlnx-ofed-kernel-utils (ibdev2netdev) |
| libibverbs | (from base-deps) | RDMA/ConnectX driver stack |
| librdmacm | (from base-deps) | RDMA/ConnectX driver stack |

### Changes from v0.1.4

- **Removed `mlnx-dpdk-dev`** (Mellanox DPDK 22.11 fork) from Layer 2 (`ano-tools/Dockerfile`)
- **Removed `PKG_CONFIG_PATH` override** pointing to `/opt/mellanox/dpdk/`
- `holoscan-networking` now links against **upstream DPDK 24.11.3** built from source in Layer 1
- MOTD networking line updated: `DOCA 3.2.1 · OFED 25.10 · DPDK 24.11.3`
- `gpunetio` stage in Layer 1 marked as EXPERIMENTAL (not supported by holoscan-networking)
- `ENV DOCA_VERSION` exposed from Layer 1 for runtime version reporting


## v0.1.4

**Base:** `nvcr.io/nvidia/cuda:13.1.0-base-ubuntu22.04`

### Base Platform

| Component | Version |
|---|---|
| Ubuntu | 22.04.5 LTS (Jammy Jellyfish) |
| CUDA | 13.1 (V13.1.115) |
| GCC | 13.1.0 |
| CMake | 3.31.11 |
| Python | 3.12 (venv: `/opt/venv/vrtigo`) |
| Holoscan SDK | 3.11.0 |
| HoloHub | Git: holoscan-sdk-3.11.0 (5c094d3) |

### DPDK / Networking Stack

| Component | Version |
|---|---|
| mlnx-dpdk-dev | 22.11.0-2510.2.1 |
| libdpdk | 22.11.2510.2.1 |
| MLNX OFED | 25.10.OFED.25.10.1.7.1.1 |
| libibverbs | 2510.0.11 |
| librdmacm | 39.0 |


## v0.1.3 (8dca1eb)

**Base:** `nvcr.io/nvidia/cuda:13.1.0-base-ubuntu22.04`

### Base Platform

| Component | Version |
|---|---|
| Ubuntu | 22.04.5 LTS (Jammy Jellyfish) |
| CUDA | 13.1 (V13.1.115) |
| GCC | 13.1.0 |
| CMake | 3.31.11 |
| Python | 3.11 (venv: `/opt/venv/vrtigo`) |
| Holoscan SDK | 3.11.0 |
| HoloHub | Git: holoscan-sdk-3.11.0 (5c094d3) |

### DPDK / Networking Stack

| Component | Version |
|---|---|
| mlnx-dpdk-dev | 22.11.0-2510.2.1 |
| libdpdk | 22.11.2510.2.1 |
| MLNX OFED | 25.10.OFED.25.10.1.7.1.1 |
| libibverbs | 2510.0.11 |
| librdmacm | 39.0 |

