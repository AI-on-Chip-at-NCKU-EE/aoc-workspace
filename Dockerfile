# syntax=docker/dockerfile:1
FROM ubuntu:24.04 AS builder

## set as non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

## set time zone env var
ENV TZ=Asia/Taipei

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y bash openssh-server sudo

## set default shell as bash
CMD ["/bin/bash"]

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

## install vim, git and pip
RUN apt-get update && apt-get install -y \
    vim git curl wget ca-certificates build-essential \
    python3 python3-pip python3-venv \
    valgrind && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## Create virtual environment for Python packages
RUN python3 -m venv /opt/venv

## install ONNX runtime, utilities, and PyTorch (CPU version)
RUN /opt/venv/bin/pip install --no-cache-dir \
    onnx \
    onnxruntime \
    tabulate \
    tqdm \
    matplotlib \
    pandas \
    numpy \
    scikit-learn \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    torch \
    torchvision

## Add venv to PATH so installed packages are available globally
ENV PATH="/opt/venv/bin:$PATH"

## install conda according to cpu's ISA
ARG CONDA_DIR=/opt/conda

RUN apt-get update && apt-get install -y bzip2 && \
    ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64)  URL=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh ;; \
      aarch64) URL=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh ;; \
      *)       echo "Unsupported arch $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL $URL -o miniconda.sh && \
    bash miniconda.sh -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    ln -s $CONDA_DIR/etc/profile.d/conda.sh /etc/profile.d/conda.sh

# stage verilator_provider
FROM builder AS verilator_provider

RUN apt-get update && apt-get install -y \
    python3 python3-pip git make autoconf g++ flex bison help2man && \
    git clone https://github.com/verilator/verilator.git && \
    cd verilator && \
    git checkout v5.030 && \
    autoconf && ./configure && make -j$(nproc) && make install && \
    cd .. && rm -rf verilator && \
    rm -rf /var/lib/apt/lists/*

# stage systemc_provider
FROM builder AS systemc_provider

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y wget tar autoconf automake libtool g++ make && \
    wget https://github.com/accellera-official/systemc/archive/refs/tags/2.3.4.tar.gz && \
    tar -xzf 2.3.4.tar.gz && \
    cd systemc-2.3.4 && \
    mkdir objdir && autoreconf -i && cd objdir && \
    ../configure --prefix=/opt/systemc-2.3.4 && \
    make -j$(nproc) && make install && \
    cd ../.. && rm -rf 2.3.4.tar.gz && rm -rf systemc-2.3.4 && \
    rm -rf /var/lib/apt/lists/*

ENV SYSTEMC_HOME=/opt/systemc-2.3.4

# stage base to copy all other stage
FROM common_pkg_provider AS base

COPY --from=verilator_provider /usr/local /usr/local
COPY --from=systemc_provider /opt/systemc-2.3.4 /opt/systemc-2.3.4

COPY ./eman.sh /usr/local/bin/eman
RUN chmod +x /usr/local/bin/eman

ENV SYSTEMC_HOME=/opt/systemc-2.3.4

USER $USERNAME

WORKDIR /home/$USERNAME

RUN $CONDA_DIR/bin/conda init --all

RUN echo 'export PATH="/opt/venv/bin:$PATH"' >> ~/.bashrc