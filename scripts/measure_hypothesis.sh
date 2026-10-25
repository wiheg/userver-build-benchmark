#!/usr/bin/env bash
set -euo pipefail

export CCACHE_DISABLE=1

echo "==> measure hypothesis"

rm -rf /tmp/benchmark_service_hypothesis
cp -r /tmp/benchmark_service /tmp/benchmark_service_hypothesis
cd /tmp/benchmark_service_hypothesis
rm -rf build

cat << 'EOF' >> CMakeLists.txt

target_precompile_headers(${PROJECT_NAME}_objs PRIVATE
    <userver/components/minimal_server_component_list.hpp>
    <userver/server/handlers/http_handler_base.hpp>
    <userver/formats/json.hpp>
    <fmt/format.h>
    <string>
    <vector>
    <memory>
    <optional>
    <string_view>
)
EOF

cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_CXX_FLAGS="-ftime-trace"

ClangBuildAnalyzer --start build
cmake --build build -- -j4 > /workspace/results/hypothesis_build.log 2>&1 || true
ClangBuildAnalyzer --stop build /workspace/results/hypothesis_capture.bin
ClangBuildAnalyzer --analyze /workspace/results/hypothesis_capture.bin > /workspace/results/hypothesis_raw.txt

echo "hypothesis done -> results/hypothesis_raw.txt"
