#!/usr/bin/env bash
set -euo pipefail

export CCACHE_DISABLE=1

echo "==> measure baseline"

rm -rf /tmp/benchmark_service
userver-create-service --grpc --mongo --postgresql /tmp/benchmark_service
cd /tmp/benchmark_service

cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_CXX_FLAGS="-ftime-trace"

ClangBuildAnalyzer --start build
cmake --build build -- -j4 > /workspace/results/baseline_build.log 2>&1 || true
ClangBuildAnalyzer --stop build /workspace/results/baseline_capture.bin
ClangBuildAnalyzer --analyze /workspace/results/baseline_capture.bin > /workspace/results/baseline_raw.txt

echo "baseline done -> results/baseline_raw.txt"
