# syntax=docker/dockerfile:1
FROM ubuntu:24.04 AS builder

## set as non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

## set time zone env var
ENV TZ=Asia/Taipei

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y bash openssh-server sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## set backup password for root
RUN passwd -d root

## Delete default ubuntu user if it exists to free up UID/GID 1000
RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu || true && \
    userdel -r ubuntu || true

## create UID/GID for non-root user
ARG USERNAME=myuser
ARG UID=1001
ARG GID=1001

## Removed -o flag to ensure ID uniqueness
RUN groupadd --gid $GID $USERNAME && \
    useradd --uid $UID --gid $GID --create-home --shell /bin/bash $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/"${USERNAME}" && \
    chmod 0440 /etc/sudoers.d/"${USERNAME}" && \
    passwd -d "${USERNAME}" && \
    chown -R $UID:$GID /home/$USERNAME

# stage common_pkg_provider
FROM builder AS common_pkg_provider

## Install Python 3.11 first and set as default
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.11 python3.11-venv python3.11-dev python3.11-distutils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## Set python3.11 as default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --set python3 /usr/bin/python3.11

## Create python symlink for compatibility
RUN ln -s /usr/bin/python3 /usr/bin/python

## Install pip for Python 3.11
RUN apt-get update && \
    apt-get install -y curl && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## install vim, git, and other development tools
RUN apt-get update && \
    apt-get install -y \
        vim git wget ca-certificates \
        gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf \
        build-essential valgrind graphviz zlib1g-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## ONNX packages compatible with TVM 0.18
RUN pip3 install --no-cache-dir \
    onnx==1.14.0 \
    onnxruntime==1.15.1 \
    protobuf==3.20.3

## Install TVM dependencies
RUN pip3 install --no-cache-dir \
    decorator attrs scipy tornado psutil cloudpickle graphviz

## Install other common packages
RUN pip3 install --no-cache-dir \
    tabulate tqdm matplotlib pandas \
    numpy==1.26.4 scikit-learn \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    torch torchvision

# stage verilator_provider
FROM builder AS verilator_provider

RUN apt-get update && apt-get install -y \
    python3 git make autoconf g++ flex bison help2man && \
    git clone https://github.com/verilator/verilator.git && \
    cd verilator && \
    git checkout v5.030 && \
    autoconf && ./configure && make -j$(nproc) && make install && \
    cd .. && rm -rf verilator && \
    rm -rf /var/lib/apt/lists/*

# stage tvm_provider
FROM builder AS tvm_provider

## Install TVM build dependencies (specifically LLVM 18)
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y wget tar autoconf automake libtool gcc g++ make cmake git \
    libzstd-dev libpolly-18-dev llvm-18-dev clang-18 libclang-18-dev zlib1g-dev

## Clone and checkout TVM v0.18.0
RUN git clone https://github.com/apache/tvm tvm && \
    cd tvm && \
    git checkout v0.18.0 && \
    git submodule update --init --recursive

## Configure CMake
WORKDIR /tvm/build
RUN cp ../cmake/config.cmake . && \
    echo "set(USE_MICRO ON)" >> config.cmake && \
    echo "set(USE_MICRO_STANDALONE_RUNTIME ON)" >> config.cmake && \
    echo "set(CMAKE_BUILD_TYPE Release)" >> config.cmake && \
    echo "set(USE_LLVM \"llvm-config-18 --ignore-libllvm --link-static\")" >> config.cmake && \
    echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake

## Build TVM
RUN cmake .. && \
    cmake --build .

## Prepare installation artifacts
RUN mkdir -p /tvm_install/build && \
    cp -r /tvm/include /tvm_install/include && \
    cp -r /tvm/python /tvm_install/python && \
    cp /tvm/build/libtvm*.so /tvm_install/build && \
    cp /tvm/README.md /tvm_install/ && \
    cp /tvm/version.py /tvm_install/

# stage base to copy all other stage
FROM common_pkg_provider AS base

## create UID/GID for non-root user again in base stage
ARG USERNAME=myuser
ARG UID=1001
ARG GID=1001

## Install graphviz for visuTVM
RUN apt-get update && \
    apt-get install -y graphviz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends locales \
 && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
 && locale-gen \
 && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

COPY --from=verilator_provider /usr/local /usr/local
# Use --chown to avoid layer duplication and disk space issues
COPY --from=tvm_provider --chown=$USERNAME:$USERNAME /tvm_install /home/$USERNAME/tvm

## system authority settings
COPY ./scripts/eman.sh /usr/local/bin/eman
RUN chmod +x /usr/local/bin/eman
RUN mkdir -p /usr/local/share/eman
COPY ./scripts/celebration.txt /usr/local/share/eman/celebration.txt

RUN mkdir -p /home/"${USERNAME}"/projects && \
    chown -R $UID:$GID /home/"${USERNAME}"/projects

## Setup TVM Python path
ENV PYTHONPATH="/home/$USERNAME/tvm/python"
ENV TVM_HOME="/home/$USERNAME/tvm"

## End
USER $USERNAME
WORKDIR /home/$USERNAME

## set default shell as bash
CMD ["/bin/bash"]