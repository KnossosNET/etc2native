#!/bin/sh
# Builds libetc2native.so for Linux: x64 (native), arm64 and riscv64 (cross).
#
# Toolchains (all baked into the Docker image, see Dockerfile.etc2native-linux):
#   x64     : host gcc/g++ (native, no cross toolchain)
#   arm64   : aarch64-linux-gnu-gcc / g++   (gcc-aarch64-linux-gnu)
#   riscv64 : riscv64-linux-gnu-gcc / g++   (gcc-riscv64-linux-gnu)
#
# etc2comp is pure C++ (no x86 intrinsics), so cross-compiling needs nothing
# special.
#
# Outputs (loose .so per arch):
#   prebuilt_linux_etc2native/x64/libetc2native.so
#   prebuilt_linux_etc2native/arm64/libetc2native.so
#   prebuilt_linux_etc2native/riscv64/libetc2native.so

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

ETC2_SRC="$SCRIPT_DIR/etc2native"                 # project: CMakeLists.txt + EtcCApi.cpp/.h
ETC2_FORK="${ETC2_FORK:-https://github.com/Shivansps/etc2comp.git}"
ETC2_REF="${ETC2_REF:-master}"
TARGET_PREBUILT_FOLDER="$SCRIPT_DIR/prebuilt_linux_etc2native"
TEMP_FOLDER="$TARGET_PREBUILT_FOLDER/etc2_temp"

if [ ! -f "$ETC2_SRC/CMakeLists.txt" ]; then
    echo "Error: expected the etc2native project at $ETC2_SRC (CMakeLists.txt, EtcCApi.cpp/.h)." >&2
    exit 1
fi

rm -rf "$TARGET_PREBUILT_FOLDER" && mkdir -p "$TARGET_PREBUILT_FOLDER" && mkdir -p "$TEMP_FOLDER"

#############################################################################
# --- Get etc2comp fork source ----------------------------------------------
#############################################################################
ETC2_DIR="$TEMP_FOLDER/etc2comp"
echo "Cloning etc2comp fork (ref: $ETC2_REF) ..."
git clone --depth 1 --branch "$ETC2_REF" "$ETC2_FORK" "$ETC2_DIR" \
    || git clone "$ETC2_FORK" "$ETC2_DIR"


#############################################################################
# Build helper: configures+builds libetc2native for one (arch, toolchain).
#   $1 = label (x64 / arm64 / riscv64)
#   $2 = CMAKE_SYSTEM_PROCESSOR (empty = native)
#   $3 = CC  (empty = native)
#   $4 = CXX (empty = native)
#############################################################################
build_one() {
    label="$1"; sysproc="$2"; cc="$3"; cxx="$4"
    build_dir="$TEMP_FOLDER/build-$label"

    echo ""
    echo "=== Building libetc2native for Linux/$label ==="

    sysname_arg=""; sysproc_arg=""; cc_arg=""; cxx_arg=""
    [ -n "$sysproc" ] && sysname_arg="-DCMAKE_SYSTEM_NAME=Linux"
    [ -n "$sysproc" ] && sysproc_arg="-DCMAKE_SYSTEM_PROCESSOR=$sysproc"
    [ -n "$cc" ]      && cc_arg="-DCMAKE_C_COMPILER=$cc"
    [ -n "$cxx" ]     && cxx_arg="-DCMAKE_CXX_COMPILER=$cxx"

    # shellcheck disable=SC2086
    cmake -S "$ETC2_SRC" -B "$build_dir" -G Ninja \
        $sysname_arg $sysproc_arg $cc_arg $cxx_arg \
        -DCMAKE_BUILD_TYPE=Release \
        -DETC2_ROOT="$ETC2_DIR"
    cmake --build "$build_dir" -j"$(nproc)"

    out_dir="$TARGET_PREBUILT_FOLDER/$label"
    mkdir -p "$out_dir"
    cp "$build_dir"/libetc2native.so "$out_dir"/ 2>/dev/null

    if [ ! -f "$out_dir/libetc2native.so" ]; then
        echo "Error: libetc2native.so was not produced for $label" >&2
        exit 1
    fi
    echo "-> $out_dir/libetc2native.so"
}

build_one "x64"     ""        ""                      ""
build_one "arm64"   "aarch64" "aarch64-linux-gnu-gcc" "aarch64-linux-gnu-g++"
build_one "riscv64" "riscv64" "riscv64-linux-gnu-gcc" "riscv64-linux-gnu-g++"

#############################################################################
# Cleanup (keep the per-arch .so folders)
#############################################################################
rm -rf "$TEMP_FOLDER"

echo ""
echo "Done. Output in $TARGET_PREBUILT_FOLDER:"
find "$TARGET_PREBUILT_FOLDER" -name '*.so'
