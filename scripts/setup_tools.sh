#!/usr/bin/env bash
set -euo pipefail

echo "==> setup tools"

# clang
if ! command -v clang++ &>/dev/null; then
    echo "installing clang..."
    mkdir -p /workspace/.cache/apt
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        -o dir::cache::archives="/workspace/.cache/apt" clang
fi

# clang build analyzer
if command -v ClangBuildAnalyzer &>/dev/null; then
    exit 0
fi

if [ -f "/workspace/bin/ClangBuildAnalyzer" ]; then
    install -m 755 /workspace/bin/ClangBuildAnalyzer /usr/local/bin/
    exit 0
fi

echo "building clang build analyzer..."
mkdir -p /workspace/bin
git clone --depth 1 https://github.com/aras-p/ClangBuildAnalyzer.git /tmp/cba_src
cmake -S /tmp/cba_src -B /tmp/cba_src/build -DCMAKE_BUILD_TYPE=Release
cmake --build /tmp/cba_src/build -j"$(nproc)"
install -m 755 /tmp/cba_src/build/ClangBuildAnalyzer /workspace/bin/
install -m 755 /tmp/cba_src/build/ClangBuildAnalyzer /usr/local/bin/
rm -rf /tmp/cba_src
