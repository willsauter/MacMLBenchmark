# CLI Interface Contract: Mac ML Benchmark Suite

**Date**: 2025-10-16
**Feature**: Mac ML Benchmark Suite
**Phase**: Phase 1 - Design & Contracts

## Overview

This document specifies the command-line interface contract for the Mac ML Benchmark Suite. All commands, arguments, options, and output formats are defined here to ensure consistent implementation matching the specification's functional requirements.

---

## Command Structure

```
macmlbench <command> [arguments] [options]
```

**Global Requirements**:
- All commands must display help with `--help` or `-h` flag (FR-013)
- All commands must validate inputs before execution (FR-008)
- All commands must handle Ctrl+C gracefully (edge case requirement)
- Invalid commands must display suggestion for correct usage

---

## Commands

### 1. `run` - Execute Benchmark(s)

**Purpose**: Run one or more benchmark tasks (FR-001, FR-003)

**Syntax**:
```bash
macmlbench run <task-name> [options]
macmlbench run --all [options]
```

**Arguments**:
- `<task-name>`: Name of specific benchmark task to execute
  - Valid values: `matrix-multiply`, `convolution-2d`, `attention-mechanism`, `activation-functions`, `mixed-operations`
  - Multiple tasks: `macmlbench run matrix-multiply convolution-2d`
- `--all`: Run all available benchmark tasks

**Options**:
- `--duration <seconds>`: Benchmark duration (default: 10)
  - Type: Integer
  - Range: 1-3600
  - Unit: seconds
  - Example: `--duration 30`

- `--batch-size <n>`: Number of samples per batch (default: task-specific)
  - Type: Integer
  - Range: 1-1024
  - Example: `--batch-size 64`

- `--threads <n>`: Number of CPU threads (default: system core count)
  - Type: Integer
  - Range: 1-<system_cores>
  - Example: `--threads 8`

- `--size <n>`: Task-specific size parameter (default: task-specific)
  - Type: Integer
  - Range: 128-8192
  - Meaning: Matrix dimension, image size, sequence length (task-dependent)
  - Example: `--size 4096`

- `--output <path>`: Export results to file (default: no export)
  - Type: File path
  - Format: Auto-detected from extension (.json or .csv)
  - Example: `--output ./results/my-benchmark.json`

- `--help, -h`: Display help for run command

**Behavior**:
- Detects hardware at startup → displays HardwareProfile
- Validates all parameters before GPU allocation
- Executes tasks sequentially (one at a time for thermal stability)
- Displays real-time progress for each task (FR-009)
- Displays results immediately after each task completion (FR-010)
- If `--output` specified, exports results after all tasks complete (FR-011)
- If multi-task and one fails, continues with remaining tasks (FR-012)

**Exit Codes**:
- `0`: All tasks completed successfully
- `1`: Invalid parameters
- `2`: Hardware requirements not met
- `3`: One or more tasks failed (partial success)
- `130`: User interrupted (Ctrl+C)

**Examples**:
```bash
# Run single task with defaults
macmlbench run matrix-multiply

# Run single task with custom parameters
macmlbench run matrix-multiply --duration 30 --size 8192 --batch-size 64

# Run multiple tasks with custom config
macmlbench run matrix-multiply convolution-2d --duration 20 --output results.json

# Run all tasks with export
macmlbench run --all --duration 15 --output full-benchmark.json

# Run with specific thread count
macmlbench run attention-mechanism --threads 4 --duration 60
```

**Output Format** (stdout, FR-010):
```
Mac ML Benchmark Suite
======================

Hardware Profile:
  Model: Mac Studio (2023)
  Chip: M2 Ultra
  GPU Cores: 76
  Memory: 128 GB
  macOS: 14.2

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

---

### 2. `list` - List Available Benchmarks

**Purpose**: Display all available benchmark tasks and their parameters (FR-013)

**Syntax**:
```bash
macmlbench list [options]
```

**Options**:
- `--verbose, -v`: Show detailed parameter information
- `--help, -h`: Display help for list command

**Behavior**:
- Lists all built-in benchmark tasks
- Shows task type, description, and default parameters
- If `--verbose`, displays full parameter constraints and resource requirements

**Exit Codes**:
- `0`: Success

**Examples**:
```bash
# List all tasks
macmlbench list

