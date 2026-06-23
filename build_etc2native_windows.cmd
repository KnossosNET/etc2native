@echo off
setlocal

cd /d "%~dp0"

REM ===========================================================================
REM Builds etc2native.dll for Windows x64, x86 and ARM64.
REM Clones the etc2comp fork into etc2native\etc2comp and builds the project
REM in etc2native\ (its CMakeLists picks up etc2comp via the default ETC2_ROOT).
REM Requires: Visual Studio 2022 (Desktop C++ + the ARM64 build tools), CMake.
REM Output DLLs are left in build-win-<arch>\Release\etc2native.dll
REM ===========================================================================

set "FORK=https://github.com/Shivansps/etc2comp.git"

echo ========================================
echo Cleanup
echo ========================================
if exist "etc2native\etc2comp" rmdir /s /q "etc2native\etc2comp"
if exist "build-win-x64"   rmdir /s /q "build-win-x64"
if exist "build-win-x86"   rmdir /s /q "build-win-x86"
if exist "build-win-arm64" rmdir /s /q "build-win-arm64"

echo ========================================
echo Cloning etc2comp fork...
echo ========================================
git clone --depth 1 "%FORK%" "etc2native\etc2comp"
if errorlevel 1 goto :error

echo ========================================
echo Build x64...
echo ========================================
cmake -S "./etc2native" -B "build-win-x64" -G "Visual Studio 17 2022" -A x64
if errorlevel 1 goto :error
cmake --build "build-win-x64" --config Release
if errorlevel 1 goto :error

echo ========================================
echo Build x86...
echo ========================================
cmake -S "./etc2native" -B "build-win-x86" -G "Visual Studio 17 2022" -A Win32
if errorlevel 1 goto :error
cmake --build "build-win-x86" --config Release
if errorlevel 1 goto :error

echo ========================================
echo Build ARM64...
echo ========================================
cmake -S "./etc2native" -B "build-win-arm64" -G "Visual Studio 17 2022" -A ARM64
if errorlevel 1 goto :error
cmake --build "build-win-arm64" --config Release
if errorlevel 1 goto :error

echo.
echo ========================================
echo BUILD COMPLETED
echo   build-win-x64\Release\etc2native.dll
echo   build-win-x86\Release\etc2native.dll
echo   build-win-arm64\Release\etc2native.dll
echo ========================================
if exist "etc2native\etc2comp" rmdir /s /q "etc2native\etc2comp"
pause
exit /b 0

:error
echo.
echo ========================================
echo ERROR
echo ========================================
pause
exit /b 1
