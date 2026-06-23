// EtcCApi.h - minimal C ABI added directly to the etc2comp fork.
// Encodes an 8-bit RGBA image to ETC2. Drop this (and EtcCApi.cpp) into the fork.
#pragma once
#include <stdint.h>

#if defined(_WIN32)
  #define ETC2_API __declspec(dllexport)
#else
  #define ETC2_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// format:    0 = ETC2_RGB   (etc2comp RGB8,   8 bytes/block)
//            1 = ETC2_RGBA1 (etc2comp RGB8A1, 8 bytes/block, 1-bit punch-through)
//            2 = ETC2_RGBA8 (etc2comp RGBA8, 16 bytes/block, EAC alpha)
// errMetric: 0 = RGBA, 1 = REC709 (perceptual, good default for color), 2 = NUMERIC
// effort:    0..100 (higher = better quality, slower)
// jobs:      worker threads inside the encoder (1 = single-threaded). You can also
//            just call this from multiple C# threads with jobs=1 for max throughput.
//
// On success (return 0) *outBits points to newly allocated ETC2 data of *outBytes
// bytes; free it with etc2_free(). *extWidth/*extHeight are the 4-aligned dimensions
// the blocks cover (equal to width/height when those are multiples of 4).
ETC2_API int  etc2_encode_rgba8(const uint8_t* rgba, int width, int height,
                                int format, float effort, int errMetric, int jobs,
                                uint8_t** outBits, int* outBytes,
                                int* extWidth, int* extHeight);

ETC2_API void etc2_free(uint8_t* p);
ETC2_API const char* etc2_version(void);

#ifdef __cplusplus
}
#endif
