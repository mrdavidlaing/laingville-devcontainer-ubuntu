#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# bash 3.2+ friendly parallel arrays
CONTAINER_NAMES=(
  "laingville-devcontainer"
  "example-node-devcontainer"
  "example-node-runtime"
  "example-python-devcontainer"
  "example-python-runtime"
)
CONTAINER_TEST_TYPES=(
  "base"
  "node"
  "node"
  "python"
  "python"
)

filter="${1:-}"

run_test() {
  local container="$1"
  local test_type="$2"
  local image_ref="$3"

  echo "=== Testing $container ($test_type) ==="
  echo "Image: $image_ref"

  case "$test_type" in
    node)
      docker run --rm \
        -v "$SCRIPT_DIR:/tests:ro" \
        "$image_ref" \
        bash /tests/test-node-environment.sh
      ;;
    python)
      docker run --rm "$image_ref" python3 --version
      ;;
    base)
      docker run --rm "$image_ref" bash -lc 'echo "Container starts successfully"'
      ;;
  esac

  # All containers should have fzf (installed in base stage)
  echo "Checking fzf installation..."
  docker run --rm "$image_ref" fzf --version > /dev/null

  # Only laingville-devcontainer should have shfmt (installed in bashdev stage)
  if [ "$container" = "laingville-devcontainer" ]; then
    echo "Checking shfmt installation..."
    docker run --rm "$image_ref" shfmt --version > /dev/null
  fi
}

build_image() {
  local target="$1"
  local tag="$2"

  docker buildx build \
    --load \
    --target "$target" \
    -t "$tag" \
    "$ROOT_DIR" >/dev/null
}

main() {
  docker buildx version >/dev/null

  local passed=0
  local failed=0

  for i in "${!CONTAINER_NAMES[@]}"; do
    local container="${CONTAINER_NAMES[$i]}"
    local test_type="${CONTAINER_TEST_TYPES[$i]}"

    if [ -n "$filter" ]; then
      if [[ ! "$container" =~ $filter ]] && [[ ! "$test_type" =~ $filter ]]; then
        continue
      fi
    fi

    local image_ref="${container}:local-test"
    build_image "$container" "$image_ref"

    # shellcheck disable=SC2310 # capture pass/fail
    if run_test "$container" "$test_type" "$image_ref"; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi

    echo ""
  done

  echo "=== Summary ==="
  echo "Passed: $passed"
  echo "Failed: $failed"

  [ "$failed" -eq 0 ]
}

main "$@"
