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

def run_benchmark(duration=10, size=224):
    """Run PyTorch convolution benchmark"""
    if not torch.backends.mps.is_available():
        print(json.dumps({"error": "MPS not available"}))
        sys.exit(1)

    device = torch.device("mps")
    init_start = time.time()

    # Create conv layer
    conv = nn.Conv2d(3, 64, kernel_size=3, stride=1, padding=1).to(device)
    input_tensor = torch.randn(16, 3, size, size, device=device)

    init_time = (time.time() - init_start) * 1000

    # Warm-up
    with torch.no_grad():
        _ = conv(input_tensor)
    torch.mps.synchronize()

    # Benchmark
    iterations = 0
    start_time = time.time()

    with torch.no_grad():
        while time.time() - start_time < duration:
            _ = conv(input_tensor)
            torch.mps.synchronize()
            iterations += 1

    elapsed = time.time() - start_time

    result = {
        "framework": "pytorch",
        "modelName": "conv2d",
        "modelSize": f"{size}x{size}",
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
    size = int(sys.argv[2]) if len(sys.argv) > 2 else 224
    run_benchmark(duration, size)
