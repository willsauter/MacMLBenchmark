# Mac ML Benchmark Suite

A comprehensive GPU benchmarking tool for Mac Silicon (M1/M2/M3) designed for ML and AI workload performance evaluation.

## Overview

The Mac ML Benchmark Suite allows ML/AI developers to measure and compare Mac Silicon GPU performance across different workloads including:
- Matrix multiplication (transformer layer simulation)
- 2D convolution (CNN simulation)
- Attention mechanisms (LLM representative operations)
- Activation functions (memory bandwidth tests)
- Mixed operations (training simulations)

## Quick Start

See [quickstart.md](specs/001-mac-ml-benchmark-suite/quickstart.md) for detailed build instructions, usage examples, and manual validation steps.

## Features

- **Quick Benchmarking**: Run single benchmarks with default settings in seconds
- **Configurable Parameters**: Customize duration, size, threads, and batch size
- **Multi-Task Suite**: Run comprehensive benchmark suites with result export
- **Hardware Detection**: Automatic Mac Silicon GPU identification and capability detection
- **Result Export**: JSON and CSV export for analysis and comparison
- **Comparison Tools**: Compare results across multiple benchmark runs

## Requirements

- **Hardware**: Mac with Apple Silicon (M1/M2/M3 or later)
- **OS**: macOS 12.0 (Monterey) or later
- **Development**: Swift 5.9+, Xcode 14.0+ or Xcode Command Line Tools

## Installation

```bash
# Clone repository
git clone <repository-url>
cd MacMLBenchmark

# Build with Swift Package Manager
swift build -c release

# Run
.build/release/macmlbench --help
```

## Basic Usage

```bash
# Run a single benchmark
macmlbench run matrix-multiply

# Run with custom parameters
macmlbench run matrix-multiply --duration 30 --size 8192

# Run all benchmarks and export results
macmlbench run --all --output results.json

# List available benchmarks
macmlbench list

# Check hardware compatibility
macmlbench hardware
```

## Documentation

- [Feature Specification](specs/001-mac-ml-benchmark-suite/spec.md) - User stories and requirements
- [Implementation Plan](specs/001-mac-ml-benchmark-suite/plan.md) - Technical architecture
- [Quick Start Guide](specs/001-mac-ml-benchmark-suite/quickstart.md) - Build and usage instructions
- [Data Model](specs/001-mac-ml-benchmark-suite/data-model.md) - Entity relationships
- [CLI Interface](specs/001-mac-ml-benchmark-suite/contracts/cli-interface.md) - Command reference

## Project Structure

```
src/
├── models/              # Data entities
├── benchmarks/          # Benchmark implementations
├── hardware/            # Hardware detection and monitoring
├── metrics/             # Performance metric collection
├── output/              # Result formatting and export
├── cli/                 # Command-line interface
└── main.swift           # Entry point

tests/
├── integration/         # Manual integration tests
└── unit/                # Unit tests
```

## Development

```bash
# Build in debug mode
swift build

# Run tests
swift test

# Clean build artifacts
swift package clean
```

## License

See LICENSE file for details.

## Contributing

See CONTRIBUTING.md for guidelines.

## Support

For issues or questions, see the specification and planning documents in `specs/001-mac-ml-benchmark-suite/`.
