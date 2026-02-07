# Contributing to GLSLScript

Thank you for your interest in contributing to GLSLScript! This guide will help you get started with development and testing.

## Development Environment

### GPU Development (Full Features)
For GPU development with Vulkan support, follow the installation instructions in the main README.md.

### CPU-Only Development (Testing & Compatibility)
For development without GPU or on diverse hardware platforms, use the CPU-only setup:

```bash
# Quick setup
./scripts/setup_cpu_env.sh

# Or manual setup - see CPU_TESTING.md
```

## Testing Your Changes

### Running Tests Locally

**With GPU:**
```bash
make
# Run specific tests with gls
```

**Without GPU (CPU only):**
```bash
make cpu-only
./test/run_cpu_tests.sh
```

### Docker Testing

**GPU version:**
```bash
docker build -t glslscript .
docker run --gpus all --rm -it glslscript gls examples/hello_1.glsl
```

**CPU version:**
```bash
docker build -f Dockerfile.cpu -t glslscript-cpu .
docker run --rm -it glslscript-cpu gls_cpu examples/hello_1.glsl
```

## Continuous Integration

The project uses GitHub Actions for automated testing:
- `.github/workflows/cpu-tests.yml` - CPU-only tests (runs on all PRs)

CPU tests run on every push and pull request, ensuring compatibility across platforms.

## Code Structure

- `src/` - C++ runtime and I/O loop
  - `gls.cpp` - GPU version entry point
  - `gls_cpu.cpp` - CPU version entry point  
  - `compute_application.hpp` - Vulkan GPU implementation
  - `cpu_compute_application.hpp` - CPU implementation using SPIRV-Cross
  - `io_loop.hpp` - I/O request handling (shared)
  - `parse_spv.hpp` - SPIR-V parser (shared)

- `lib/` - GLSL library code
  - `file.glsl` - File I/O operations
  - `string.glsl` - String manipulation
  - `array.glsl` - Dynamic arrays
  - `hashtable.glsl` - Hash table implementation
  - `malloc.glsl` - Memory allocation
  - And more...

- `bin/` - Build scripts
  - `glsl2spv` - Compiles GLSL to SPIR-V
  - `gls_preprocess.js` - Preprocessor
  - `gls_resolve_includes.js` - Include resolution

- `test/` - Test files
  - `test_*.glsl` - Unit tests for various features
  - `run_cpu_tests.sh` - Automated test runner for CPU

- `examples/` - Example programs

## Compatibility Goals

GLSLScript aims to work reliably on diverse hardware:
- ✅ NVIDIA GPUs (primary target)
- ✅ CPU (via SPIRV-Cross transpilation)
- 🔄 AMD GPUs (Vulkan support)
- 🔄 Intel GPUs (Vulkan support)
- 🔄 Apple Metal/MPS (future)
- 🔄 Raspberry Pi (CPU mode)
- 🔄 Mobile (Termux, CPU mode)

The CPU implementation enables testing and development on any platform, making the project more accessible.

## Making Changes

### For Library Code (`lib/`)
1. Make your changes to GLSL library files
2. Test with both GPU and CPU versions if possible
3. Add or update tests in `test/`
4. Ensure existing tests pass

### For Runtime Code (`src/`)
1. Consider impact on both GPU and CPU implementations
2. Test compilation on both paths
3. Update error messages to be helpful
4. Document any new dependencies

### For Build System
1. Maintain compatibility with both `gls` and `gls_cpu` targets
2. Test on Linux and macOS if possible
3. Update documentation for any new requirements

## Pull Request Guidelines

1. **Test your changes:**
   - Run `./test/run_cpu_tests.sh` for CPU tests
   - Test manually with example programs
   - Verify both debug and release builds

2. **Document your changes:**
   - Update README.md if user-facing
   - Update CPU_TESTING.md for compatibility changes
   - Add code comments for complex logic

3. **Keep changes focused:**
   - One feature or fix per PR
   - Avoid unrelated refactoring
   - Maintain backward compatibility when possible

4. **Write clear commit messages:**
   - Describe what and why, not just how
   - Reference issues if applicable

## Getting Help

- Check existing issues for similar problems or questions
- Review the README.md and CPU_TESTING.md documentation
- Look at example programs in `examples/`
- Examine test files in `test/` for usage patterns

## Performance Considerations

- GPU version: Optimized for thousands of parallel threads
- CPU version: Sequential execution, mainly for testing
- Keep shader complexity reasonable for both modes
- Document performance-critical code

## Code Style

- Follow the existing code style in the file you're editing
- C++ code: Modern C++17 style
- GLSL code: Follow GLSL conventions
- Shell scripts: POSIX-compatible when possible

## License

By contributing, you agree that your contributions will be licensed under the same MIT license as the project.

---

Thank you for contributing to GLSLScript! Your efforts help make GPU computing more accessible.
