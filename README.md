# Docker Container Management Script

This script (`docker.sh`) provides convenient CLI-based management of a development container environment, including build, run, mount, and cleanup operations.

---

## 📦 Default Configuration

| 項目             | 預設值                         |
|------------------|--------------------------------|
| Docker Image     | `jackiempty/aoc2026-env`       |
| Container Name   | `aoc2026-container`            |
| Default Mount    | `./test:/home/myuser/test`     |

---

## 🚀 Usage

```bash
./docker.sh <command> [options...]
```

### Available Commands:

- `run` — Build the image if not present and run the container
- `clean` — Remove the container and image
- `rebuild` — Clean and rebuild the image
- `help` — Show usage instructions

---

## 🔧 Options

| Option           | Description                            |
|------------------|----------------------------------------|
| `--image-name`   | Specify a custom Docker image name     |
| `--cont-name`    | Specify a custom container name        |
| `--username`     | Reserved for future user setup         |
| `--hostname`     | Reserved for future container hostname |
| `--mount <path>` | Mount additional paths into container  |

---

## 🧪 Examples

### Run container with default config

```bash
./docker.sh run
```

### Run with custom image and mount:

```bash
./docker.sh run --image-name myuser/myenv --mount $(pwd)/src
```

### Rebuild from scratch

```bash
./docker.sh rebuild
```

### Clean up image and container

```bash
./docker.sh clean
```

---

## 🛠️ Features

- Automatically builds Docker image if it doesn't exist
- Reuses container if already running or exited
- Mounts specified local paths into container
- Provides quiet cleanup of containers and images

---

## 📂 To-Do

- Integrate `--username` and `--hostname` functionality
- Custom mounting targets within the container
- Add SSH support (port 2222 exposed)

---