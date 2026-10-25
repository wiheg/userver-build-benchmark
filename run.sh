#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

IMG="ghcr.io/userver-framework/ubuntu-22.04-userver"
DIGEST="sha256:fca9c8ac7e97b4e2b042d822facbb152aec10a9d4e09c0862e44c50640f3f303"
LIMITS=(--cpus=4 --cpuset-cpus=0-3 --memory=8g --memory-swap=8g)

echo "target image : ${IMG}@${DIGEST}"
echo "limits: ${LIMITS[*]}"

mkdir -p results bin

docker run --rm "${LIMITS[@]}" -v "${REPO_DIR}:/workspace" -w /workspace "${IMG}@${DIGEST}" bash /workspace/scripts/run_all.sh

echo "benchmark completed"
