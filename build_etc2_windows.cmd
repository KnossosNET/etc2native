@echo off
REM ============================================================================
REM Builds etc2native.dll (etc2comp fork + EtcCApi) for Windows x64.
REM Requirements: Visual Studio 2019/2022 (Desktop C++), CMake in PATH.
REM
REM Layout (place this .cmd, CMakeLists.txt, EtcCApi.cpp/.h together):
REM   <thisdir>\CMakeLists.txt   EtcCApi.cpp   EtcCApi.h
REM   <thisdir>\etc2comp\       
REM ============================================================================
setlocal
cd /d "%~dp0"

if not exist "etc2comp\EtcLib\Etc\Etc.h" (
  echo [ERROR] etc2comp fork not found at "%~dp0etc2comp".
  echo         Clone it FIRST:  git clone https://github.com/^<you^>/etc2comp.git etc2comp
  exit /b 1
)

REM Always reconfigure from clean to avoid a stale empty-glob cache
REM (that is what produced the ~1KB stub DLL).
if exist build_win rmdir /s /q build_win
mkdir build_win

cmake -S . -B build_win -A x64
if errorlevel 1 ( echo [ERROR] cmake configure failed & exit /b 1 )

cmake --build build_win --config Release
if errorlevel 1 ( echo [ERROR] build failed & exit /b 1 )

set "DLL=build_win\Release\etc2native.dll"
if not exist "%DLL%" ( echo [ERROR] DLL not produced & exit /b 1 )

for %%A in ("%DLL%") do set SIZE=%%~zA
echo.
echo [OK] %DLL%   (%SIZE% bytes)
echo      A healthy build is ~150-200 KB. If you see ~1 KB, the etc2comp sources
echo      were not compiled in (check the etc2comp\ folder is populated).
echo      Copy the DLL next to your app exe, or into runtimes\win-x64\native\
endlocal
