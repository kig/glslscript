#!/bin/bash
# Setup script for CPU-only GLSLScript environment
# This script helps install dependencies needed for CPU execution

set -e

echo "GLSLScript CPU Environment Setup"
echo "================================="
echo ""

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
fi

echo "Detected OS: $OS"
echo ""

# Install system dependencies
echo "Installing system dependencies..."
if [ "$OS" == "linux" ]; then
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y build-essential cmake git liblz4-dev libzstd-dev glslang-tools
    elif command -v yum &> /dev/null; then
        sudo yum install -y gcc-c++ cmake git lz4-devel libzstd-devel
    else
        echo "Warning: Could not detect package manager. Please install: build-essential, cmake, git, lz4, zstd, glslang-tools"
    fi
elif [ "$OS" == "macos" ]; then
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew not found. Please install Homebrew first: https://brew.sh"
        exit 1
    fi
    brew install cmake lz4 zstd glslang
else
    echo "Warning: Unsupported OS. Please manually install: cmake, git, lz4, zstd, glslang"
fi

# Check if SPIRV-Cross is already installed
if command -v spirv-cross &> /dev/null; then
    echo ""
    echo "SPIRV-Cross is already installed: $(which spirv-cross)"
    echo "Version: $(spirv-cross --version 2>&1 | head -1 || echo 'unknown')"
    read -p "Do you want to reinstall SPIRV-Cross? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping SPIRV-Cross installation."
        echo ""
        echo "Setup complete! You can now build with: make cpu-only"
        exit 0
    fi
fi

# Install SPIRV-Cross
echo ""
echo "Installing SPIRV-Cross..."
SPIRV_CROSS_DIR="/tmp/SPIRV-Cross-install-$$"
mkdir -p "$SPIRV_CROSS_DIR"
cd "$SPIRV_CROSS_DIR"

echo "Cloning SPIRV-Cross repository..."
git clone --depth 1 https://github.com/KhronosGroup/SPIRV-Cross.git
cd SPIRV-Cross

echo "Building SPIRV-Cross..."
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

echo "Installing SPIRV-Cross..."
if [ "$EUID" -eq 0 ]; then
    make install
else
    sudo make install
fi

# Cleanup
cd /
rm -rf "$SPIRV_CROSS_DIR"

echo ""
echo "================================="
echo "Setup complete!"
echo ""
echo "SPIRV-Cross installed: $(which spirv-cross 2>/dev/null || echo 'ERROR: not found in PATH')"
echo ""
echo "Next steps:"
echo "  1. Build GLSLScript for CPU: make cpu-only"
echo "  2. Run tests: ./test/run_cpu_tests.sh"
echo "  3. Run examples: bin/gls_cpu examples/hello_1.glsl"
echo ""
