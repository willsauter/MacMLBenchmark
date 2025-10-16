# Menu Interface Contract: Interactive Menu

**Date**: 2025-10-16
**Feature**: Remote Deployment and Interactive Menu

## Menu Command

**Syntax**: `macmlbench menu` or `macmlbench` (interactive mode)

## Menu Flow States

### 1. Main Menu
```
Mac ML Benchmark Suite - Interactive Menu
==========================================

1. Run Benchmarks
2. Manage Remote Machines
3. View Results
4. Exit

Select option (1-4):
```

### 2. Benchmark Selection
```
Select Benchmarks to Run
========================

1. [x] Matrix Multiplication
2. [ ] 2D Convolution
3. [ ] Attention Mechanism
4. [ ] Activation Functions
5. [ ] Mixed Operations
6. [x] Select All
7. Continue to Configuration

Enter numbers to toggle (e.g., 1,3,5 or 'all'):
```

### 3. Parameter Configuration
```
Configure Parameters
====================

Current Configuration:
  Duration: 10 seconds
  Size: 4096 (matrix/image/sequence dimension)
  Batch Size: 32
  Threads: 14 (system cores)

1. Change Duration
2. Change Size
3. Change Batch Size
4. Change Threads
5. Use Defaults
6. Continue to Machine Selection

Select option:
```

### 4. Machine Selection
```
Select Execution Machines
=========================

Local Machine:
  ✓ Mac16,8 (M4 Pro, 20 GPU cores)

Remote Machines:
1. [ ] Mac Studio (M3 Ultra) - 10.20.1.64 [Deployed: v1.0.0]
2. [ ] MacBook (M4 Max) - 10.20.1.89 [Not Deployed]

3. Add New Remote Machine
4. Run on Local Only
5. Run on Selected Machines
6. Back

Select option:
```

### 5. Execution & Results
```
Executing Benchmarks...
=======================

[Local] Matrix Multiplication: [##########----------] 50% (5.2s)
[Remote-1] Matrix Multiplication: [#######-------------] 35% (3.5s)
[Remote-2] Connecting...

Results will appear as each machine completes.
```

## User Story Mapping

- **P1 (MVP)**: States 1-5 with local execution only
- **P2**: Adds remote machine configuration and deployment
- **P3**: Enables multi-machine selection and parallel execution