# List with detailed parameter info
macmlbench list --verbose
```

**Output Format** (stdout):
```
Available Benchmark Tasks:
==========================

1. matrix-multiply
   Type: Inference
   Description: Measures GPU throughput for large matrix operations
   Default Parameters:
     - duration: 10 seconds
     - batch_size: 32
     - size: 4096

2. convolution-2d
   Type: Inference
   Description: Measures convolution performance for CNN workloads
   Default Parameters:
     - duration: 10 seconds
     - batch_size: 16
     - image_size: 1024
     - kernel_size: 3

[... remaining tasks ...]

Run with --verbose for full parameter details.
```

**Verbose Output** (with `--verbose`):
```
[Task listing as above, plus:]

Parameters:
  --duration <seconds>
    Type: Integer
    Range: 1-3600
    Default: 10
    Description: How long to run the benchmark

  --batch-size <n>
    Type: Integer
    Range: 1-1024
    Default: Task-specific
    Description: Number of samples per batch

[... all parameters with constraints ...]
```

---

### 3. `compare` - Compare Benchmark Results

**Purpose**: Compare results from multiple benchmark runs (FR-014)

**Syntax**:
```bash
macmlbench compare <file1> <file2> [file3...] [options]
```

**Arguments**:
- `<file1> <file2> [file3...]`: Paths to result files (JSON format)
  - Minimum 2 files required
  - Must be valid JSON exports from previous runs

**Options**:
- `--output <path>`: Export comparison to file (default: stdout only)
- `--help, -h`: Display help for compare command

**Behavior**:
- Loads all specified result files
- Matches tasks by name across files
- Calculates percentage deltas for all metrics
- Displays side-by-side comparison
- Highlights significant differences (>10% change)

**Exit Codes**:
- `0`: Comparison successful
- `1`: Invalid file paths or corrupted JSON
- `2`: No matching tasks found across files

**Examples**:
```bash
# Compare two runs
macmlbench compare baseline.json new-config.json

# Compare multiple runs
macmlbench compare run1.json run2.json run3.json

# Compare and export
macmlbench compare old.json new.json --output comparison.txt
```

**Output Format** (stdout):
```
Benchmark Comparison
====================

Comparing 2 runs:
  Run 1: baseline.json (2025-10-16 10:30:45, M2 Ultra, 76 GPU cores)
  Run 2: new-config.json (2025-10-16 11:15:22, M2 Ultra, 76 GPU cores)

Task: matrix-multiply
---------------------
  Throughput:     12,500 ops/sec → 13,750 ops/sec  (+10.0%) ↑
  Latency:        0.08 ms → 0.07 ms                (-12.5%) ↓
  GPU Util:       95% → 97%                        (+2.1%)
  Peak Memory:    2,048 MB → 2,048 MB              (no change)

Task: convolution-2d
--------------------
  Throughput:     8,200 ops/sec → 8,150 ops/sec   (-0.6%)
  Latency:        0.12 ms → 0.12 ms               (no change)
  GPU Util:       88% → 87%                        (-1.1%)
  Peak Memory:    1,536 MB → 1,536 MB             (no change)

Summary:
  Tasks compared: 2
  Significant improvements: 1 (matrix-multiply throughput)
  Regressions: 0
