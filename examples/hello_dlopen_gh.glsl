#!/usr/bin/env gls

#include <file.glsl>
#include <https://raw.githubusercontent.com/kig/spirv-wasm/12f2554994f5b733da65e6705099e2afd160649c/spirv-io/lib/dlopen.glsl> @ 4b43671ba494238b3855c2990c2cd844573a91d15464ed8b77d2a5b98d0eb2e1

ThreadLocalCount = 1;
ThreadGroupCount = 1;

writeSync("hello.c", "#include <stdio.h>\nvoid hello(char* s){printf(\"Hello, %s!\\n\",s);}\nvoid sub(int* v, unsigned int vlen, int* res, unsigned int reslen) { res[0] = v[0]-v[1]; }");
awaitIO(runCmd("cc --shared -o hello.so hello.c"));
uint64_t lib = dlopenSync("./hello.so");
dlcallSync(lib, "hello", "GLSL\u0000", string(-4,-4));
alloc_t params = malloc(8);
i32heap[params.x/4] = 7;
i32heap[params.x/4+1] = 12;
alloc_t res = dlcallSync(lib, "sub", params, malloc(4));
int32_t subResult = readI32heap(res.x);
println(concat(str(i32heap[params.x/4]), " - ", str(i32heap[params.x/4+1]), " = ", str(subResult)));
