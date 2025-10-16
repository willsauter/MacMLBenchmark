# How to Run Multi-Machine Comprehensive Benchmarks

## Overview

This runs Metal + PyTorch + TensorFlow benchmarks with varying durations and sizes across multiple machines, then aggregates results.

## Step-by-Step Instructions

### Step 1: Run on Local Machine (Primary Node)

```bash
cd /Users/willsauter/Development/MacMLBenchmark

# Ensure venv is activated for framework benchmarks
source .venv/bin/activate

# Run comprehensive benchmarks locally
./run_comprehensive_benchmark.sh
```

This will:
- Run 7 Metal benchmarks with different sizes
- Run 3 PyTorch benchmarks
- Run 2 TensorFlow benchmarks
- Save to `results/benchmark_<hostname>_<timestamp>.json`

### Step 2: Setup and Run on Remote Machines

#### Remote 1: 10.20.1.89

```bash
# From local machine, copy script to remote
scp run_comprehensive_benchmark.sh willsauter@10.20.1.89:~/MacMLBenchmark/

# SSH to remote and run
ssh willsauter@10.20.1.89

# On remote machine:
cd ~/MacMLBenchmark
source .venv/bin/activate  # If venv exists
./run_comprehensive_benchmark.sh

# Exit remote session
exit
```

#### Remote 2: 10.20.1.64 (M3 Ultra)

```bash
# Copy script
scp run_comprehensive_benchmark.sh willsauter@10.20.1.64:~/MacMLBenchmark/

# SSH and run
ssh willsauter@10.20.1.64
cd ~/MacMLBenchmark
source .venv/bin/activate
./run_comprehensive_benchmark.sh
exit
```

### Step 3: Aggregate Results (from Primary Node)

```bash
# From local machine, collect and aggregate
./aggregate_results.sh
```

This will:
1. Find the most recent local benchmark result
2. SSH to each remote machine and download their results
3. Automatically setup SSH keys if needed
4. Merge all results into one JSON file
5. Generate a comparison report

### Step 4: View Results

The aggregated file will be at:
```
results/multi_machine_aggregated_<timestamp>.json
```

The script also prints a comparison table showing all benchmarks across all machines.

---

## What Gets Run

### Metal Benchmarks (varying sizes)
- matrix-multiply: 4096, 8192, 2048
- convolution-2d: 1024
- attention-mechanism: 2048
- activation-functions: 4096
- mixed-operations: 2048

### PyTorch Benchmarks
- pytorch-matmul: 1024, 2048, 4096

### TensorFlow Benchmarks
- tensorflow-matmul: 1024, 2048

**Total per machine**: ~12 benchmarks
**Total across 3 machines**: ~36 benchmark runs

---

## Estimated Time

- **Per machine**: ~8-10 minutes
- **Total (if run in parallel)**: ~10 minutes
- **If run sequentially**: ~25-30 minutes

---

## Output Format

```json
{
  "aggregation_timestamp": "2025-10-16T...",
  "machines": [
    {
      "machine_type": "local",
      "hostname": "Wills-Mac...",
      "data": {
        "hostname": "...",
        "timestamp": "...",
        "benchmarks": [...]
      }
    },
    {
      "machine_type": "remote",
      "hostname": "...",
      "data": {...}
    }
  ]
}
```

---

## Notes

- Scripts must be run from project root directory
- Virtual environment should be activated for framework benchmarks
- Remote machines need the benchmark tool deployed first
- SSH keys should be configured for passwordless access
- Results directory created automatically
