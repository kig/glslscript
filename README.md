### Crash

GLSL as a scripting language? Say no more!

Crash is a super not production-ready asynchronous IO runtime and module system for Vulkan compute shaders.

With crash, your compute shaders can tell your CPU to do arbitrary IO:

 * Print strings (the crash GLSL preprocessor adds strings to GLSL)
 * Read from files and write to files
 * Listen on network sockets
 * Tell the current time
 * dlopen CPU libraries and call functions in them
 * Run commands and await their completion

The example scripts in [examples/](examples/) show you how to do various things, such as:

 * [hello_1.glsl](examples/hello_1.glsl) - Single-threaded "Hello, World!" 
 * [wait_for_stdin.glsl](examples/wait_for_stdin.glsl) - Prompt the user for a string and respond.
 * [hello_dlopen.glsl](examples/hello_dlopen.glsl) - How to compile a C shared library and call functions in it.
 * [memalloc.glsl](examples/memalloc.glsl) - Allocate memory on the CPU side, write to it and read from it.
 * [delz4.glsl](examples/delz4.glsl) - An LZ4 decompressor.
 * [grep.glsl](examples/grep.glsl) - grep that can run at 20 GB/s over PCIe3 x16 using LZ4-compressed data transfers.
 * [listen3.glsl](examples/listen3.glsl) - A simple HTTP server.


## Try it out

The easiest way to try out crash is with Docker.

```bash
git clone https://github.com/kig/crash
cd crash
docker build -t crash .
docker run --gpus all --ipc host --rm -it crash crash examples/hello_1.glsl
```


## Install

The easiest way is to use the [Dockerfile](Dockerfile), but you can set up a local dev environment by doing what it does:

```bash
# Install libnvidia-gl and other deps
apt-get install libnvidia-gl-520 libvulkan-dev cpp glslang-tools liblz4-dev libzstd-dev lsb-release wget software-properties-common gnupg curl make
# Install nodejs (the preprocessor is written in JavaScript)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs
# Install LLVM
bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
# Install Crash
git clone https://github.com/kig/crash
cd crash
make install
crash examples/hello_1.glsl
```


## Develop

The [lib/](lib/) dir has the core language libraries for strings, arrays, hashtables, files, malloc, lz4 decompression, and other things you may need.

The [src/](src/) dir has the CPU-side IO runtime.

The core IO loop is in [io_loop.hpp](src/io_loop.hpp) and works by spawning a pool of threads that read requests from the GPU and write back responses.

There's a simple SPIR-V parser in [parse_spv.hpp](src/parse_spv.hpp) to set runtime parameters and initial memory contents based on the data in the SPIR-V file.

Finally, [compute_application.hpp](src/compute_application.hpp) has all the Vulkan boilerplate for allocating IO buffers and running the thing.


## Why the name "Crash"

Have _you_ tried developing an IO runtime for Vulkan compute shaders? [1]

It's crashingly fast! From zero to done in a crash. Imagine being bottlenecked by ridiculously high-bandwidth things as you crash through your problems.

[1] There's no mid-shader CPU-GPU synchronization out-of-the-box. Shaders are designed to run for just a few milliseconds at a time.
To get around this, you can spin on a shared buffer.

The GPU does a request by writing the params to the request buffer, and increments the request count. The CPU keeps checking the request count for changes.
When it sees a change, it reads the request params and runs the request. After running the request, the CPU writes the results to the response buffer.

The GPU spins and waits for the request status flag to be set to completed. After the request is completed, the GPU reads the response from the response
buffer, sets the request status flag to handled, and goes on its merry way.

So far, so good. What if you couldn't trust the order of the writes and reads above? What if cache lines in your memory buffer were getting transported over UDP.


## License

MIT
