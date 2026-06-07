#!/bin/bash
# version-info.sh - Display installed tool versions in the framework-dev container.
# Installed to /usr/local/bin/version-info for standalone use.
#
# DAQIRI-only stack: no Holoscan SDK / HoloHub / holoscan-networking rows.

# Use build-time cache for instant display; --live to regenerate.
CACHE_FILE="/etc/version-info.cache"
if [[ -f "$CACHE_FILE" && "${1:-}" != "--live" ]]; then
    cat "$CACHE_FILE"
    exit 0
fi

# ── Helpers ──────────────────────────────────────────────────

# Get version string from a pip package (empty if not installed).
pip_ver() { pip show "$1" 2>/dev/null | awk '/^Version:/{print $2}'; }

# Get version string from dpkg, stripping the distro suffix.
dpkg_ver() { dpkg-query -W -f '${Version}' "$1" 2>/dev/null; }

# Print a labeled row.
row() { local label="$1"; shift; printf "  %-13s%s\n" "$label" "$*"; }

# Print a continuation row (no label).
cont() { printf "  %-13s%s\n" "" "$*"; }

# Join non-empty args with " . ".
join() {
    local result=""
    for item in "$@"; do
        [[ -z "$item" ]] && continue
        [[ -n "$result" ]] && result+=" . "
        result+="$item"
    done
    echo "$result"
}

# Format "name ver" - returns empty string if ver is empty/n/a.
tag() {
    local name="$1" ver="$2"
    [[ -z "$ver" || "$ver" == "n/a" ]] && return
    echo "$name $ver"
}

# Read PACKAGE_VERSION from a CMake *ConfigVersion.cmake file.
cmake_pkg_ver() {
    sed -n 's/^set(PACKAGE_VERSION "\([^"]*\)").*/\1/p' "$1" 2>/dev/null | head -1
}

# ── Version queries ──────────────────────────────────────────

# Container
container_ver="${CONTAINER_VERSION:-dev}"
git_commit="${GIT_COMMIT:-unknown}"

# Platform
ubuntu_ver=$(. /etc/os-release 2>/dev/null && echo "$VERSION" || echo "n/a")
kernel_ver=$(uname -r 2>/dev/null | sed 's/-.*//' || echo "n/a")

# Compilers
gcc_ver=$(gcc -dumpfullversion 2>/dev/null || gcc -dumpversion 2>/dev/null)
nvcc_ver=$(nvcc --version 2>/dev/null | sed -n 's/.*release [^,]*, V//p')

# Build tools
cmake_ver=$(cmake --version 2>/dev/null | head -1 | awk '{print $NF}')
ninja_ver=$(ninja --version 2>/dev/null)
meson_ver=$(meson --version 2>/dev/null)
ccache_ver=$(ccache --version 2>/dev/null | head -1 | awk '{print $NF}')
pkgconfig_ver=$(pkg-config --version 2>/dev/null)

# Analysis
clangfmt_ver=$(clang-format --version 2>/dev/null | grep -oP 'version \K[\d.]+')
clangtidy_ver=$(clang-tidy --version 2>/dev/null | grep -oP 'version \K[\d.]+')
lcov_ver=$(lcov --version 2>/dev/null | grep -oP 'version \K[\d.]+')

# Python
python_ver=$(python3 --version 2>/dev/null | awk '{print $2}')

# Pip packages
vrtigo_pip=$(pip_ver vrtigo)
vrtigo_commit=$(cut -c1-7 /workspace/vrtigo/.git/refs/heads/main 2>/dev/null)
vrtigo_ver="${vrtigo_pip:+$vrtigo_pip}${vrtigo_commit:+ ($vrtigo_commit)}"
pytest_ver=$(pip_ver pytest)
scipy_ver=$(pip_ver scipy)
pyqtgraph_ver=$(pip_ver pyqtgraph)
pyqt6_ver=$(pip_ver PyQt6)

# DAQIRI
daqiri_ver=$(pkg-config --modversion daqiri 2>/dev/null)
daqiri_commit=$(cut -c1-7 /workspace/daqiri/.git/HEAD 2>/dev/null)
[[ -z "$daqiri_ver" && -d /opt/daqiri ]] && daqiri_ver="installed"

