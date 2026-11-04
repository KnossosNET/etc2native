#!/bin/sh
# Builds libetc2native.dylib for macOS: Apple Silicon + x86_64.
#
# etc2comp is pure C++ (no x86 intrinsics), so cross-compiling needs nothing
# special.
#
# Outputs (loose .so per arch):
#   prebuilt_macos_etc2native/libetc2native.dylib

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- '$0')" && pwd)

ETC2_SRC="$SCRIPT_DIR/etc2native"                 # project: CMakeLists.txt + EtcCApi.cpp/.h
ETC2_FORK="${ETC2_FORK:-https://github.com/Shivansps/etc2comp.git}"
ETC2_REF="${ETC2_REF:-master}"
TARGET_PREBUILT_FOLDER="$SCRIPT_DIR/prebuilt_macos_etc2native"
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
# Build helper: configures+builds libetc2native.
#############################################################################
build() {
    label="universal"
    build_dir="$TEMP_FOLDER/build-$label"

    echo ""
    echo "=== Building libetc2native for macOS ==="

    # shellcheck disable=SC2086
    cmake -S "$ETC2_SRC" -B "$build_dir" -G Ninja \
        -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" \
        -DCMAKE_BUILD_TYPE=Release \
        -DETC2_ROOT="$ETC2_DIR"
    cmake --build "$build_dir"

    out_dir="$TARGET_PREBUILT_FOLDER/$label"
    mkdir -p "$out_dir"
    cp "$build_dir"/libetc2native.dylib "$out_dir"/ 2>/dev/null

    if [ ! -f "$out_dir/libetc2native.dylib" ]; then
        echo "Error: libetc2native.dylib was not produced" >&2
        exit 1
    fi

    codesign --force --timestamp --deep --sign - "$out_dir/libetc2native.dylib" 2>/dev/null

    echo "-> $out_dir/libetc2native.dylib"
}

build

#############################################################################
# Cleanup (keep the per-arch .so folders)
#############################################################################
rm -rf "$TEMP_FOLDER"

echo ""
echo "Done. Output in $TARGET_PREBUILT_FOLDER:"
find "$TARGET_PREBUILT_FOLDER" -name '*.dylib'
