# Quickstart Guide: Remote Deployment and Interactive Menu

**Date**: 2025-10-16
**Feature**: Remote Deployment and Interactive Menu

## Prerequisites

- Feature 001 (Mac ML Benchmark Suite) complete and built
- SSH access to remote Mac machines (SSH keys configured)
- Remote machines have SSH enabled (System Settings > General > Sharing > Remote Login)

## Interactive Menu (P1)

```bash
# Launch interactive menu
macmlbench menu

# Follow prompts to select benchmarks and configure parameters
```

## Remote Deployment (P2)

```bash
# Deploy to a remote machine
macmlbench deploy 10.20.1.64 --username willsauter --key ~/.ssh/id_ed25519

# Run benchmark on remote machine
macmlbench remote 10.20.1.64 run matrix-multiply --output remote-results.json
```

## Multi-Machine Execution (P3)

```bash
# Configure machines (first time)
macmlbench menu
# Select "Manage Remote Machines" → "Add New Machine"

# Run benchmarks across all machines
macmlbench menu
# Select "Run Benchmarks" → Select tasks → Select "All Machines"
```

## Validation

### P1: Interactive menu launches and allows task selection
### P2: Deploy to remote and execute successfully
### P3: Multi-machine run aggregates results from all machines
