# syntax=docker/dockerfile:1
FROM ubuntu:24.04 AS builder

## set as non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

## set time zone env var
ENV TZ=Asia/Taipei

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y bash openssh-server sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## set default shell as bash
CMD ["/bin/bash"]

## set backup password for root
RUN passwd -d root

## create UID/GID for non-root user
ARG USERNAME=myuser
ARG UID=1001
ARG GID=1001

RUN groupadd --gid $GID $USERNAME && \
    useradd --uid $UID --gid $GID --create-home --shell /bin/bash $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/"${USERNAME}" && \
    passwd -d "${USERNAME}"


# stage common_pkg_provider
FROM builder AS common_pkg_provider

ARG USERNAME=myuser

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
        build-essential valgrind graphviz && \
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
    numpy scikit-learn \
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

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y wget tar autoconf automake libtool gcc g++ make cmake git && \
    apt-get install -y libzstd-dev libpolly-18-dev llvm-18-dev clang-18 libclang-18-dev llvm-18 zlib1g-dev llvm-dev && \
    git clone https://github.com/apache/tvm tvm && \
    cd tvm && git checkout --track origin/v0.18.0 && \
    git submodule update --init --recursive && \
    mkdir build && cd build && cp ../cmake/config.cmake . &&  \
    echo "set(USE_MICRO ON)" >> config.cmake && \
    echo "set(USE_MICRO_STANDALONE_RUNTIME ON)" >> config.cmake && \
    echo "set(USE_LLVM ON)" >> config.cmake && \
    echo "set(USE_MICRO ON)" >> config.cmake && \
    echo "set(CMAKE_BUILD_TYPE RelWithDebInfo)" >> config.cmake && \
    echo "set(USE_LLVM \"llvm-config-18 --link-shared\")" >> config.cmake && \
    echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake && \
    cmake .. && cmake --build . && \
    cd /tvm && mkdir /tvm_install && \
    cp -r include /tvm_install/include && \
    cp -r python /tvm_install/python && \
    mkdir -p /tvm_install/build && \
    cp build/libtvm*.so /tvm_install/build && \
    cp README.md /tvm_install/ && \
    cp version.py /tvm_install/
    
# stage base to copy all other stage
FROM common_pkg_provider AS base

ARG USERNAME=myuser

## Install graphviz for visuTVM
RUN apt-get update && \
    apt-get install -y graphviz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=verilator_provider /usr/local /usr/local
COPY --from=tvm_provider /tvm_install /home/myuser/tvm

## system authority settings
COPY ./eman.sh /usr/local/bin/eman
RUN chmod +x /usr/local/bin/eman
RUN sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/tvm

## Setup TVM Python path
ENV PYTHONPATH="/home/$USERNAME/tvm/python"
ENV TVM_HOME="/home/$USERNAME/tvm"
## End
USER $USERNAME
WORKDIR /home/$USERNAME