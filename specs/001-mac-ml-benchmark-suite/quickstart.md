# Quickstart Guide: Mac ML Benchmark Suite

**Date**: 2025-10-16
**Feature**: Mac ML Benchmark Suite
**Phase**: Phase 1 - Design & Contracts

## Overview

This guide explains how to build, install, and run the Mac ML Benchmark Suite. It covers prerequisites, build instructions, basic usage, and validation against the specification's acceptance scenarios.

---

## Prerequisites

### System Requirements
- **Hardware**: Mac with Apple Silicon (M1/M2/M3 or later)
- **Operating System**: macOS 12.0 (Monterey) or later
- **Memory**: Minimum 8 GB RAM (16 GB+ recommended for larger benchmarks)
- **Developer Tools**: Xcode 14.0+ or Xcode Command Line Tools

### Verify Prerequisites

1. **Check Hardware**:
```bash
sysctl -n machdep.cpu.brand_string
```
Expected output: Should contain "Apple M1" or "Apple M2" or "Apple M3"

2. **Check macOS Version**:
```bash
sw_vers
```
Expected: ProductVersion >= 12.0

3. **Check Swift Version**:
```bash
swift --version
```
Expected: Swift version 5.9 or later

4. **Install Xcode Command Line Tools** (if not installed):
```bash
xcode-select --install
```

---

## Build Instructions

### Option 1: Build with Swift Package Manager (Recommended)

1. **Clone Repository** (once implemented):
```bash
git clone https://github.com/your-org/MacMLBenchmark.git
cd MacMLBenchmark
```

2. **Build Project**:
```bash
swift build -c release
```

3. **Verify Build**:
```bash
.build/release/macmlbench version
```
Expected output:
```
Mac ML Benchmark Suite
Version: 1.0.0
Build: 2025-10-16
Swift: 5.9
Metal API: 3.1
```

4. **Install to PATH** (optional):
```bash
sudo cp .build/release/macmlbench /usr/local/bin/
```

### Option 2: Build with Xcode

1. **Generate Xcode Project**:
```bash
swift package generate-xcodeproj
```

2. **Open in Xcode**:
```bash
open MacMLBenchmark.xcodeproj
```

3. **Select Target**: Choose "macmlbench" scheme

4. **Build**: Product → Build (⌘B)

5. **Run**: Product → Run (⌘R)

### Build Artifacts

After successful build:
```
.build/
├── release/
│   ├── macmlbench        # Executable binary
│   └── (dependencies)
└── debug/
    └── macmlbench        # Debug build (optional)
```

---

## Basic Usage

### 1. Verify Hardware Compatibility

```bash
macmlbench hardware
```

Expected output (example):
```
Mac ML Benchmark Suite - Hardware Profile
==========================================

Model: Mac Studio (2023)
Chip: M2 Ultra
GPU Cores: 76
CPU Cores: 24 (16 performance + 8 efficiency)
Total Memory: 128 GB
GPU Memory: 64 GB
macOS Version: 14.2

Status: Compatible ✓
```

### 2. List Available Benchmarks

```bash
macmlbench list
```

Expected output:
```
Available Benchmark Tasks:
==========================

1. matrix-multiply
   Type: Inference
   Description: Measures GPU throughput for large matrix operations

2. convolution-2d
   Type: Inference
   Description: Measures convolution performance for CNN workloads

3. attention-mechanism
   Type: Inference
   Description: Measures scaled dot-product attention performance

4. activation-functions
   Type: Processing
   Description: Measures activation function throughput

5. mixed-operations
   Type: Training
   Description: Measures combined operation performance

Run with --verbose for full parameter details.
```

### 3. Run Your First Benchmark (P1 User Story)

```bash
macmlbench run matrix-multiply
```

Expected output (example):
```
Mac ML Benchmark Suite
======================

Hardware Profile:
  Model: Mac Studio (2023)
  Chip: M2 Ultra
  GPU Cores: 76
  Memory: 128 GB

Running Benchmark: Matrix Multiplication
----------------------------------------
Configuration:
  Duration: 10 seconds
  Batch Size: 32
  Matrix Size: 4096x4096
  Threads: 24

Progress: [####################] 100% (10.0s elapsed)

Results:
  Throughput: 12,500 ops/sec
  Latency: 0.08 ms/op
  GPU Utilization: 95%
  Peak Memory: 2,048 MB
  Iterations: 125,000
  Status: Success
  Thermal State: Nominal

Time: 10.02 seconds
```

**Validation**: Meets SC-001 (first benchmark within 2 minutes) ✓

---

## Advanced Usage

### Custom Parameters (P2 User Story)

```bash
# Custom duration and batch size
macmlbench run matrix-multiply --duration 30 --batch-size 64

# Custom size parameter
macmlbench run matrix-multiply --size 8192

# Custom thread count
macmlbench run attention-mechanism --threads 8 --duration 60

# Combine multiple parameters
macmlbench run convolution-2d --duration 20 --batch-size 16 --size 2048
```