# Networking
dpdk_ver=$(pkg-config --modversion libdpdk 2>/dev/null)
ofed_ver=$(ofed_info -s 2>/dev/null | grep -oP 'MLNX_OFED_LINUX-\K[\d.]+' | head -1)
[[ -z "$ofed_ver" ]] && ofed_ver=$(dpkg_ver mlnx-ofed-kernel-utils | grep -oP '^\d+\.\d+')
doca_ver="${DOCA_VERSION:-}"

# GPU libraries
matx_ver=$(cmake_pkg_ver /usr/local/lib/cmake/matx/matx-config-version.cmake)
gtest_ver=$(cmake_pkg_ver /usr/local/lib/cmake/GTest/GTestConfigVersion.cmake)

# C++ libraries
boost_ver=$(dpkg_ver libboost-all-dev | grep -oP '^\d+\.\d+\.\d+')
spdlog_ver=$(awk '
    /^#define SPDLOG_VER_MAJOR /{maj=$3}
    /^#define SPDLOG_VER_MINOR /{min=$3}
    /^#define SPDLOG_VER_PATCH /{pat=$3}
    END{if(maj!="") printf "%s.%s.%s", maj, min, pat}
' /usr/local/include/spdlog/version.h 2>/dev/null)
taskflow_ver=$(cmake_pkg_ver /usr/local/lib/cmake/Taskflow/TaskflowConfigVersion.cmake)
poco_ver=$(dpkg_ver libpoco-dev | grep -oP '^\d+\.\d+\.\d+')
yamlcpp_ver=$(dpkg_ver libyaml-cpp-dev | grep -oP '^\d+\.\d+\.\d+')

# Tools
git_ver=$(git --version 2>/dev/null | awk '{print $3}')
gdb_ver=$(gdb --version 2>/dev/null | head -1 | grep -oP '[\d.]+$')
doxygen_ver=$(doxygen --version 2>/dev/null)
vim_ver=$(vim --version 2>/dev/null | head -1 | grep -oP 'IMproved \K[\d.]+')

# ── Output ───────────────────────────────────────────────────

echo ""
printf "  framework-dev %s (%s)\n" "$container_ver" "$git_commit"
echo "  ---------------------------------------------"

row "Platform"    "$(join "$(tag Ubuntu "$ubuntu_ver")" "$(tag Linux "$kernel_ver")")"
row "Compilers"   "$(join "$(tag GCC "$gcc_ver")" "$(tag CUDA "$nvcc_ver")")"
row "Build"       "$(join "$(tag CMake "$cmake_ver")" "$(tag Ninja "$ninja_ver")" "$(tag Meson "$meson_ver")" "$(tag ccache "$ccache_ver")")"
row "Analysis"    "$(join "$(tag clang-format "$clangfmt_ver")" "$(tag clang-tidy "$clangtidy_ver")" "$(tag lcov "$lcov_ver")")"
row "Python"      "$python_ver"
row "Py Packages" "$(join "$(tag vrtigo "$vrtigo_ver")" "$(tag pytest "$pytest_ver")" "$(tag scipy "$scipy_ver")")"
cont              "$(join "$(tag pyqtgraph "$pyqtgraph_ver")" "$(tag PyQt6 "$pyqt6_ver")")"
row "DAQIRI"      "$(join "$(tag DAQIRI "$daqiri_ver")" "$(tag commit "$daqiri_commit")")"
row "Networking"  "$(join "$(tag DPDK "$dpdk_ver")" "$(tag DOCA "$doca_ver")" "$(tag OFED "$ofed_ver")")"
row "GPU Libs"    "$(join "$(tag MatX "$matx_ver")" "$(tag GTest "$gtest_ver")")"
row "C++ Libs"    "$(join "$(tag Boost "$boost_ver")" "$(tag spdlog "$spdlog_ver")" "$(tag Taskflow "$taskflow_ver")")"
cont              "$(join "$(tag Poco "$poco_ver")" "$(tag yaml-cpp "$yamlcpp_ver")")"
row "Tools"       "$(join "$(tag git "$git_ver")" "$(tag gdb "$gdb_ver")" "$(tag doxygen "$doxygen_ver")" "$(tag vim "$vim_ver")")"

echo "  ---------------------------------------------"
echo ""
