// EtcCApi.cpp - minimal C ABI added directly to the etc2comp fork.
#include "EtcCApi.h"
#include "Etc.h"
#include "EtcImage.h"
#include "EtcErrorMetric.h"
#include <vector>

extern "C" {

ETC2_API int etc2_encode_rgba8(const uint8_t* rgba, int width, int height,
                               int format, float effort, int errMetric, int jobs,
                               uint8_t** outBits, int* outBytes,
                               int* extWidth, int* extHeight)
{
    if (outBits)  *outBits = nullptr;
    if (outBytes) *outBytes = 0;
    if (!rgba || width <= 0 || height <= 0 || !outBits || !outBytes) return -1;

    Etc::Image::Format fmt;
    switch (format) {
        case 0:  fmt = Etc::Image::Format::RGB8;   break;
        case 1:  fmt = Etc::Image::Format::RGB8A1; break;
        case 2:
        default: fmt = Etc::Image::Format::RGBA8;  break;
    }
    Etc::ErrorMetric em;
    switch (errMetric) {
        case 0:  em = Etc::RGBA;    break;
        case 2:  em = Etc::NUMERIC; break;
        case 1:
        default: em = Etc::REC709;  break;
    }
    if (jobs < 1) jobs = 1;
    if (effort < 0.0f) effort = 0.0f;
    if (effort > 100.0f) effort = 100.0f;

    // etc2comp wants float RGBA in [0,1], row-major, tightly packed.
    const size_t n = (size_t)width * (size_t)height;
    std::vector<float> f(n * 4);
    const float inv = 1.0f / 255.0f;
    for (size_t i = 0; i < n * 4; ++i) f[i] = (float)rgba[i] * inv;

    unsigned char* bits = nullptr;
    unsigned int   bytes = 0, ew = 0, eh = 0;
    int            ms = 0;

    Etc::Encode(f.data(), (unsigned)width, (unsigned)height, fmt, em, effort,
                (unsigned)jobs, (unsigned)jobs,
                &bits, &bytes, &ew, &eh, &ms, false);

    if (!bits || bytes == 0) { if (bits) delete[] bits; return -3; }

    *outBits  = bits;            // owned by caller; Etc::Encode allocates with new[]
    *outBytes = (int)bytes;
    if (extWidth)  *extWidth  = (int)ew;
    if (extHeight) *extHeight = (int)eh;
    return 0;
}

ETC2_API void etc2_free(uint8_t* p) { delete[] p; }
ETC2_API const char* etc2_version(void) { return "etc2native-1.0"; }

}
