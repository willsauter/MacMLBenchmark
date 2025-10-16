#!/bin/bash
# Result Aggregation Script - Run on primary node to collect from all machines

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REMOTE1="10.20.1.89"
REMOTE2="10.20.1.64"
USERNAME="willsauter"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Multi-Machine Benchmark Result Aggregation            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Find most recent result file on local machine
LOCAL_RESULT=$(ls -t results/benchmark_$(hostname -s)_*.json 2>/dev/null | head -1)

if [ -z "$LOCAL_RESULT" ]; then
    echo "Error: No local benchmark results found. Run ./run_comprehensive_benchmark.sh first."
    exit 1
fi

echo "Local result: $LOCAL_RESULT"

# Setup SSH keys for new machines if needed
echo ""
echo "Setting up SSH keys..."

for HOST in "$REMOTE1" "$REMOTE2"; do
    echo "Testing connection to $HOST..."

    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$USERNAME@$HOST" "echo 'Connected'" 2>/dev/null; then
        echo "  ✓ $HOST connected"
    else
        echo "  ○ $HOST not accessible, attempting key setup..."
        ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519.pub "$USERNAME@$HOST" 2>/dev/null || echo "  ✗ Failed to setup key for $HOST (may need manual setup)"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "COLLECTING REMOTE RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REMOTE_RESULTS=()

# Collect from Remote 1
echo ""
echo "Fetching from $REMOTE1..."
REMOTE1_FILE=$(ssh "$USERNAME@$REMOTE1" "ls -t ~/MacMLBenchmark/results/benchmark_*.json 2>/dev/null | head -1" 2>/dev/null || echo "")

if [ -n "$REMOTE1_FILE" ]; then
    LOCAL_COPY="results/remote1_${TIMESTAMP}.json"
    scp "$USERNAME@$REMOTE1:$REMOTE1_FILE" "$LOCAL_COPY" 2>/dev/null

    if [ -f "$LOCAL_COPY" ]; then
        REMOTE_RESULTS+=("$LOCAL_COPY")
        echo "  ✓ Downloaded: $LOCAL_COPY"
    else
        echo "  ✗ Failed to download from $REMOTE1"
    fi
else
    echo "  ○ No results found on $REMOTE1"
fi

# Collect from Remote 2
echo ""
echo "Fetching from $REMOTE2..."
REMOTE2_FILE=$(ssh "$USERNAME@$REMOTE2" "ls -t ~/MacMLBenchmark/results/benchmark_*.json 2>/dev/null | head -1" 2>/dev/null || echo "")

if [ -n "$REMOTE2_FILE" ]; then
    LOCAL_COPY="results/remote2_${TIMESTAMP}.json"
    scp "$USERNAME@$REMOTE2:$REMOTE2_FILE" "$LOCAL_COPY" 2>/dev/null

    if [ -f "$LOCAL_COPY" ]; then
        REMOTE_RESULTS+=("$LOCAL_COPY")
        echo "  ✓ Downloaded: $LOCAL_COPY"
    else
        echo "  ✗ Failed to download from $REMOTE2"
    fi
else
    echo "  ○ No results found on $REMOTE2"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AGGREGATING ALL RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

FINAL_OUTPUT="results/multi_machine_aggregated_${TIMESTAMP}.json"

# Create aggregated JSON
python3 - << PYTHON_SCRIPT
import json
from datetime import datetime

local_file = "$LOCAL_RESULT"
remote_files = "${REMOTE_RESULTS[@]}".split()
output_file = "$FINAL_OUTPUT"

aggregated = {
    "aggregation_timestamp": datetime.now().isoformat(),
    "machines": []
}

# Load local results
try:
    with open(local_file, 'r') as f:
        local_data = json.load(f)
        aggregated["machines"].append({
            "machine_type": "local",
            "hostname": local_data.get("hostname", "unknown"),
            "data": local_data
        })
        print(f"✓ Loaded local: {local_data.get('hostname', 'unknown')}")
except Exception as e:
    print(f"✗ Failed to load local results: {e}")

# Load remote results
for remote_file in remote_files:
    if not remote_file:
        continue
    try:
        with open(remote_file, 'r') as f:
            remote_data = json.load(f)
            aggregated["machines"].append({
                "machine_type": "remote",
                "hostname": remote_data.get("hostname", "unknown"),
                "data": remote_data
            })
            print(f"✓ Loaded remote: {remote_data.get('hostname', 'unknown')}")
    except Exception as e:
        print(f"✗ Failed to load {remote_file}: {e}")

# Save aggregated results
with open(output_file, 'w') as f:
    json.dump(aggregated, f, indent=2)

print(f"\n✓ Aggregated results from {len(aggregated['machines'])} machines")
print(f"  Output: {output_file}")
PYTHON_SCRIPT

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "GENERATING COMPARISON REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Generate human-readable comparison
python3 - << PYTHON_SCRIPT
import json

with open("$FINAL_OUTPUT", 'r') as f:
    data = json.load(f)

print("\n" + "="*70)
print("MULTI-MACHINE BENCHMARK COMPARISON")
print("="*70)

for machine in data["machines"]:
    hostname = machine["data"].get("hostname", "Unknown")
    benchmarks = machine["data"].get("benchmarks", [])

    print(f"\n{hostname} ({machine['machine_type']})")
    print("-" * 70)

    for bench in benchmarks:
        if "benchmarkRun" in bench:
            results = bench["benchmarkRun"].get("results", [])
            for result in results:
                task = result.get("taskName", "unknown")
                metrics = result.get("metrics", {})
                throughput = metrics.get("throughputOpsPerSec", 0)
                latency = metrics.get("latencyMs", 0)
                print(f"  {task:25s} {throughput:8.1f} ops/sec  {latency:8.2f} ms")

print("\n" + "="*70)
print(f"Aggregated results saved to: $FINAL_OUTPUT")
print("="*70)
PYTHON_SCRIPT

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     COMPLETE!"
echo "║     Results: $FINAL_OUTPUT"
echo "╚═══════════════════════════════════════════════════════════╝"
