# Research & Technical Decisions: Mac ML Benchmark Suite

**Date**: 2025-10-16
**Feature**: Mac ML Benchmark Suite
**Phase**: Phase 0 - Outline & Research

## Overview

This document consolidates research findings and technical decisions for implementing a Mac Silicon GPU benchmark suite for ML/AI workloads. All decisions prioritize simplicity, macOS API compatibility, and alignment with the specification's performance and user experience goals.

---

## Decision 1: Programming Language

**Decision**: Swift 5.9+

**Rationale**:
- **Native Metal Access**: Swift provides first-class access to Metal Performance Shaders (MPS) framework, which is the only way to directly program Apple Silicon GPUs
- **System API Integration**: Swift's Foundation framework provides native APIs for hardware detection (ProcessInfo, sysctl), file I/O, and system monitoring without FFI overhead
- **Performance**: Swift is compiled and provides C-like performance, critical for accurate benchmark timing and minimal measurement overhead
- **Ecosystem**: Swift Package Manager (SPM) provides dependency management; ArgumentParser is the standard CLI library; mature JSON encoding/decoding built into Foundation

**Alternatives Considered**:
- **Python**: Easier to write but adds interpreter overhead that could skew benchmark timings. Metal bindings (PyObjC) are less mature and add complexity. Not ideal for performance-critical tool.
- **C++**: Direct Metal access possible via Objective-C++ but significantly more complex. No benefit over Swift for macOS-exclusive tool.
- **Rust**: Excellent performance but Metal bindings immature. Would require Objective-C interop, adding complexity without clear benefit for macOS-only tool.

---

## Decision 2: GPU API / Compute Framework

**Decision**: Metal Performance Shaders (MPS) + Metal Compute Kernels

**Rationale**:
- **Only Option**: Metal is the exclusive API for Apple Silicon GPU programming. No alternatives (CUDA, OpenCL deprecated on macOS).
- **MPS for Common Operations**: MPS provides optimized implementations of common ML operations (matrix multiplication, convolutions, activations) that are representative of real ML workloads
- **Custom Compute Kernels**: For benchmark tasks not covered by MPS (e.g., attention mechanisms), Metal compute shaders provide full GPU control
- **Performance Monitoring**: Metal framework includes performance counters and GPU utilization APIs needed for FR-006

**Alternatives Considered**:
- **None viable**: OpenCL deprecated on macOS 10.14, CUDA unavailable on Apple Silicon, Vulkan not supported

---

## Decision 3: Benchmark Task Implementations

**Decision**: Use MPS primitives to simulate ML workload patterns, not full model execution

**Rationale**:
- **Spec Assumption 2**: Benchmark tasks use "representative ML/AI operations (matrix multiplication, convolutions, attention mechanisms) rather than running actual large language models"
- **Fast Execution**: MPS primitives execute in milliseconds-to-seconds, meeting SC-007 (full suite under 5 minutes)
- **Minimal Dependencies**: No need to ship large model weights or depend on ML frameworks (CoreML, TensorFlow)
- **Workload Diversity**: MPS covers matrix ops, convolutions, activations, pooling, normalization - enough to create 5+ distinct task types

**Benchmark Task Types** (meets FR-002 and SC-005):
1. **Matrix Multiplication**: Simulates transformer layer forward pass (matmul heavy)
2. **Convolution**: Simulates CNN inference (conv2d operations)
3. **Attention Mechanism**: Custom compute kernel for scaled dot-product attention (LLM representative)
4. **Activation Functions**: GELU/ReLU/Softmax at scale (memory bandwidth bound)
5. **Mixed Operations**: Combines matmul + activations + normalization (training simulation)

**Alternatives Considered**:
- **Run actual models (CoreML)**: Too slow (minutes per model), large dependencies (GB of weights), violates Assumption 2
- **Synthetic compute (just math)**: Less representative of real ML workloads, doesn't stress memory hierarchy like real ML ops

---

## Decision 4: Hardware Detection

**Decision**: Use IOKit + sysctl for chip identification, Metal API for GPU specs

