# etc2native — DDS → KTX1(ETC2) via BCnEncoder.NET + etc2comp

```
C#  : parse DDS, decode BCn -> RGBA8 (BCnEncoder.NET, managed), optional 50% resize, write KTX1
C++ : RGBA8 -> ETC2 blocks (etc2comp fork + a tiny C ABI)
```

Mapping (forceRgba8 == false): DXT1 no-alpha→ETC2_RGB, DXT1 alpha→ETC2_RGBA1,
DXT3/DXT5/BC7→ETC2_RGBA8, uncompressed→ETC2_RGBA8 (only with forceTranscodeUncompressed).
`forceRgba8` forces ETC2_RGBA8; `forceResize` halves W/H (regenerating mips); `quality`
is etc2comp effort 0..100; `jobs` is encoder threads.

## Repo layout
```
etc2native/                      
  CMakeLists.txt
  EtcCApi.cpp  EtcCApi.h 
build_etc2native_windows.cmd     <- Windows  x64 / x86 / arm64
build_etc2native_linux.sh        <- Linux    x64 / arm64 / riscv64
build_etc2native_android.sh      <- Android  arm64-v8a / armeabi-v7a / x86 / x86_64
Dockerfile.etc2native-linux
Dockerfile.etc2native-android
compose.etc2native.yaml
csharp/   
  Etc2Transcoder.cs 
```

The build scripts clone the etc2comp fork (https://github.com/Shivansps/etc2comp)
fresh on every run and build it together with `EtcCApi.cpp`. Override the source with
`ETC2_FORK=<url> ETC2_REF=<tag>`.

Output is **loose .so / .dll per arch **

## Windows
```
build_etc2native_windows.cmd
:: -> build-win-x64\Release\etc2native.dll
:: -> build-win-x86\Release\etc2native.dll
:: -> build-win-arm64\Release\etc2native.dll
```
Needs VS 2022 Desktop C++ **plus the ARM64 build tools** (Individual Components →
"MSVC v143 ARM64 build tools") for the arm64 target.

## Linux (Docker)
```
docker compose -f compose.etc2native.yaml run --rm etc2native-linux
# -> prebuilt_linux_etc2native/{x64,arm64,riscv64}/libetc2native.so
```

## Android (Docker)
```
docker compose -f compose.etc2native.yaml run --rm etc2native-android
# -> prebuilt_android_etc2native/{arm64-v8a,armeabi-v7a,x86,x86_64}/libetc2native.so
```
The image bakes NDK r29 (android-24). 

```csharp
using Etc2;
var status = Etc2Transcoder.TranscodeFile("tex.dds", "tex.ktx",
    forceRgba8: false, forceResize: true, forceTranscodeUncompressed: false,
    quality: 20, jobs: 8);
```