```

---

### 4. `hardware` - Display Hardware Information

**Purpose**: Show detected hardware profile without running benchmarks

**Syntax**:
```bash
macmlbench hardware [options]
```

**Options**:
- `--json`: Output in JSON format
- `--help, -h`: Display help for hardware command

**Behavior**:
- Detects and displays HardwareProfile
- Validates macOS version compatibility (>= 12.0)
- Checks if running on Apple Silicon

**Exit Codes**:
- `0`: Hardware detection successful
- `1`: Unsupported hardware (Intel Mac, non-Mac)
- `2`: macOS version too old

**Examples**:
```bash
# Show hardware info
macmlbench hardware

# Output as JSON
macmlbench hardware --json
```

**Output Format** (stdout):
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

**JSON Output** (with `--json`):
```json
{
  "hardware_profile": {
    "model_name": "Mac Studio (2023)",
    "chip_identifier": "M2 Ultra",
    "gpu_core_count": 76,
    "cpu_core_count": 24,
    "total_memory_gb": 128,
    "gpu_memory_gb": 64,
    "macos_version": "14.2",
    "is_compatible": true,
    "detection_timestamp": "2025-10-16T10:30:45Z"
  }
}
```

---

### 5. `version` - Display Version Information

**Purpose**: Show tool version and build info

**Syntax**:
```bash
macmlbench version
macmlbench --version
```

**Behavior**:
- Displays version number, build date, Swift version

**Exit Codes**:
- `0`: Success

**Output Format**:
```
Mac ML Benchmark Suite
Version: 1.0.0
Build: 2025-10-16
Swift: 5.9
Metal API: 3.1
```

---

## Error Handling

### Invalid Parameter Errors (FR-008, SC-008)

**Format**:
```
Error: Invalid value for '--duration': -5

The --duration parameter must be between 1 and 3600 seconds.

Example:
  macmlbench run matrix-multiply --duration 30
```

**Requirements**:
- Clear error message stating what went wrong
- Explanation of valid ranges/options
- Example of correct usage
- Exit code 1

### Hardware Incompatibility Errors

**Format**:
```
Error: Unsupported Hardware

This benchmark suite requires Apple Silicon (M1/M2/M3 or later).
Detected: Intel Core i9 (x86_64)

The tool cannot run on Intel-based Macs.
```

**Exit code**: 2

### Resource Constraint Errors (Edge Case)

**Format**:
```
Error: Insufficient Memory

The 'matrix-multiply' benchmark with current parameters requires at least 4 GB of available GPU memory.
Available: 2 GB

Suggestions:
  - Reduce --batch-size: try --batch-size 16 (currently 64)
  - Reduce --size: try --size 2048 (currently 8192)
  - Close other GPU-intensive applications
```

**Exit code**: 2

### Thermal Throttling Warning

**Format**:
```
Warning: Thermal Throttling Detected

Your Mac is running hot and GPU performance may be reduced.
Results may not be representative of maximum performance.

Suggestions:
  - Wait for system to cool down
  - Ensure adequate ventilation
  - Run shorter benchmarks (reduce --duration)

