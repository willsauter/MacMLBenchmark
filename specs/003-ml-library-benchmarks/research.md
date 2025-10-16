# Research: ML Library Benchmarks

**Date**: 2025-10-16

## Key Decisions

### 1. Hybrid Architecture: Swift + Python

**Decision**: Swift for CoreML/MLX, Python subprocess for TensorFlow/PyTorch

**Rationale**:
- CoreML/MLX have Swift bindings (native performance)
- TensorFlow/PyTorch are Python-first (no mature Swift bindings)
- Reuses Feature 002's Process API pattern

**Alternatives**: Pure Swift impossible - would require rewriting TensorFlow

### 2. Model Deployment via SSH

**Decision**: Extend Feature 002's SSH infrastructure for model transfer

**Rationale**:
- Reuses proven SSHClient from Feature 002
- Models transferred like binaries (scp with progress)
- Cached on remote machines (checksum validation)

### 3. Progress Tracking

**Decision**: Multi-phase progress (download → load → prefill → decode)

**Rationale**:
- LLM inference has distinct phases with different performance
- Extends Feature 001's progress indicator pattern
- Real-time updates via stdout parsing from Python scripts

### 4. Model Selection

**Decision**: Small/Medium/Large variants per framework

**Rationale**:
- Small: Fast testing, <500MB (GPT-2 small, MobileNet)
- Medium: Balanced, 500MB-2GB (GPT-2 medium)
- Large: Stress test, 2-5GB (GPT-2 large)

Phase 0 complete - ready for data model design.
