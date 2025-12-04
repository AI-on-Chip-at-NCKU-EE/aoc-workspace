#!/bin/bash

# manually build cmd:
#   docker build -t aoc2026-env . --no-cache --progress=plain
# manually build cmd (base):
#   docker build --target common_pkg_provider -t base . --no-cache --progress=plain
# manually run cmd:
#   docker run -dit --name full_test_1 -p 2222:22 \
#     -v ./test:/home/myuser/test aoc2026-env /bin/bash
# manually run cmd (base):
#   docker run -it --name aoc-env aoc2026-env /bin/bash
# push image to cloud:
#   docker push aoc2026-env
# manually enter container:
#   docker exec -it aoc2026-env /bin/bash

# Adaption to windows env with GNU tools
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    export MSYS_NO_PATHCONV=1
fi

# Color output functions
info() { echo -e "\033[0;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[0;32m[SUCCESS]\033[0m $*"; }
warn() { echo -e "\033[0;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $*"; }

# default parameters
IMAGE_NAME="aoc2026-env"
CONTAINER_NAME="aoc2026-container"
MOUNT_PATHS=()

# --- Parse CLI ---
while [[ $# -gt 0 ]]; do
  case $1 in
    run|clean|rebuild|help)
      COMMAND=$1
      shift
      ;;
    -i|--image)
      IMAGE_NAME="$2"
      shift 2
      ;;
    -c|--container)
      CONTAINER_NAME="$2"
      shift 2
      ;;
    -u|--user)
      USERNAME="$2"
      shift 2
      ;;
    -h|--host)
      HOSTNAME="$2"
      shift 2
      ;;
    -m|--mount)
      MOUNT_PATHS+=("$2")
      shift 2
      ;;
    *)
      error "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# --- Check if image exists ---
build_image() {
  if docker images "$IMAGE_NAME" | grep -q "$IMAGE_NAME"; then
    success "Docker image '$IMAGE_NAME' already exists"
    info "You can delete it with: docker rmi $IMAGE_NAME"
  else
    info "Building Docker image '$IMAGE_NAME'..."
    docker build -t "$IMAGE_NAME" . --no-cache
  fi
}

# --- Run container ---
run_container() {
  CONTAINER_STATUS=$(docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format '{{.Status}}')

  # Default mount if none is specified
  if [[ ${#MOUNT_PATHS[@]} -eq 0 ]]; then
    if [ -d "./workspace" ]; then
      WORKSPACE_DIR="$(cd ./workspace && pwd)"
      MOUNT_PATHS+=("$WORKSPACE_DIR")
      info "Auto-detected workspace directory: $WORKSPACE_DIR"
    fi
  fi
  # mount path
  MOUNTS_ARGS=""
  for path in "${MOUNT_PATHS[@]}"; do
    abs_path=$(realpath "$path")
    # Mount to /home/myuser/workspace
    MOUNTS_ARGS+=" -v $abs_path:/home/myuser/workspace"
    info "Mounting: $abs_path -> /home/myuser/workspace"
  done

  if [[ "$CONTAINER_STATUS" == *"Up"* ]]; then
    success "Container '$CONTAINER_NAME' is already running"
    info "Entering container..."
    docker exec -it "$CONTAINER_NAME" /bin/bash

  elif [[ "$CONTAINER_STATUS" == *"Exited"* ]]; then
    info "Starting stopped container '$CONTAINER_NAME'..."
    docker start "$CONTAINER_NAME"
    success "Container started"
    info "Entering container..."
    docker exec -it "$CONTAINER_NAME" /bin/bash

  else
    info "Creating and starting new container '$CONTAINER_NAME'..."
    docker run -dit --name "$CONTAINER_NAME" \
      -p 2222:22 \
      $MOUNTS_ARGS \
      "$IMAGE_NAME" /bin/bash
    success "Container created and started"
  fi
}

# --- Clean image & container ---
clean_all() {
  warn "Removing container '$CONTAINER_NAME' and image '$IMAGE_NAME'..."
  docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
  docker rmi -f "$IMAGE_NAME" 2>/dev/null || true
  success "Cleanup completed"
}

# --- Rebuild ---
rebuild_all() {
  clean_all
  build_image
}

# --- Show help ---
show_help() {
  cat << EOF

Docker Container Management Script

Usage:
  $0 <command> [options...]

Commands:
  run         Build image (if needed) and run container
  clean       Remove container and image
  rebuild     Clean and rebuild from scratch
  help        Show this help message

Options:
  -i, --image <name>        Custom Docker image name (default: $IMAGE_NAME)
  -c, --container <name>    Custom container name (default: $CONTAINER_NAME)
  -m, --mount <path>        Mount path to /home/myuser/workspace
                            (default: auto-detect ./workspace)
  -u, --user <name>         Reserved for future use
  -h, --host <name>         Reserved for future use

Examples:
  # Mount custom directory
  $0 run --mount ./my-project

  # Use custom image name
  $0 run --image my-custom-image

  # Combine multiple options (using short flags for brevity)
  $0 run -i custom-env -c dev-container -m ./workspace

EOF
}

# --- Entrypoint ---
case "$COMMAND" in
  run)
    build_image
    run_container
    ;;
  clean)
    clean_all
    ;;
  rebuild)
    rebuild_all
    ;;
  help)
    show_help
    ;;
  *)
    error "Unknown command: $COMMAND"
    show_help
    exit 1
    ;;
esac