Continue anyway? [y/N]:
```

**Behavior**: Prompt user before continuing (not an error, just a warning)

---

## JSON Export Format (FR-011)

**Structure**:
```json
{
  "benchmark_run": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "timestamp": "2025-10-16T10:30:45Z",
    "hardware": {
      "model_name": "Mac Studio (2023)",
      "chip_identifier": "M2 Ultra",
      "gpu_core_count": 76,
      "total_memory_gb": 128,
      "macos_version": "14.2"
    },
    "configuration": {
      "duration": 10,
      "custom_parameters": {
        "matrix-multiply": {
          "batch_size": 32,
          "size": 4096
        }
      }
    },
    "results": [
      {
        "id": "660e9400-f30c-52e5-b827-557766551111",
        "task_name": "matrix-multiply",
        "start_timestamp": "2025-10-16T10:30:45Z",
        "end_timestamp": "2025-10-16T10:30:55Z",
        "duration_seconds": 10.02,
        "metrics": {
          "throughput_ops_per_sec": 12500.0,
          "latency_ms": 0.08,
          "gpu_utilization_percent": 95.0,
          "peak_memory_usage_mb": 2048,
          "average_memory_usage_mb": 1856,
          "iterations_completed": 125000
        },
        "status": "success",
        "thermal_state": "nominal"
      }
    ]
  }
}
```

**Validation**:
- All fields required unless marked optional (error_message)
- All numeric values must be non-negative
- Timestamps must be ISO8601 format
- Status must be one of: `success`, `failed`, `throttled`, `partially_completed`

---

## CSV Export Format (Alternative)

**Structure** (flattened):
```csv
timestamp,hardware_model,chip,gpu_cores,task_name,duration_sec,throughput_ops_sec,latency_ms,gpu_util_%,memory_mb,status
2025-10-16T10:30:45Z,Mac Studio (2023),M2 Ultra,76,matrix-multiply,10.02,12500.0,0.08,95.0,2048,success
```

**Notes**:
- One row per task result
- Hardware info repeated in each row for standalone analysis
- Configuration parameters included as additional columns

---

## Help Output (FR-013)

**Global Help** (`macmlbench --help`):
```
Mac ML Benchmark Suite

USAGE:
  macmlbench <command> [options]

COMMANDS:
  run         Execute one or more benchmarks
  list        List available benchmark tasks
  compare     Compare results from multiple runs
  hardware    Display detected hardware information
  version     Show version information

OPTIONS:
  --help, -h  Show this help message

EXAMPLES:
  # Run a single benchmark
  macmlbench run matrix-multiply --duration 30

  # Run all benchmarks and export results
  macmlbench run --all --output results.json

  # List available tasks
  macmlbench list

  # Compare two runs
  macmlbench compare baseline.json experiment.json

For more information on a specific command, run:
  macmlbench <command> --help
```

---

## User Story Mapping

### P1: Quick Benchmark Execution
- **Command**: `macmlbench run matrix-multiply`
- **Acceptance**: Runs single task with defaults, displays results

### P2: Configurable Parameters
- **Command**: `macmlbench run matrix-multiply --duration 60 --batch-size 64 --size 8192`
- **Acceptance**: Custom parameters respected, results reflect configuration

### P3: Multi-Task Suite
- **Command**: `macmlbench run --all --output full-benchmark.json`
- **Acceptance**: All tasks execute, results exported, comparison available via `compare`

---

## Implementation Requirements

### ArgumentParser Structure (Swift)
```swift
@main
struct MacMLBench: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "macmlbench",
    abstract: "Mac ML Benchmark Suite",
    subcommands: [Run.self, List.self, Compare.self, Hardware.self, Version.self]
  )
}

struct Run: ParsableCommand {
  @Argument(help: "Benchmark task name(s) to execute")
  var tasks: [String] = []

  @Flag(name: .long, help: "Run all available benchmarks")
  var all: Bool = false

  @Option(name: .long, help: "Benchmark duration in seconds (1-3600)")
  var duration: Int = 10

  @Option(name: .long, help: "Batch size (1-1024)")
  var batchSize: Int?

  @Option(name: .long, help: "Thread count (1-cores)")
  var threads: Int?

  @Option(name: .long, help: "Size parameter (128-8192)")
  var size: Int?

  @Option(name: .long, help: "Export results to file (.json or .csv)")
  var output: String?

  func validate() throws {
    // Parameter validation before execution
  }

  func run() throws {
    // Execution logic
  }
}
```

---

## Phase 1 Contracts Complete

All CLI interface contracts defined:
- ✅ 5 commands (run, list, compare, hardware, version)
- ✅ All parameters with types, ranges, defaults
- ✅ Error formats with helpful messages
- ✅ JSON/CSV export structures
- ✅ Help output format
- ✅ Exit codes for all scenarios
- ✅ User story mapping to commands

Ready for quickstart.md (build/run instructions).
