cmake_minimum_required(VERSION 3.16)
project(etc2native LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Path to a fresh etc2comp checkout (the fork). The build scripts clone it and
# pass -DETC2_ROOT=<path>. EtcCApi.cpp/.h live HERE (next to this CMakeLists),
# so the fork stays vanilla etc2comp.
set(ETC2_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/etc2comp" CACHE PATH "etc2comp fork root")

file(GLOB ETC_SRCS CONFIGURE_DEPENDS
    ${ETC2_ROOT}/EtcLib/Etc/*.cpp
    ${ETC2_ROOT}/EtcLib/EtcCodec/*.cpp)

if (NOT ETC_SRCS)
    message(FATAL_ERROR
        "No etc2comp sources under '${ETC2_ROOT}/EtcLib'. "
        "Clone the fork there or pass -DETC2_ROOT=<path>.")
endif()

add_library(etc2native SHARED
    ${ETC_SRCS}
    ${CMAKE_CURRENT_SOURCE_DIR}/EtcCApi.cpp)

# Export the C ABI even if __declspec is bypassed.
set_target_properties(etc2native PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)

target_include_directories(etc2native PRIVATE
    ${ETC2_ROOT}/EtcLib/Etc
    ${ETC2_ROOT}/EtcLib/EtcCodec
    ${CMAKE_CURRENT_SOURCE_DIR})

if (MSVC)
    target_compile_options(etc2native PRIVATE /O2 /DNDEBUG)
else()
    target_compile_options(etc2native PRIVATE -O3 -fvisibility=hidden -w)
endif()

find_package(Threads REQUIRED)
target_link_libraries(etc2native PRIVATE Threads::Threads)
