CPP ?= clang++
CFLAGS := -m64 -march=native -mtune=native -std=c++17 -I../include -O2
LDFLAGS := -ldl -llz4 -lzstd -lvulkan -lpthread
LDFLAGS_CPU := -ldl -llz4 -lzstd -lpthread

gls:
	$(CPP) $(CFLAGS) $(LDFLAGS) -o bin/gls src/gls.cpp

gls_cpu:
	$(CPP) $(CFLAGS) $(LDFLAGS_CPU) -o bin/gls_cpu src/gls_cpu.cpp

install: gls
	install -d $(DESTDIR)$(PREFIX)/lib/spirv-io
	install -m 644 lib/* $(DESTDIR)$(PREFIX)/lib/spirv-io
	install -d $(DESTDIR)$(PREFIX)/bin/
	install -m 755 bin/* $(DESTDIR)$(PREFIX)/bin/

all: gls

# CPU-only build target for environments without GPU/Vulkan support
cpu-only: gls_cpu

.PHONY: all install cpu-only gls gls_cpu
