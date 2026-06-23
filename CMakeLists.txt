cmake_minimum_required(VERSION 3.16)
project(etc2native LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Point this at your etc2comp fork checkout.
set(ETC2_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/etc2comp" CACHE PATH "etc2comp fork root")

file(GLOB ETC_SRCS CONFIGURE_DEPENDS
    ${ETC2_ROOT}/EtcLib/Etc/*.cpp
    ${ETC2_ROOT}/EtcLib/EtcCodec/*.cpp)

if (NOT ETC_SRCS)
    message(FATAL_ERROR
        "No etc2comp sources found under '${ETC2_ROOT}/EtcLib'. "
        "Clone your etc2comp fork there, or pass -DETC2_ROOT=<path>.")
endif()

add_library(etc2native SHARED
    ${ETC_SRCS}
    ${CMAKE_CURRENT_SOURCE_DIR}/EtcCApi.cpp)

# Belt-and-suspenders: export the C ABI even if __declspec slips (e.g. /D overrides).
set_target_properties(etc2native PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)

target_include_directories(etc2native PRIVATE
    ${ETC2_ROOT}/EtcLib/Etc
    ${ETC2_ROOT}/EtcLib/EtcCodec
    ${CMAKE_CURRENT_SOURCE_DIR})

# Speed: release + NDEBUG. (EtcConfig.h does #undef NDEBUG to keep asserts on during
# development; for max throughput remove that line in your fork, or override here.)
if (MSVC)
    target_compile_options(etc2native PRIVATE /O2 /fp:fast /DNDEBUG)
else()
    target_compile_options(etc2native PRIVATE -O3 -ffast-math -fvisibility=hidden -w)
endif()

find_package(Threads REQUIRED)
target_link_libraries(etc2native PRIVATE Threads::Threads)

# Optional: round-trip validation harness (needs Compressonator for ETC2 decode).
option(BUILD_ETC_TEST "Build the encode validation test" OFF)
if (BUILD_ETC_TEST)
    add_executable(etc2_test ${CMAKE_CURRENT_SOURCE_DIR}/etc2_test.cpp
        ${ETC_SRCS} ${CMAKE_CURRENT_SOURCE_DIR}/EtcCApi.cpp ${CMP_TEST_SRCS})
    target_include_directories(etc2_test PRIVATE
        ${ETC2_ROOT}/EtcLib/Etc ${ETC2_ROOT}/EtcLib/EtcCodec
        ${CMAKE_CURRENT_SOURCE_DIR} ${CMP_TEST_INCS})
    target_compile_definitions(etc2_test PRIVATE _LINUX)
    target_compile_options(etc2_test PRIVATE -O2 -w)
    target_link_libraries(etc2_test PRIVATE Threads::Threads)
endif()