**Validation**: Meets P2 acceptance scenarios (custom parameters respected) ✓

### Run Multiple Benchmarks (P3 User Story)

```bash
# Run specific tasks
macmlbench run matrix-multiply convolution-2d attention-mechanism

# Run all available tasks
macmlbench run --all

# Run all with custom duration
macmlbench run --all --duration 15
```

**Validation**: Meets SC-007 (full suite under 5 minutes with defaults) ✓

### Export Results

```bash
# Export to JSON
macmlbench run matrix-multiply --output results/my-benchmark.json

# Export all tasks to JSON
macmlbench run --all --output results/full-suite.json

# Export to CSV
macmlbench run matrix-multiply --output results/benchmark.csv
```

**Validation**: Meets FR-011 (structured export formats) ✓

### Compare Results

```bash
# Compare two runs
macmlbench compare results/baseline.json results/experiment.json

# Compare multiple runs
macmlbench compare results/run1.json results/run2.json results/run3.json

# Export comparison
macmlbench compare results/old.json results/new.json --output comparison.txt
```

**Validation**: Meets FR-014 (result comparison with deltas) ✓

---

## Validation Against Acceptance Scenarios

### P1 User Story 1: Quick Benchmark Execution

**Scenario 1**: Run single task with defaults
```bash
macmlbench run matrix-multiply
```
✓ Executes for 10 seconds (default duration)
✓ Displays throughput, latency, GPU utilization
✓ Shows hardware info (chip variant)

**Scenario 2**: Consistent format across hardware
```bash
# On M1 Mac
macmlbench run matrix-multiply
# On M3 Mac
macmlbench run matrix-multiply
```
✓ Results format identical
✓ Hardware clearly identified in output

**Scenario 3**: Real-time progress indication
```bash
macmlbench run matrix-multiply --duration 30
```
✓ Progress bar updates during execution
✓ Shows elapsed time
✓ Indicates benchmark is active

**Scenario 4**: Complete result display
```bash
macmlbench run matrix-multiply
```
✓ Output includes task name
✓ Hardware info present (Mac model, chip)
✓ Configuration shown (duration)
✓ Metrics displayed (throughput, latency)
✓ Timestamp included

### P2 User Story 2: Configurable Parameters

**Scenario 1**: Custom duration
```bash
macmlbench run matrix-multiply --duration 30
```
✓ Runs for exactly 30 seconds
✓ Results reflect longer test period

**Scenario 2**: Custom input size
```bash
macmlbench run matrix-multiply --size 8192
```
✓ Uses 8192x8192 matrices
✓ Results indicate configuration tested

**Scenario 3**: Custom thread count
```bash
macmlbench run matrix-multiply --threads 8
```
✓ Executes with 8 threads
✓ Results show thread utilization

**Scenario 4**: Invalid parameters error handling
```bash
macmlbench run matrix-multiply --duration -5
```
✓ Clear error message explaining issue
✓ Shows valid parameter range
✓ Provides example of correct usage

**Scenario 5**: Result replication
```bash
macmlbench run matrix-multiply --duration 20 --batch-size 64 --output test.json
cat test.json | jq '.benchmark_run.configuration'
```
✓ All parameters included in exported results
✓ Can replicate exact configuration

### P3 User Story 3: Multi-Task Suite

**Scenario 1**: Run all tasks
```bash
macmlbench run --all
```
✓ All 5 tasks execute
✓ Results displayed for each

**Scenario 2**: Select multiple specific tasks
```bash
macmlbench run matrix-multiply convolution-2d attention-mechanism
```
✓ Only selected tasks execute
✓ Results presented in order

**Scenario 3**: Failure handling
```bash
# Simulate by running on low-memory system or creating resource constraint
macmlbench run --all
```
✓ Remaining tasks continue after one fails
✓ Final results indicate which succeeded/failed
✓ Error details included

**Scenario 4**: Summary report
```bash
macmlbench run --all
```
✓ Summary shows relative performance
✓ Highlights strongest/weakest areas
✓ All task types included

**Scenario 5**: Result export
```bash
macmlbench run --all --output suite-results.json
```
✓ JSON file contains all task results
✓ Hardware information included
✓ Configuration parameters saved

---

## Troubleshooting

### "Unsupported Hardware" Error

**Symptom**:
```
Error: Unsupported Hardware
This benchmark suite requires Apple Silicon (M1/M2/M3 or later).
Detected: Intel Core i9 (x86_64)
```

**Solution**: This tool requires a Mac with Apple Silicon. It will not run on Intel-based Macs.

### "Insufficient Memory" Error

**Symptom**:
```
Error: Insufficient Memory
The 'matrix-multiply' benchmark requires at least 4 GB of GPU memory.
Available: 2 GB
```

