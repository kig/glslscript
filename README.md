### Crash

GLSL as a scripting language? Say no more!

Crash is a super not production-ready asynchronous IO runtime and module system for Vulkan compute shaders.

## What does it look like?

```glsl
#include <file.glsl>
#include <parallel.glsl>

void main() {
    if (ThreadId == 0) {
        println("Hello from crash!");
        println(`We are running on ${ThreadLocalCount * ThreadGroupCount} threads across ${ThreadGroupCount} thread groups. Let me introduce the first four thread groups.`);
    }
    globalBarrier();
    if (ThreadGroupId < 4 && ThreadLocalId % 16 == 0) {
        println(`Thread ${ThreadId} from thread group ${ThreadGroupId}[${ThreadLocalId}] checking in.`);
    }
    globalBarrier();
    if (ThreadId == 0) {
        println("What's your name?");
        FREE_ALL(
            string name = awaitIO(readLine(stdin, malloc(256)));
            println(`Hello ${name}!`);
        )
    }
}
```

Output
```
Hello from crash!
We are running on 16384 threads across 256 thread groups. Let me introduce the first four thread groups.
Thread 0 from thread group 0[0] checking in.
Thread 16 from thread group 0[16] checking in.
Thread 224 from thread group 3[32] checking in.
Thread 240 from thread group 3[48] checking in.
Thread 160 from thread group 2[32] checking in.
Thread 176 from thread group 2[48] checking in.
Thread 32 from thread group 0[32] checking in.
Thread 64 from thread group 1[0] checking in.
Thread 48 from thread group 0[48] checking in.
Thread 80 from thread group 1[16] checking in.
Thread 128 from thread group 2[0] checking in.
Thread 192 from thread group 3[0] checking in.
Thread 144 from thread group 2[16] checking in.
Thread 208 from thread group 3[16] checking in.
Thread 96 from thread group 1[32] checking in.
Thread 112 from thread group 1[48] checking in.
What's your name?
John
Hello John!

```

## Features

With crash, your compute shaders can tell your CPU to do arbitrary IO:

 * Print strings
 * Read from files and write to files
 * Run commands and await their completion
 * Listen on network sockets
 * Tell the current time
 * Allocate memory on the CPU side and do reads and writes to it
 * dlopen CPU libraries and call functions in them

Extra language features

 * Asynchronous IO `alloc_t buf = malloc(1024); io r = read("myfile.txt", buf); awaitIO(r); awaitIO(write("mycopy.txt", buf));`
 * Strings `string s = "foobar"; string s2 = str(vec3(0.0, 1.0, 2.0)); string s3 = concat(s1, " = ", s2); awaitIO(println(s3));`
 * Multi-line template strings with backticks `` `foo ${bar}` ``
 * Character literals `'x'` and int32 literals `'\x89PNG'`
 * Dynamically allocated arrays `i32array a = i32{1,2,3}; i32array b = i32{4,5}; i32array ab = i32concat(a,b);`
 * String and Array libraries that mostly match JavaScript, with some Pythonic `str()` thrown in.
 * Hashtables `i32map h = i32hAlloc(256); i32hSet(h, 12891, 23); println(str(i32hGet(h, 12891) == 23));`
 * Malloc that works by bumping a heap pointer and a FREE() macro to free all memory allocated inside it `FREE(alloc_t ptr = malloc(4));`
 * A second heap for IO to make life complicated: `FREE(alloc_t buf = malloc(1024); FREE_IO(readSync("myfile.txt", buf)); println(buf));`
 * And a macro to free both heaps at the same time: `FREE_ALL(alloc_t buf = malloc(1024); readSync("myfile.txt", buf); println(buf));`
 * Set warp width and warp count from GLSL: `ThreadLocalCount = 64; ThreadGroupCount = 256;`
 * By default, crash programs run across 16384 threads. A naive hello world will fill your screen with hellos. Use ThreadId to limit it to a single thread `if (ThreadId == 0) println("Hello, World!");` 
 * Set heap size per thread, per thread group and total program heap `HeapSize = 4096; GroupHeapSize = HeapSize * ThreadLocalCount; TotalHeapSize = GroupHeapSize * ThreadGroupCount;`
 * An `#include <file.glsl>` system powered by the C preprocessor.
 * That also loads things over HTTPS with SHA256 integrity verification `#include <https://raw.githubusercontent.com/kig/spirv-wasm/12f2554994f5b733da65e6705099e2afd160649c/spirv-io/lib/dlopen.glsl> @ 4b43671ba494238b3855c2990c2cd844573a91d15464ed8b77d2a5b98d0eb2e1`

## Examples

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
What if the driver killed your compute shaders after 10 seconds. Since clearly it has hung, right? Who would wait for user input in a shader? Crash, that's who!


## License

MIT