**Rationale**:
- **Chip Identification**: `sysctlbyname("machdep.cpu.brand_string")` returns "Apple M1/M2/M3" identifier
- **GPU Core Count**: `MTLDevice.recommendedMaxWorkingSetSize` and device feature set indicate GPU variant (base/Pro/Max/Ultra)
- **Memory Info**: `ProcessInfo.physicalMemory` for total RAM, Metal device properties for GPU memory
- **Thermal State**: `ProcessInfo.thermalState` monitors thermal throttling (FR-006 edge case requirement)

**Alternatives Considered**:
- **system_profiler command**: Too slow (multi-second execution), overkill for simple hardware ID
- **Hard-coded detection rules**: Fragile, breaks with new hardware releases

---

## Decision 5: CLI Framework

**Decision**: Swift ArgumentParser

**Rationale**:
- **Standard Library**: Developed by Apple, de facto standard for Swift CLI tools
- **Type-Safe**: Compile-time validation of argument types, automatic help generation
- **User-Friendly**: Supports subcommands, flags, options with validation (meets FR-008)
- **Lightweight**: Single package dependency, no runtime overhead

**CLI Structure**:
```
macmlbench <command> [options]

Commands:
  run <task-name>     Run specific benchmark task
  run --all           Run all benchmark tasks
  list                List available tasks and parameters
  compare <files>     Compare results from multiple runs

Global Options:
  --duration <secs>   Benchmark duration (default: 10)
  --batch-size <n>    Batch size (default: task-specific)
  --threads <n>       Thread count (default: system cores)
  --output <path>     Export results to file (JSON/CSV)
  --help              Show help
```

**Alternatives Considered**:
- **Manual argument parsing**: Error-prone, poor UX, violates Code Quality principle
- **Commander/SwiftCLI**: Less mature, no advantages over ArgumentParser

---

## Decision 6: Result Storage & Export

**Decision**: In-memory during execution, JSON/CSV file export on demand

**Rationale**:
- **No Database**: Spec states "no database required" - simple file I/O sufficient
- **JSON Format**: Swift Codable + JSONEncoder built-in, human-readable, tool-friendly (meets FR-011)
- **CSV Format**: Easy Excel/spreadsheet import for non-technical users
- **File Location**: Default to `./results/` directory (created at runtime), user can override via --output flag

**Result File Format**:
```json
{
  "benchmark_run": {
    "timestamp": "2025-10-16T10:30:45Z",
    "hardware": { "model": "MacBook Pro", "chip": "M3 Max", "gpu_cores": 40 },
    "tasks": [
      {
        "name": "matrix-multiply",
        "config": { "duration": 10, "batch_size": 32, "size": 4096 },
        "metrics": { "throughput_ops_per_sec": 12500, "latency_ms": 0.08, "gpu_util_%": 95 }
      }
    ]
  }
}
```

**Alternatives Considered**:
- **SQLite**: Overkill for single-user tool, adds dependency and complexity
- **Binary format (Protocol Buffers)**: Not human-readable, requires decoder tools, violates Assumption 6

---

## Decision 7: Performance Measurement

**Decision**: Metal command buffer completion callbacks + high-resolution timers