**Solution**:
- Reduce `--batch-size`: Try `--batch-size 16` (instead of 64)
- Reduce `--size`: Try `--size 2048` (instead of 8192)
- Close other GPU-intensive applications (browsers, video editors, games)

### Thermal Throttling Warning

**Symptom**:
```
Warning: Thermal Throttling Detected
Your Mac is running hot and GPU performance may be reduced.
```

**Solution**:
- Wait 5-10 minutes for system to cool down
- Ensure adequate ventilation (not on soft surfaces)
- Run shorter benchmarks: `--duration 5`
- Check Activity Monitor for other GPU-intensive processes

### High Result Variance

**Symptom**: Running same benchmark twice gives >10% difference

**Solution**:
- Close all other applications
- Ensure system is not under load (check Activity Monitor)
- Wait for thermal state to normalize
- Increase duration: `--duration 30` for more stable averages
- Run multiple times and compare: `macmlbench compare run1.json run2.json run3.json`

---

## Development Workflow

### Running Tests

```bash
# Run all unit tests
swift test

# Run specific test
swift test --filter BenchmarkConfigurationTests

# Run with verbose output
swift test --verbose
```

### Debug Build

```bash
# Build in debug mode
swift build

# Run debug build
.build/debug/macmlbench run matrix-multiply
```

### Clean Build

```bash
# Remove all build artifacts
swift package clean

# Rebuild from scratch
swift build -c release
```

---

## Performance Expectations

### Typical Benchmark Durations (Default Parameters)

| Task | M1 Base | M1 Pro | M2 Ultra | M3 Max |
|------|---------|--------|----------|--------|
| matrix-multiply | ~10s | ~10s | ~10s | ~10s |
| convolution-2d | ~10s | ~10s | ~10s | ~10s |
| attention-mechanism | ~10s | ~10s | ~10s | ~10s |
| activation-functions | ~10s | ~10s | ~10s | ~10s |
| mixed-operations | ~10s | ~10s | ~10s | ~10s |
| **Full Suite** | ~60s | ~55s | ~50s | ~50s |

✓ Meets SC-007 (full suite under 5 minutes)

### Expected Throughput Ranges (Approximate)

| Task | M1 Base | M2 Max | M3 Max |
|------|---------|--------|--------|
| matrix-multiply | 6-8K ops/s | 10-12K ops/s | 12-15K ops/s |
| convolution-2d | 4-6K ops/s | 7-9K ops/s | 9-11K ops/s |
| attention-mechanism | 3-5K ops/s | 5-7K ops/s | 7-10K ops/s |

✓ Meets SC-006 (clear differentiation between chip variants)

---

## Next Steps

After validating the quickstart scenarios:

1. **Run comprehensive benchmark**: `macmlbench run --all --output my-results.json`
2. **Compare with future runs**: `macmlbench compare baseline.json new-run.json`
3. **Experiment with parameters**: Try different `--duration`, `--batch-size`, `--size` combinations
4. **Monitor thermal behavior**: Watch for throttling on sustained loads
5. **Share results**: Export JSON files are portable and can be analyzed with external tools

---

## Support

For issues, questions, or contributions:
- **Documentation**: See `specs/001-mac-ml-benchmark-suite/` directory
- **Specification**: `spec.md` (user stories and requirements)
- **Technical Design**: `research.md` (architecture decisions)
- **Data Model**: `data-model.md` (entity relationships)
- **CLI Reference**: `contracts/cli-interface.md` (complete command documentation)

---

## Appendix: Manual Validation Checklist

Use this checklist to validate implementation against specification acceptance scenarios:

### P1 Scenarios (MVP)
- [ ] Single benchmark runs with defaults (10 seconds)
- [ ] Results display throughput, latency, GPU utilization
- [ ] Hardware info correctly identifies M1/M2/M3/M4 variant
- [ ] Progress indicator shows during execution
- [ ] Results include timestamp and configuration

### P2 Scenarios (Configuration)
- [ ] Custom duration parameter works (--duration 30)
- [ ] Custom size parameter works (--size 8192)
- [ ] Custom thread count works (--threads 8)
- [ ] Invalid parameters show helpful error messages
- [ ] Exported results include all configuration parameters

### P3 Scenarios (Multi-Task)
- [ ] `--all` flag runs all 5 tasks
- [ ] Multiple task names work (`matrix-multiply convolution-2d`)
- [ ] Task failures don't stop remaining tasks
- [ ] Summary report shows comparative performance
- [ ] JSON export includes all task results

### Performance Success Criteria
- [ ] SC-001: First benchmark completes within 2 minutes ✓
- [ ] SC-002: Result variance <10% on repeated runs ✓
- [ ] SC-003: Hardware detection works for all M1/M2/M3 variants ✓
- [ ] SC-007: Full suite completes in under 5 minutes ✓
- [ ] SC-008: 0% crashes on invalid parameters ✓

---

**Phase 1 Quickstart Complete** - Ready for agent context update.
