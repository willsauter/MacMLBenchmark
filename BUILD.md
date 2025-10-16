# Build Instructions - Mac ML Benchmark Suite

## Prerequisites

### Required
- **Hardware**: Mac with Apple Silicon (M1/M2/M3/M4 or later)
- **OS**: macOS 12.0 (Monterey) or later
- **Development Tools**: Xcode 14.0+ or Xcode Command Line Tools
- **Swift**: 5.9 or later (included with Xcode)

### Optional (for ML Framework benchmarks)
- **Python**: 3.12.x (for TensorFlow support)
- **Homebrew**: For installing Python 3.12

---

## Quick Start (Metal Benchmarks Only)

```bash
# 1. Clone the repository
git clone <repository-url>
cd MacMLBenchmark

# 2. Build the project
swift build -c release

# 3. Run a benchmark
.build/release/macmlbench run matrix-multiply

# 4. Or launch interactive menu
.build/release/macmlbench
```

That's it! The core Metal GPU benchmarks work immediately with no additional setup.

---

## Full Setup (Including Framework Benchmarks)

### Step 1: Install Xcode Command Line Tools

```bash
xcode-select --install
```

Verify installation:
```bash
swift --version
# Should show: Swift version 5.9 or later
```

### Step 2: Clone and Build

```bash
git clone <repository-url>
cd MacMLBenchmark

# Build in release mode (optimized)
swift build -c release

# Verify build
.build/release/macmlbench --version
# Should show: 1.0.0
```

### Step 3: Install Python 3.12 (for Framework Benchmarks)

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python 3.12
brew install python@3.12

# Verify installation
python3.12 --version
# Should show: Python 3.12.x
```

### Step 4: Setup Python Virtual Environment

```bash
# Create virtual environment with Python 3.12
python3.12 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate

# Verify Python version in venv
python3 --version
# Should show: Python 3.12.x (not 3.13!)

# Install ML framework packages
pip install torch numpy tensorflow-macos transformers

# Verify installations
python3 -c "import torch; print('PyTorch:', torch.__version__)"
python3 -c "import tensorflow as tf; print('TensorFlow:', tf.__version__)"
```

### Step 5: Test Framework Benchmarks

```bash
# Make sure venv is activated
source .venv/bin/activate

# Test Python scripts directly
python3 src/python/pytorch_benchmark.py 3 1024
python3 src/python/tensorflow_benchmark.py 3 1024

# Both should output JSON with metrics

# Run through the tool
.build/release/macmlbench run pytorch-matmul --duration 5
.build/release/macmlbench run tensorflow-matmul --duration 5
```

---

## Build Modes

### Debug Build
```bash
swift build
# Output: .build/debug/macmlbench
```

### Release Build (Recommended)
```bash
swift build -c release
# Output: .build/release/macmlbench
# Optimized for performance
```

### Clean Build
```bash
swift package clean
swift build -c release
```

---

## Installation (Optional)

### Install to System PATH

```bash
# Copy to /usr/local/bin for system-wide access
sudo cp .build/release/macmlbench /usr/local/bin/

# Then run from anywhere
macmlbench --version
```

### Uninstall
```bash
sudo rm /usr/local/bin/macmlbench
```

---

## Troubleshooting

### "No such module 'XCTest'" when building
This is a warning for test files and can be ignored. The release build will succeed.

### "Permission denied" when running executable
```bash
chmod +x .build/release/macmlbench
```

### Python benchmarks fail with "Module not found"
1. Verify venv is activated: `which python3` should show `.venv/bin/python3`
2. Verify packages installed: `pip list | grep torch`
3. Ensure venv was created with Python 3.12, not 3.13

### TensorFlow "No GPU available" error
This is fixed in the latest version. TensorFlow-macos uses Metal automatically on Apple Silicon.

### Build fails with Swift version error
Update Xcode or Command Line Tools:
```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

---

## Directory Structure After Build

```
MacMLBenchmark/
├── .build/                 # Build artifacts
│   └── release/
│       └── macmlbench      # Compiled executable
├── .venv/                  # Python virtual environment (if created)
├── models/                 # Cached ML models (created at runtime)
├── results/                # Benchmark results (created at runtime)
├── config/                 # SSH machine profiles (created at runtime)
├── src/                    # Source code
│   ├── benchmarks/         # Benchmark implementations
│   ├── cli/                # Command-line interface
│   ├── models/             # Data models
│   ├── hardware/           # Hardware detection
│   ├── menu/               # Interactive menu
│   ├── remote/             # SSH/remote execution
│   ├── python/             # Python framework scripts
│   └── main.swift          # Entry point
├── tests/                  # Unit and integration tests
├── specs/                  # Feature specifications
├── Package.swift           # Swift package manifest
└── README.md               # Project overview
```

---

## Quick Command Reference

```bash
# Build
swift build -c release

# Run single benchmark
.build/release/macmlbench run matrix-multiply

# Run with custom parameters
.build/release/macmlbench run matrix-multiply --duration 30 --size 8192

# Run all benchmarks
.build/release/macmlbench run --all

# Interactive menu
.build/release/macmlbench menu

# List available benchmarks
.build/release/macmlbench list

# Compare results
.build/release/macmlbench compare results/run1.json results/run2.json

# Show hardware info
.build/release/macmlbench hardware

# Show version
.build/release/macmlbench version
```

---

## Remote Machine Setup

To run benchmarks on remote Mac machines:

1. **Enable SSH on remote machine**:
   - System Settings > General > Sharing > Remote Login (ON)

2. **Setup SSH keys**:
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub username@remote-host
   ```

3. **Add machine via menu**:
   ```bash
   .build/release/macmlbench menu
   # Select "Manage Remote Machines" > "Add New Machine"
   ```

4. **Deploy and run**:
   - Menu > Manage Remote Machines > Deploy to Machine
   - Menu > Run Benchmarks > Select machines > Execute

---

## Development

### Run Tests
```bash
swift test
```

### Build Documentation
All documentation is in `specs/` directory:
- `specs/001-mac-ml-benchmark-suite/` - Metal benchmarks
- `specs/002-remote-deploy-menu/` - Interactive menu & remote
- `specs/003-ml-library-benchmarks/` - Framework integration

### Adding New Benchmarks
See `src/benchmarks/BenchmarkProtocol.swift` for the interface.
Register new benchmarks in `src/benchmarks/BenchmarkRegistry.swift`.

---

## Support

- **Specifications**: See `specs/` directory for feature details
- **Manual Tests**: See `tests/integration/ManualTestPlan.md`
- **Quickstart**: See `specs/*/quickstart.md` in each feature directory
- **Issues**: Check build output and error messages for guidance

---

**Last Updated**: 2025-10-16
**Version**: 1.0.0
**Swift**: 5.9+
**Python**: 3.12 (for frameworks)
