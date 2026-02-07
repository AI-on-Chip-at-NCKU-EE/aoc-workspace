# Lab 0 - Environment Setup

This lab provides a containerized development environment for AI-on-Chip coursework, including essential build tools, TVM, and ML frameworks.

## Quick Start

```bash
# Build and run the container
./docker.sh run

# Inside the container, verify environment
eman check-all
```

## Environment

### Docker Container

Use `docker.sh` to manage your development container:

```bash
./docker.sh run              # Start container
./docker.sh clean            # Remove container and image
./docker.sh rebuild          # Clean rebuild
./docker.sh help             # Show detailed help
```

**Default Configuration:**

| Item             | Default Value                                       |
|------------------|-----------------------------------------------------|
| Docker Image     | `aoc2026-env`                                       |
| Container Name   | `aoc2026-container`                                 |
| Default Mount    | `./projects:/home/myuser/projects` (auto-detect) |

### Environment Manager (`eman`)

Verify your environment setup inside the container:

```bash
eman check-all         # Check all tools and packages
eman tvm-version       # Check TVM installation
eman python-version    # Check Python and pip
eman help              # Show all commands
```

The environment includes:
- **Build Tools**: GCC, Make, Verilator
- **ML Framework**: TVM 0.18, Python 3.11
- **ML Packages**: ONNX, PyTorch, NumPy, etc.

## Features

- Auto-build Docker image if not present
- Auto-detect and mount `./projects` directory
- Reuse existing container across sessions
- Color-coded output for clarity
- Built-in environment validation tool

## Reference

### `docker.sh` Options

| Short | Long           | Description                     |
|-------|----------------|---------------------------------|
| `-i`  | `--image`      | Custom Docker image name        |
| `-c`  | `--container`  | Custom container name           |
| `-m`  | `--mount`      | Mount path to workspace         |
| `-h`  | `--host`       | Reserved for future use         |

### Usage Examples

**Mount a specific directory:**
```bash
./docker.sh run --mount ./my-project
```

**Custom image and container names:**
```bash
./docker.sh run --image my-env --container my-dev
```

**Quick workflow with short flags:**
```bash
./docker.sh run -i custom-env -c dev -m ./projects
```
