#!/bin/sh
# Builds libetc2native.so for every Android ABI: arm64-v8a, armeabi-v7a, x86, x86_64.
#
# The Android NDK is NOT downloaded by this script -- it is baked into the Docker
# image (see Dockerfile.etc2native-android) and honored here via $ANDROID_NDK_HOME.
# Running it directly requires ANDROID_NDK_HOME to point at a valid NDK (r25+).
#
# The etc2comp fork is cloned fresh on every run; ETC2_REF pins the ref.
#
# Outputs (loose .so per ABI, NO tar.gz):
#   prebuilt_android_etc2native/arm64-v8a/libetc2native.so
#   prebuilt_android_etc2native/armeabi-v7a/libetc2native.so
#   prebuilt_android_etc2native/x86/libetc2native.so
#   prebuilt_android_etc2native/x86_64/libetc2native.so

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

export ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-24}"
ETC2_SRC="$SCRIPT_DIR/etc2native"
ETC2_FORK="${ETC2_FORK:-https://github.com/Shivansps/etc2comp.git}"
ETC2_REF="${ETC2_REF:-master}"
TARGET_PREBUILT_FOLDER="$SCRIPT_DIR/prebuilt_android_etc2native"
TEMP_FOLDER="$TARGET_PREBUILT_FOLDER/etc2_temp"

if [ -z "$ANDROID_NDK_HOME" ] || [ ! -f "$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" ]; then
    echo "Error: \$ANDROID_NDK_HOME is not set or does not point at a valid NDK." >&2
    echo "       It is expected to be baked into the Docker image (see" >&2
    echo "       Dockerfile.etc2native-android) or installed on the host." >&2
    exit 1
fi
echo "Using NDK at $ANDROID_NDK_HOME"

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
# Build helper: configures+builds libetc2native for one ABI.
#############################################################################
build_one() {
    abi="$1"
    build_dir="$TEMP_FOLDER/build-$abi"

    echo ""
    echo "=== Building libetc2native for Android/$abi ($ANDROID_PLATFORM) ==="
    cmake -S "$ETC2_SRC" -B "$build_dir" -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI="$abi" \
        -DANDROID_PLATFORM="$ANDROID_PLATFORM" \
        -DCMAKE_BUILD_TYPE=Release \
        -DETC2_ROOT="$ETC2_DIR"
    cmake --build "$build_dir" -j"$(nproc)"

    out_dir="$TARGET_PREBUILT_FOLDER/$abi"
    mkdir -p "$out_dir"
    cp "$build_dir"/libetc2native.so "$out_dir"/ 2>/dev/null

    if [ ! -f "$out_dir/libetc2native.so" ]; then
        echo "Error: libetc2native.so was not produced for $abi" >&2
        exit 1
    fi
    echo "-> $out_dir/libetc2native.so"
}

for abi in arm64-v8a armeabi-v7a x86 x86_64; do
    build_one "$abi"
done

#############################################################################
# Cleanup (keep per-ABI .so folders)
#############################################################################
rm -rf "$TEMP_FOLDER"

echo ""
echo "Done. Output in $TARGET_PREBUILT_FOLDER:"
find "$TARGET_PREBUILT_FOLDER" -name '*.so'
