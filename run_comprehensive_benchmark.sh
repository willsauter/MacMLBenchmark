#!/bin/bash
# Comprehensive Benchmark Script - Run on each machine independently
# Then aggregate results on primary node

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

HOSTNAME=$(hostname -s)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="results/benchmark_${HOSTNAME}_${TIMESTAMP}.json"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Comprehensive Benchmark Suite - $HOSTNAME"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Output file: $OUTPUT_FILE"
echo ""

# Ensure results directory exists
mkdir -p results

# Activate venv if exists
if [ -d ".venv" ]; then
    source .venv/bin/activate
    echo "✓ Virtual environment activated"
fi

# Array to collect all result files
RESULT_FILES=()

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "METAL GPU BENCHMARKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Metal benchmarks with varying durations and sizes
METAL_BENCHMARKS=(
    "matrix-multiply:10:4096"
    "matrix-multiply:15:8192"
    "matrix-multiply:5:2048"
    "convolution-2d:10:1024"
    "attention-mechanism:10:2048"
    "activation-functions:10:4096"
    "mixed-operations:10:2048"
)

for bench_config in "${METAL_BENCHMARKS[@]}"; do
    IFS=':' read -r benchmark duration size <<< "$bench_config"
    echo ""
    echo "Running: $benchmark (duration=${duration}s, size=${size})"

    TEMP_FILE="results/temp_${benchmark}_${duration}_${size}.json"

    .build/release/macmlbench run "$benchmark" \
        --duration "$duration" \
        --size "$size" \
        --output "$TEMP_FILE" 2>&1 | grep -E "(Throughput|Latency|Status)" || true

    if [ -f "$TEMP_FILE" ]; then
        RESULT_FILES+=("$TEMP_FILE")
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PYTORCH FRAMEWORK BENCHMARKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# PyTorch benchmarks with varying parameters
PYTORCH_BENCHMARKS=(
    "pytorch-matmul:10:1024"
    "pytorch-matmul:10:2048"
    "pytorch-matmul:15:4096"
)

for bench_config in "${PYTORCH_BENCHMARKS[@]}"; do
    IFS=':' read -r benchmark duration size <<< "$bench_config"
    echo ""
    echo "Running: $benchmark (duration=${duration}s, size=${size})"

    TEMP_FILE="results/temp_${benchmark}_${duration}_${size}.json"

    .build/release/macmlbench run "$benchmark" \
        --duration "$duration" \
        --size "$size" \
        --output "$TEMP_FILE" 2>&1 | grep -E "(Throughput|Latency|Status)" || true

    if [ -f "$TEMP_FILE" ]; then
        RESULT_FILES+=("$TEMP_FILE")
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TENSORFLOW FRAMEWORK BENCHMARKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# TensorFlow benchmarks
TENSORFLOW_BENCHMARKS=(
    "tensorflow-matmul:10:1024"
    "tensorflow-matmul:10:2048"
)

for bench_config in "${TENSORFLOW_BENCHMARKS[@]}"; do
    IFS=':' read -r benchmark duration size <<< "$bench_config"
    echo ""
    echo "Running: $benchmark (duration=${duration}s, size=${size})"

    TEMP_FILE="results/temp_${benchmark}_${duration}_${size}.json"

    .build/release/macmlbench run "$benchmark" \
        --duration "$duration" \
        --size "$size" \
        --output "$TEMP_FILE" 2>&1 | grep -E "(Throughput|Latency|Status|Error)" || true

    if [ -f "$TEMP_FILE" ]; then
        RESULT_FILES+=("$TEMP_FILE")
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CONSOLIDATING RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Merge all results into single JSON file with hostname
python3 - << PYTHON_SCRIPT
import json
import sys
from datetime import datetime

result_files = ${RESULT_FILES[@]@json}
output_file = "$OUTPUT_FILE"
hostname = "$HOSTNAME"

consolidated = {
    "hostname": hostname,
    "timestamp": datetime.now().isoformat(),
    "benchmarks": []
}

for file in result_files.split():
    try:
        with open(file, 'r') as f:
            data = json.load(f)
            consolidated["benchmarks"].append(data)
    except Exception as e:
        print(f"Warning: Failed to load {file}: {e}", file=sys.stderr)

with open(output_file, 'w') as f:
    json.dump(consolidated, f, indent=2)

print(f"✓ Consolidated {len(consolidated['benchmarks'])} benchmarks to {output_file}")
PYTHON_SCRIPT

# Cleanup temp files
rm -f results/temp_*.json

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Benchmark Complete on $HOSTNAME"
echo "║     Results: $OUTPUT_FILE"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "File size: $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
echo "Benchmarks run: $(cat "$OUTPUT_FILE" | grep -c '"benchmarkRun"' || echo "Unknown")"
