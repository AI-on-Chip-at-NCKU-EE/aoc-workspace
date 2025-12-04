# AOC Lab0 - Course Environment Guidance

## Cloud-based Notebook Environments

### What are Cloud-based Environments?

### Colab

### Kaggle

## Docker

### Introduction

Before diving into technical details, let's understand why we need Docker. The most common headache in software development is when code works perfectly on a developer's machine but fails when deployed to a server. This is usually due to differences in operating systems or library dependencies.

Docker solves this by ensuring applications run exactly the same way in any environment.

**Evolution**

*   Bare Metal: Early days. One OS per server. Wasteful resources and difficult to migrate.
*   Virtual Machines (VM): Simulates multiple computers on one machine. Solves resource allocation but requires a full Guest OS for each VM, making them heavy (GBs) and slow to start.
*   Containerization (Docker): Containers share the Host OS kernel. No full OS installation needed, making them lightweight (MBs) and instant to start.

**Core Concepts: Image vs. Container**

Think of them as "Mold" vs. "Product":

*   Image (Recipe): A read-only template containing code, runtime, and libraries. It's like a cake recipe or a game installation disc.
*   Container (Cake): A running instance created from an Image. You can modify files inside a container without affecting the original image. It's like the cake baked from the recipe or the running game.

**Workflow**

1.  Build: Create an Image from a Dockerfile.
2.  Ship: Upload the Image to a registry.
3.  Run: Download and start the Container on any machine.

### File Structure

```text
lab-0/
├── Dockerfile          # Docker image definition
├── docker.sh           # Docker container management script
├── eman.sh             # Environment testing tool
├── README.md           # Documentation
├── .gitignore          # Git ignore file
├── test/               # Test files directory
│   ├── c-compiler/     # C/C++ compilation tests
│   └── verilator/      # Verilator tests
└── workspace/          # User workspace for future labs
    ├── lab1/
    ├── lab2/
    └── ...
```

### Prerequisites

1.  **Install Docker Desktop**
    - [Windows Download](https://www.docker.com/products/docker-desktop)
    - [macOS Download](https://www.docker.com/products/docker-desktop)

2.  **WSL 2 Setup** (Windows only)
    - Ensure WSL 2 is installed and enabled.
    - Enable WSL 2 integration in Docker Desktop settings.

3.  **Verify Docker is running**
    ```bash
    docker version
    ```

### Memory Configuration

**Overview**
When using Docker Desktop with WSL 2 on Windows, resource allocation is managed via a `.wslconfig` file. By default, WSL 2 allocates **50% of RAM** or **8GB** (whichever is less), which is often insufficient for compiling large projects like TVM or Verilator.

**Why Configure?**
This environment compiles several heavy components (TVM, Verilator, PyTorch), with a peak memory requirement of **~8-10GB**. The default limit may cause builds to fail.

**Configuration Steps**
1.  Open PowerShell and run:
    ```powershell
    notepad $env:USERPROFILE\.wslconfig
    ```
    (Click "Yes" to create if it doesn't exist)

2.  Add the following settings based on your system RAM:

    **For 16GB RAM systems (Recommended):**
    ```ini
    [wsl2]
    memory=10GB
    processors=6
    swap=4GB
    ```

    **For 32GB+ RAM systems:**
    ```ini
    [wsl2]
    memory=16GB
    processors=8
    swap=8GB
    ```

### Setup Procedure

We have provided a script `docker.sh` to simplify the management of your Docker environment. While it looks like a simple "Start" button, it performs several critical Docker operations for you.

**1. Launch Container**
```bash
./docker.sh run
```

**What happens when you run this?**

When you execute this command, the script first checks if the `aoc2026-env` image exists. If the image is missing, it automatically runs `docker build` to create it from the `Dockerfile`, constructing your environment with all necessary compilers and libraries.

Next, it checks the status of the `aoc2026-container`. If the container doesn't exist, it creates a new one using `docker run`. If it exists but is stopped, it wakes it up with `docker start`. If it's already running, it simply connects you to the existing session.

Crucially, the script mounts your local `./workspace` folder to `/home/myuser/workspace` inside the container. This is vital because Docker containers are ephemeral; if you delete a container, any files inside it are lost. By mounting a folder, your code lives safely on your actual computer (Host), while the container (Guest) can read and compile it. **Always save your work in `workspace`!**

**2. Cleanup Environment**
```bash
./docker.sh clean    # Remove container and image
./docker.sh rebuild  # Rebuild from scratch
```
The `clean` command deletes the "Cake" (Container) and the "Recipe" (Image), which is useful if you want to free up disk space. The `rebuild` command is useful if the `Dockerfile` has been updated and you need to regenerate the environment from scratch.

### Environment Testing

After entering the container, use the `eman` tool to verify the environment. We have updated `eman` to support checking more components:

```bash
eman help                    # Show all available commands
eman check-all               # Check all tools and packages versions

# Individual checks
eman c-compiler-version      # Check GCC and Make version
eman c-compiler-example      # Compile and run C/C++ example
eman verilator-version       # Check Verilator version
eman verilator-example       # Run Verilator example
eman tvm-version             # Check TVM version and env vars
eman python-version          # Check Python and Pip versions
eman ml-packages-version     # Check PyTorch, ONNX, etc.
```

### Advanced Usage

The `docker.sh` script now supports short flags for convenience:

**Custom Mount Path**
```bash
./docker.sh run -m /path/to/your/project
# OR
./docker.sh run --mount /path/to/your/project
```

**Custom Container Name**
```bash
./docker.sh run -c my-custom-container
# OR
./docker.sh run --container my-custom-container
```

**Multiple Mounts**
```bash
./docker.sh run -m ./src -m ./data
```

## FAQ

## Appendix: Manual Docker Commands (Under the Hood)

The `docker.sh` script is just a wrapper. If you want to understand exactly what commands are being executed, or if you need to debug the environment manually, here are the raw Docker commands.

**1. Build Image**
```bash
docker build -t aoc2026-env . --no-cache --progress=plain
```
This command tags the image as `aoc2026-env` and tells Docker to look for the `Dockerfile` in the current directory (`.`).

**2. Run Container**
```bash
docker run -dit --name aoc2026-container \
  -p 2222:22 \
  -v ./workspace:/home/myuser/workspace \
  aoc2026-env /bin/bash
```
This command runs the container in detached mode (`-d`), allowing it to run in the background, while keeping it interactive (`-it`). It maps port 2222 on your machine to port 22 inside the container for SSH access, and mounts your local workspace folder to the container's workspace directory.

**3. Enter Container**
```bash
docker exec -it aoc2026-container /bin/bash
```
This command executes a bash shell inside the already running container, allowing you to interact with it.
