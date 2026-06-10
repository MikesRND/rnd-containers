# R&D Container Repository

This repository contains Docker containers used for Research & Development projects.

## Framework Development Container

`framework-dev` is the primary container in this repo. 

It is intended for use in developing high-performance, networked, distributed GPU-accelerated DSP applications using the latest NVIDIA SDKs and tools.  Contents include:

```
framework-dev 0.1.3 (c62a5b1)
---------------------------------------------
Platform     Ubuntu 24.04.3 LTS (Noble Numbat) . Linux 6.6.87.2
Compilers    GCC 13.3.0 . CUDA 13.1.80
Build        CMake 3.31.12 . Ninja 1.11.1 . Meson 1.3.2 . ccache 4.9.1
Analysis     clang-format 18.1.3 . clang-tidy 18.1.3 . lcov 2.0
Python       3.12.3
Py Packages  vrtigo 0.2.0 (9f70591) . pytest 9.0.3 . scipy 1.17.1
            pyqtgraph 0.14.0 . PyQt6 6.11.0
DAQIRI       DAQIRI 0.1.0 . commit bedf31a
Networking   DPDK 25.11.0 . OFED 25.10
GPU Libs     MatX 0.9.4 . GTest 1.17.0
C++ Libs     Boost 1.83.0 . spdlog 1.17.0
            Poco 1.11.0 . yaml-cpp 0.8.0
Tools        git 2.43.0 . gdb 15.1 . doxygen 1.9.8 . vim 9.1
---------------------------------------------
```
### Build and Run

Build it from the repo root:

```sh
make framework-dev
```

Run it:

```sh
make -C containers/framework-dev compose-up
make -C containers/framework-dev compose-shell
```

See [containers/framework-dev/README.md](containers/framework-dev/README.md) for
details.

## Deprecated Containers

The other containers are retained for historical/reference use only:

- `ano-dev`
- `ano-tools`
- `gpu-algo-dev`
- `ano/holohub`

## License

This repository is licensed under the MIT License. See LICENSE file for details.
