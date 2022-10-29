FROM dualvtable/vulkan-sample:latest
RUN apt-key del 7fa2af80 \
    && rm /etc/apt/sources.list.d/cuda.list
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb \
    && dpkg -i cuda-keyring_1.0-1_all.deb
RUN apt-get update && apt-get install -y cpp glslang-tools liblz4-dev libzstd-dev lsb-release wget software-properties-common gnupg curl make
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs
RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
WORKDIR /app
COPY . /app
RUN make install
CMD ["gls", "/app/examples/hello_1.glsl"]
