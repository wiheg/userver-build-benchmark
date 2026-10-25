#!/usr/bin/env bash
set -euo pipefail

bash /workspace/scripts/setup_tools.sh
bash /workspace/scripts/measure_baseline.sh
bash /workspace/scripts/measure_hypothesis.sh


echo "generating report"
python3 /workspace/scripts/compare_results.py \
    /workspace/results/baseline_raw.txt \
    /workspace/results/hypothesis_raw.txt \
    /workspace/results/comparison.txt