**Rationale**:
- **GPU Timing**: `MTLCommandBuffer.addCompletedHandler` provides accurate GPU execution time (excludes CPU overhead)
- **Wall Clock**: `mach_absolute_time()` or `DispatchTime.now()` for total latency measurement
- **Iteration Count**: Run operation in loop for specified duration, count completed iterations for throughput calculation
- **GPU Utilization**: Poll `IOReport` framework during benchmark execution (Apple's GPU profiling backend)

**Metric Calculations** (meets FR-006):
- **Throughput**: `operations_completed / duration_seconds`
- **Latency**: `total_gpu_time / operations_completed`
- **GPU Utilization**: `(active_gpu_time / wall_clock_time) * 100`
- **Memory Usage**: `MTLDevice.currentAllocatedSize` sampled during execution

**Alternatives Considered**:
- **Instruments integration**: Too heavyweight for automated benchmarking, requires manual interpretation
- **CPU-side timing only**: Inaccurate for GPU work due to async execution and buffering

---

## Decision 8: Parameter Validation

**Decision**: Type-safe validation at CLI parse time + runtime constraints check

**Rationale**:
- **Early Validation**: ArgumentParser validates types and required args before execution starts
- **Range Validation**: Custom validation functions check ranges (duration > 0, threads <= cores, batch size <= memory limit)
- **Conflict Detection**: Cross-parameter validation (e.g., batch_size * element_size < available_memory) before GPU allocation
- **Helpful Errors**: Validation failures return specific messages with valid ranges (meets FR-008)

**Validation Rules** (derived from edge cases in spec):
- `duration`: 1-3600 seconds
- `batch_size`: 1-1024 (task-dependent, memory-checked at runtime)
- `threads`: 1-system_core_count
- `size`: 128-8192 (matrix dimensions, task-dependent)

**Alternatives Considered**:
- **Runtime-only validation**: Poor UX, wasted time on invalid inputs
- **No validation**: Violates FR-008 and edge case requirements

---

## Decision 9: Error Handling Strategy

**Decision**: Fail-fast for user errors, graceful fallback for resource constraints

**Rationale**:
- **Invalid Input**: Immediate exit with clear error message (meets FR-008, SC-008)
- **Resource Errors**: Catch Metal allocation failures, suggest parameter reductions (edge case: insufficient memory)
- **Multi-Task Mode**: Continue on task failure, report errors in summary (meets FR-012)
- **Interruption**: Register signal handler for SIGINT (Ctrl+C), clean up GPU resources, save partial results if requested

**Error Categories**:
- **User Error**: Invalid parameters, unsupported hardware → exit with explanation
- **Resource Constraint**: Out of memory, thermal throttling → attempt recovery or graceful degradation
- **Implementation Error**: Unexpected Metal errors → log details, continue with remaining tasks

**Alternatives Considered**:
- **Crash on any error**: Poor UX, violates graceful handling requirements
- **Silent failure**: Violates transparency requirements (users need to know why benchmarks failed)

---

## Decision 10: Testing Strategy

**Decision**: Manual validation against acceptance scenarios + unit tests for calculations

**Rationale**:
- **Spec Assumption**: "Manual validation steps that correspond to acceptance scenarios" (Testing Discipline principle)
- **Unit Tests**: XCTest for metric calculations, parameter validation, result formatting (testable without GPU)
- **Integration Tests**: Manual execution of acceptance scenarios from spec (P1/P2/P3 user stories)
- **No TDD Requirement**: Constitution's Testing Discipline principle allows manual validation when tests not explicitly requested

**Test Coverage**:
- **Unit**: Metric calculations, parameter validation, JSON/CSV export formatting
- **Manual**: Each acceptance scenario in spec.md becomes a manual test case
- **No Coverage Goal**: Focus on acceptance scenarios passing, not line coverage metrics

**Alternatives Considered**:
- **Full automated test suite**: Requires Metal mocking infrastructure, significant complexity for tool that will be manually verified anyway
- **No tests**: Violates Testing Discipline (even manual validation requires documented test cases)

---

## Open Questions & Assumptions

### Resolved Assumptions from Spec:
- ✅ macOS 12.0+ platform (Assumption 1)
- ✅ CLI tool, not GUI (Assumption 5)
- ✅ Representative operations, not full models (Assumption 2)
- ✅ Manual validation acceptable (Testing Discipline)
- ✅ No complex visualizations in exports (Assumption 6)

### Implementation Assumptions:
- Metal API stability maintained across macOS versions (Apple commitment)
- Thermal throttling detection best-effort (API limitations on some Mac models)
- Benchmark tasks complete deterministically (no non-deterministic GPU operations)
- Users running on Apple Silicon Macs (spec requirement, not Intel-compatible)

---

## Summary

All technical decisions made with rationale documented. No NEEDS CLARIFICATION items remain. The chosen stack (Swift + Metal + ArgumentParser + file export) aligns with:
- Complete Feature Delivery (can implement all user stories independently)
- Code Quality (simple, minimal dependencies, standard libraries)
- Testing Discipline (manual validation + unit tests for core logic)
- Performance Goals (native Metal access, minimal overhead)
- Success Criteria (reproducible results, <5 min suite execution, accurate metrics)

**Phase 0 Complete** - Ready for Phase 1 (data model & contracts design).
