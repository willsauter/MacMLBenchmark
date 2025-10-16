#!/usr/bin/env python3
import json
import sys
import time

try:
    import torch
    import torch.nn as nn
except ImportError:
    print(json.dumps({"error": "PyTorch not installed. Run: pip install torch"}))
    sys.exit(1)

def run_benchmark(duration=10, seq_len=512):
    """Run PyTorch transformer/attention benchmark"""
    if not torch.backends.mps.is_available():
        print(json.dumps({"error": "MPS not available"}))
        sys.exit(1)

    device = torch.device("mps")
    init_start = time.time()

    # Create attention layer
    d_model = 512
    nhead = 8
    attention = nn.MultiheadAttention(d_model, nhead, batch_first=True).to(device)

    # Create input
    batch_size = 8
    query = torch.randn(batch_size, seq_len, d_model, device=device)
    key = torch.randn(batch_size, seq_len, d_model, device=device)
    value = torch.randn(batch_size, seq_len, d_model, device=device)

    init_time = (time.time() - init_start) * 1000

    # Warm-up
    with torch.no_grad():
        _ = attention(query, key, value)
    torch.mps.synchronize()

    # Benchmark
    iterations = 0
    start_time = time.time()

    with torch.no_grad():
        while time.time() - start_time < duration:
            _ = attention(query, key, value)
            torch.mps.synchronize()
            iterations += 1

    elapsed = time.time() - start_time

    result = {
        "framework": "pytorch",
        "modelName": "transformer-attention",
        "modelSize": f"seq{seq_len}",
        "metrics": {
            "throughputOpsPerSec": iterations / elapsed,
            "latencyMs": (elapsed / iterations) * 1000,
            "gpuUtilizationPercent": 100.0,
            "peakMemoryUsageMB": 0,
            "averageMemoryUsageMB": 0,
            "iterationsCompleted": iterations
        },
        "frameworkOverhead": 0.0,
        "initTimeMs": init_time
    }

    print(json.dumps(result))

if __name__ == "__main__":
    duration = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    seq_len = int(sys.argv[2]) if len(sys.argv) > 2 else 512
    run_benchmark(duration, seq_len)
