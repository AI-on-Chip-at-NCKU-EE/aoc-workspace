#!/bin/bash

# manually build cmd: docker build -t aoc2026-env . --no-cache --progress=plain
# manually build cmd (base): docker build --target common_pkg_provider -t base . --no-cache --progress=plain
# manually run cmd: docker run -dit --name full_test_1 -p 2222:22 -v ./test:/home/myuser/test aoc2026-env /bin/bash
# manually run cmd (base): docker run -it --name aoc-env aoc2026-env /bin/bash
# push image to cloud: docker push aoc2026-env
# manually enter container: docker exec -it aoc2026-env /bin/bash

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
    --image-name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    --cont-name)
      CONTAINER_NAME="$2"
      shift 2
      ;;
    --username)
      USERNAME="$2"
      shift 2
      ;;
    --hostname)
      HOSTNAME="$2"
      shift 2
      ;;
    --mount)
      MOUNT_PATHS+=("$2")
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# --- Check if image exists ---
build_image() {
  if docker images "$IMAGE_NAME" | grep -q "$IMAGE_NAME"; then
    echo "Docker image '$IMAGE_NAME' already exists."
    echo "You can delete it with: docker rmi $IMAGE_NAME"
  else
    echo "Building Docker image '$IMAGE_NAME'..."
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
      echo "Auto-detected workspace directory: $WORKSPACE_DIR"
    fi
  fi
  # mount path
  # TODO: set eman script mounting position (and other test scripts')
  MOUNTS_ARGS=""
  for path in "${MOUNT_PATHS[@]}"; do
    abs_path=$(realpath "$path")
    # Mount to /home/myuser/workspace
    MOUNTS_ARGS+=" -v $abs_path:/home/myuser/workspace"
    echo "Mounting: $abs_path -> /home/myuser/workspace"
  done

  if [[ "$CONTAINER_STATUS" == *"Up"* ]]; then
    echo "Container '$CONTAINER_NAME' is already running. Entering..."
    docker exec -it "$CONTAINER_NAME" /bin/bash

  elif [[ "$CONTAINER_STATUS" == *"Exited"* ]]; then
    echo "Starting stopped container '$CONTAINER_NAME'..."
    docker start "$CONTAINER_NAME"
    docker exec -it "$CONTAINER_NAME" /bin/bash

  else
    echo "Creating and starting new container '$CONTAINER_NAME'..."
    docker run -dit --name "$CONTAINER_NAME" \
      -p 2222:22 \
      $MOUNTS_ARGS \
      "$IMAGE_NAME" /bin/bash
  fi
}

# --- Clean image & container ---
clean_all() {
  echo "Removing container '$CONTAINER_NAME' and image '$IMAGE_NAME'..."
  docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
  docker rmi -f "$IMAGE_NAME" 2>/dev/null || true
}

# --- Rebuild ---
rebuild_all() {
  clean_all
  build_image
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
    echo "Usage:"
    echo "  $0 run [--image-name <image name>] [--cont-name <container name>] [--mount <path>]..."
    echo "  $0 clean"
    echo "  $0 rebuild"
    echo "  $0 help"
    ;;
  *)
    echo "Usage:"
    echo "  $0 run [--image-name <image name>] [--cont-name <container name>] [--mount <path>]..."
    echo "  $0 clean"
    echo "  $0 rebuild"
    echo "  $0 help"
    exit 1
    ;;
esac