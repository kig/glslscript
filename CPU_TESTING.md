# CPU Testing Guide for GLSLScript

This guide explains how to test GLSLScript on CPU-only environments without GPU or Vulkan support.

## Overview

GLSLScript can run in CPU-only mode using SPIRV-Cross to transpile SPIR-V compute shaders to C++ and execute them natively on the CPU. This is useful for:

- Testing on systems without GPU support (CI/CD, cloud environments)
- Development on systems without Vulkan drivers
- Compatibility testing across different hardware
- Running on diverse platforms (Raspberry Pi, mobile devices, etc.)

## Platform Compatibility

GLSLScript CPU mode has been tested or is expected to work on:

### Tested Platforms
- **Ubuntu/Debian Linux** - Full support with apt-get packages
- **macOS** - Support via Homebrew

### Expected to Work
- **Raspberry Pi** (Raspbian/Ubuntu) - ARM CPU support via SPIRV-Cross
- **Alpine Linux** - Minimal Linux environments
- **WSL2** (Windows Subsystem for Linux) - Windows development
- **Termux** (Android) - Mobile development and testing

### Platform-Specific Notes

#### Raspberry Pi
```bash
# Install dependencies
sudo apt-get install build-essential cmake git liblz4-dev libzstd-dev nodejs

# Follow normal SPIRV-Cross installation from source
# Binary packages may not be available for ARM
```

#### macOS (Apple Silicon)
```bash
# SPIRV-Cross should build natively for ARM64
brew install cmake lz4 zstd glslang

# Then build SPIRV-Cross from source as shown in Prerequisites
```

#### WSL2
```bash
# Use Ubuntu instructions
# No GPU passthrough needed for CPU mode
```

#### Termux (Android)
```bash
# Install dependencies via pkg
pkg install clang cmake git lz4 zstd nodejs

# Build SPIRV-Cross from source
# May need to adjust compiler flags for Android
```

## Prerequisites

For CPU-only testing, you need:

1. **C++ compiler**: clang++ or g++ with C++17 support
2. **Build tools**: make
3. **SPIRV-Cross**: For transpiling SPIR-V to C++
   ```bash
   # Install SPIRV-Cross
   git clone https://github.com/KhronosGroup/SPIRV-Cross
   cd SPIRV-Cross
   mkdir build && cd build
   cmake ..
   make
   sudo make install
   ```
4. **Dependencies**: lz4, zstd
   ```bash
   # Ubuntu/Debian
   sudo apt-get install liblz4-dev libzstd-dev
   
   # macOS
   brew install lz4 zstd
   ```
5. **Node.js**: For the preprocessor
6. **glslang tools**: For compiling GLSL to SPIR-V
   ```bash
   # Ubuntu/Debian
   sudo apt-get install glslang-tools
   ```

## Building for CPU-only

To build the CPU-only version without Vulkan dependencies:

```bash
make cpu-only
```

This creates `bin/gls_cpu` which runs shaders on the CPU.

## Running Tests on CPU

### Basic Test

```bash
# Run a simple example
bin/gls_cpu examples/hello_1.glsl
```

### Running Test Suite

The test files in `test/` directory can be run on the CPU:

```bash
# String tests
bin/gls_cpu test/test_string.glsl

# Array tests  
bin/gls_cpu test/test_array.glsl

# Hashtable tests
bin/gls_cpu test/test_hashtable.glsl

# File I/O tests
bin/gls_cpu test/test_file.glsl
```

## How CPU Execution Works

1. **Compilation**: GLSL source is compiled to SPIR-V using glslang
2. **Transpilation**: SPIRV-Cross converts SPIR-V to C++ code
3. **Compilation**: The C++ code is compiled to a shared library
4. **Execution**: The shared library is loaded and executed with the I/O runtime

The CPU runtime simulates compute shader execution by:
- Emulating work groups and local invocations
- Providing the same buffer interfaces as the GPU version
- Running the same I/O request handling loop

## Performance Considerations

CPU execution is significantly slower than GPU execution:
- No hardware parallelism across thousands of threads
- Sequential execution of work groups
- Memory access patterns optimized for GPU may be inefficient on CPU

For testing purposes, reduce the thread counts:
```glsl
ThreadLocalCount = 1;
ThreadGroupCount = 1;
```

## Limitations

Current CPU implementation limitations:
- Requires SPIRV-Cross to be installed separately
- No built-in parallel execution across CPU cores
- Some GPU-specific optimizations don't apply
- Shader compilation to C++ adds overhead

## Troubleshooting

### SPIRV-Cross not found
If you get errors about missing `spirv_cross` headers, ensure SPIRV-Cross is installed and headers are in the include path.

### Compilation errors
The transpiled C++ may have compatibility issues. Try:
- Updating SPIRV-Cross to the latest version
- Checking shader for GPU-specific features that don't translate to CPU

### Slow execution
This is expected on CPU. Reduce work group counts for testing:
```glsl
ThreadGroupCount = 1;
ThreadLocalCount = 1;
```

## Future Improvements

Planned enhancements for CPU compatibility:
- [ ] Bundle SPIRV-Cross or provide automated setup
- [ ] Add multi-threaded CPU execution using thread pools
- [ ] SIMD optimization for CPU execution (ISPC-style)
- [ ] Better error messages for CPU-specific issues
- [ ] Automated test runner for the test suite

## Continuous Integration

A GitHub Actions workflow is provided at `.github/workflows/cpu-tests.yml` that demonstrates CPU-only testing without GPU requirements. This workflow:
- Installs all dependencies including SPIRV-Cross
- Builds the CPU version
- Runs the test suite
- Validates basic functionality

This serves as a reference for setting up CI/CD pipelines on platforms like:
- GitHub Actions
- GitLab CI
- CircleCI
- Travis CI
- Jenkins

The CPU mode enables testing on any CI platform, regardless of GPU availability.

