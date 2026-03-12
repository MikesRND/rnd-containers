#!/bin/bash
# rebuild-holoscan-networking — Rebuild and reinstall holoscan-networking
# from the mounted /workspace/holohub source tree.
#
# Must be run as root (install target is /opt/nvidia/holoscan).
set -euo pipefail

HOLOHUB_DIR="/workspace/holohub"
INSTALL_PREFIX="/opt/nvidia/holoscan"
BUILD_TYPE="Release"
CUDA_ARCHS="native"
CLEAN=false

usage() {
    cat <<EOF
Usage: rebuild-holoscan-networking [OPTIONS]

Rebuild and reinstall holoscan-networking from /workspace/holohub.

OPTIONS:
    --debug     Build with CMAKE_BUILD_TYPE=Debug
    --clean     Remove existing build directory before building
    --archs A   Set CUDA architectures (default: native)
    -h, --help  Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)   BUILD_TYPE="Debug"; shift ;;
        --clean)   CLEAN=true; shift ;;
        --archs)   CUDA_ARCHS="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

# ── Validate source tree ───────────────────────────────────
if [[ ! -d "$HOLOHUB_DIR/.git" ]]; then
    echo "ERROR: $HOLOHUB_DIR/.git not found." >&2
    echo "This script requires a live HoloHub git checkout mounted at $HOLOHUB_DIR." >&2
    exit 1
fi

# ── Print source identity ─────────────────────────────────
branch=$(git -C "$HOLOHUB_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
commit=$(git -C "$HOLOHUB_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
echo "HoloHub source: branch=$branch commit=$commit"
echo "Build type: $BUILD_TYPE  CUDA archs: $CUDA_ARCHS"

# ── Clean if requested ────────────────────────────────────
if [[ "$CLEAN" == true && -d "$HOLOHUB_DIR/build" ]]; then
    echo "Cleaning previous build..."
    rm -rf "$HOLOHUB_DIR/build"
fi

# ── Patch CUDA architectures ──────────────────────────────
for cmake_file in \
    "$HOLOHUB_DIR/applications/adv_networking_bench/cpp/CMakeLists.txt" \
    "$HOLOHUB_DIR/applications/network_radar_pipeline/cpp/CMakeLists.txt"; do
    if [[ -f "$cmake_file" ]]; then
        sed -i 's/set(CMAKE_CUDA_ARCHITECTURES "[^"]*")/set(CMAKE_CUDA_ARCHITECTURES "'"$CUDA_ARCHS"'")/' \
            "$cmake_file"
        sed -i 's/CUDA_ARCHITECTURES "[0-9;]*"/CUDA_ARCHITECTURES "'"$CUDA_ARCHS"'"/' \
            "$cmake_file"
    fi
done

# ── Configure ─────────────────────────────────────────────
echo "Configuring..."
cmake -B "$HOLOHUB_DIR/build" -S "$HOLOHUB_DIR" \
    -DPKG_holoscan-networking=ON \
    -DAPP_adv_networking_bench=ON \
    -DAPP_basic_networking_ping=ON \
    -DAPP_network_radar_pipeline=ON \
    -DANO_MGR=dpdk \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_CUDA_ARCHITECTURES="$CUDA_ARCHS" \
    -DHOLOHUB_BUILD_PYTHON=OFF \
    -DHOLOHUB_DOWNLOAD_DATASETS=OFF \
    -DBUILD_TESTING=OFF

# ── Build ─────────────────────────────────────────────────
echo "Building..."
cmake --build "$HOLOHUB_DIR/build" -j"$(nproc)"

# ── Install ───────────────────────────────────────────────
echo "Installing to $INSTALL_PREFIX..."
mkdir -p "$HOLOHUB_DIR/build/python/lib/holohub"
cmake --install "$HOLOHUB_DIR/build" --prefix "$INSTALL_PREFIX"

echo "Done. holoscan-networking rebuilt and installed."
