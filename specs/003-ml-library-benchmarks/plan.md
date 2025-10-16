# Implementation Plan: ML Library Benchmarks

**Branch**: `003-ml-library-benchmarks` | **Date**: 2025-10-16 | **Spec**: [spec.md](./spec.md)

## Summary

Extend the Mac ML Benchmark Suite with real-world ML framework benchmarks using TensorFlow, CoreML, PyTorch/MLX, and actual model inference. This complements the existing Metal GPU synthetic benchmarks with production ML library performance testing, including LLM inference with tokenization and text generation.

## Technical Context

**Language/Version**: Swift 5.9+ (primary), Python 3.10+ (for TensorFlow/PyTorch via subprocess)
**Primary Dependencies**:
- **Existing**: ArgumentParser, Metal, Foundation
- **Swift-native**: CoreML (built-in), MLX Swift bindings
- **Python (via subprocess)**: tensorflow-macos, torch with MPS, transformers (HuggingFace)
**Storage**: File system (model cache in models/ dir, results extend existing JSON export)
**Testing**: Manual validation, framework availability tests
**Target Platform**: macOS 12.0+ on Apple Silicon
**Project Type**: Hybrid - Swift CLI + Python script execution for framework diversity
**Performance Goals**: Framework overhead <100% vs Metal, LLM >10 tokens/sec, framework init <5s
**Constraints**: Requires Python frameworks installed, model downloads (100MB-1GB), 8GB+ RAM for LLM models
**Scale/Scope**: 3-5 frameworks (CoreML, MLX, TensorFlow, PyTorch), 2-3 model sizes, unified output format

## Architecture Decision

**Hybrid Approach**: Swift main app + Python scripts for TensorFlow/PyTorch

### Answer to "Are we still doing this all in Swift?"

**Partially**:
- **Swift**: CoreML benchmarks (native), MLX benchmarks (Swift bindings), orchestration, UI
- **Python**: TensorFlow and PyTorch benchmarks (no mature Swift bindings exist)
- **Integration**: Swift calls Python via Process API (same pattern as Feature 002's SSH)

### Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│   Swift Main App (macmlbench)                   │
│   ┌─────────────────────────────────────────┐   │
│   │ BenchmarkRegistry                       │   │
│   │  ├── Metal benchmarks (Feature 001)     │   │
│   │  ├── CoreML benchmarks (Swift native)   │   │
│   │  ├── MLX benchmarks (Swift bindings)    │   │
│   │  └── Python bridge benchmarks           │   │
│   └─────────────────────────────────────────┘   │
│                     │                            │
│                     ▼                            │
│   ┌─────────────────────────────────────────┐   │
│   │ PythonFrameworkBenchmark                │   │
│   │  - Executes via Process API             │   │
│   │  - Captures JSON output                 │   │
│   └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
                      │
                      ▼ (subprocess)
┌─────────────────────────────────────────────────┐
│   Python Scripts (src/python/)                  │
│   ├── tensorflow_benchmark.py                   │
│   ├── pytorch_benchmark.py                      │
│   └── llm_inference.py                          │
│       - Load models (transformers library)      │
│       - Run inference                           │
│       - Output JSON results to stdout           │
└─────────────────────────────────────────────────┘
```

**Why This Architecture**:
1. **Reuses Feature 002 Pattern**: Process API execution (proven with SSH)
2. **Minimal Swift Changes**: Extends existing BenchmarkProtocol
3. **Framework Flexibility**: Easy to add new Python-based frameworks
4. **Native Where Possible**: CoreML/MLX stay in Swift for performance

## Constitution Check

- [x] **Complete Feature Delivery**: All user stories fully implemented
- [x] **Incremental Implementation**: P1 (CoreML native) → P2 (LLM) → P3 (comparison)
- [x] **Testing Discipline**: Manual validation + framework tests
- [x] **Code Quality**: Reuses patterns (Process API), extends existing registry
- [x] **Documentation**: All docs maintained

**Complexity Justification**: Python dependency required for TensorFlow/PyTorch (no Swift alternatives). Process API pattern reused from Feature 002.

## Project Structure

```
src/
├── benchmarks/framework/   # NEW
│   ├── CoreMLBenchmark.swift
│   ├── MLXBenchmark.swift
│   └── PythonFrameworkBenchmark.swift
├── python/                 # NEW - Python scripts
│   ├── tensorflow_benchmark.py
│   ├── pytorch_benchmark.py
│   ├── llm_inference.py
│   └── requirements.txt
└── models/                 # NEW - Framework-specific
    ├── FrameworkMetrics.swift
    └── ModelDescriptor.swift

models/                     # NEW - Model cache directory
└── [cached model weights]
```

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Python dependency | TensorFlow/PyTorch have no Swift bindings | Pure Swift impossible - frameworks are Python-native |
| Process subprocess | Call Python from Swift | Rewrite TensorFlow in Swift - impractical |

Justified: Minimal complexity to access industry-standard frameworks.
