# Feature Specification: ML Library Benchmarks

**Feature Branch**: `003-ml-library-benchmarks`
**Created**: 2025-10-16
**Status**: Draft
**Input**: User description: "I'm going to add support through TensorFlow or other large language model type tests where we're actually doing inferencing tests and concatenate those as well. So I like the metal-based GPU testing that we're doing, but I also want to work them through various real-world libraries as well."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Framework Library Integration (Priority: P1)

A developer wants to benchmark GPU performance using actual ML frameworks (CoreML, TensorFlow, PyTorch/MLX) with real model inference, and be able to select which models to use (small/medium/large variants) for testing.

**Why this priority**: This is the MVP - it adds real-world framework benchmarks to complement the existing Metal synthetic tests. Users can select specific models and see how actual ML libraries perform on their hardware.

**Independent Test**: Can be fully tested by selecting a framework benchmark (e.g., CoreML image classification with MobileNet-small), running it locally, and seeing real inference metrics.

**Acceptance Scenarios**:

1. **Given** the user runs a framework benchmark, **When** selecting the benchmark, **Then** they can choose which model size to use (small/medium/large) and the system loads that specific model variant for testing.

2. **Given** the user runs a CoreML or MLX benchmark, **When** the benchmark executes, **Then** it loads a real model, runs inference operations for the specified duration, and reports throughput, latency, and GPU utilization with progress indicators matching the Metal benchmarks.

3. **Given** a required framework or model is missing, **When** the user attempts to run that benchmark, **Then** the system detects the missing component, displays installation/download instructions, and optionally skips if running in --all mode.

4. **Given** the user runs framework benchmarks, **When** viewing results, **Then** the output clearly shows framework name, model name, model size, and framework overhead compared to equivalent Metal operations.

---

### User Story 2 - Model Deployment Across Machines (Priority: P2)

A developer wants to deploy ML models to remote machines and run framework benchmarks across multiple machines with the same models to ensure fair cross-hardware comparison.

**Why this priority**: After framework integration (P1), users need to deploy models to remote machines for consistent multi-machine testing. This ensures all machines use identical models for valid performance comparison.

**Independent Test**: Can be fully tested by selecting a model, deploying it to a remote machine via SSH, and running the benchmark remotely with progress indicators showing model transfer and inference progress.

**Acceptance Scenarios**:

1. **Given** the user selects a framework benchmark for multi-machine execution, **When** initiating the run, **Then** the system automatically deploys the required model weights to all selected remote machines before executing benchmarks.

2. **Given** model weights are being transferred to remote machines, **When** the transfer is in progress, **Then** the system displays progress indicators showing transfer percentage and estimated time remaining for each machine.

3. **Given** a model is already cached on a remote machine, **When** deploying for a subsequent run, **Then** the system detects the cached model and skips re-transfer, displaying "Using cached model" to save time.

4. **Given** model deployment fails on one machine (disk space, network error), **When** the error occurs, **Then** the system continues deploying to other machines, marks the failed machine, and provides remediation steps.

5. **Given** different remote machines have different framework versions, **When** deploying models, **Then** the system validates framework compatibility per machine and warns if version mismatches may affect results.

---

### User Story 3 - LLM Inference with Progress Tracking (Priority: P3)

A developer wants to run LLM inference benchmarks with real tokenization and text generation, seeing detailed progress for prompt processing (prefill) and token generation (decode) phases across multiple machines.

**Why this priority**: After model deployment works (P2), users need LLM-specific benchmarks with granular progress tracking since LLM inference has distinct phases (prefill vs decode) with different performance characteristics.

**Independent Test**: Can be fully tested by running an LLM benchmark, observing separate progress indicators for model loading, prompt processing, and token generation, with tokens-per-second metrics reported for each phase.

**Acceptance Scenarios**:

1. **Given** the user runs an LLM inference benchmark, **When** execution begins, **Then** the system displays progress for three phases: model loading (0-20%), prompt processing/prefill (20-40%), and token generation/decode (40-100%).

2. **Given** the LLM benchmark is running on multiple machines, **When** viewing progress, **Then** each machine shows its current phase (loading/prefill/decode) with per-machine progress bars updated in real-time.

3. **Given** the benchmark completes, **When** results are displayed, **Then** the system reports separate metrics for prefill speed (tokens/sec for prompt) and decode speed (tokens/sec for generation), as these have different performance profiles.

4. **Given** the user wants to test different model sizes, **When** selecting an LLM benchmark, **Then** they can choose from small (GPT-2 small, ~500MB), medium (GPT-2 medium, ~1.5GB), or large (GPT-2 large, ~3GB) variants.

5. **Given** model download is required, **When** downloading, **Then** the system shows download progress with percentage, speed (MB/s), and estimated time remaining, caching the model for future runs.

---

### Edge Cases

- **What happens when model download fails mid-transfer?** System should support resume if possible, or re-download with retry logic, displaying clear error if network unavailable.

- **What happens when remote machine lacks disk space for models?** System should check available disk space before transfer, warn if insufficient, and suggest which models to skip or smaller variants to use.

- **What happens when framework versions differ across machines?** System should detect version differences, warn about potential result inconsistencies, and optionally skip incompatible machines.

- **What happens during LLM inference if GPU memory is exhausted?** System should detect OOM errors, suggest smaller model variants or batch sizes, and fail gracefully without crashing.

- **What happens when Python environment is missing on remote machine?** System should detect Python availability and required packages, provide installation commands, and skip Python benchmarks if unavailable.

- **What happens with slow model downloads on remote machines?** Progress indicators should show per-machine download status, allow timeout configuration, and continue with machines that complete successfully.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support selecting specific model sizes (small/medium/large) for each framework benchmark to test scalability.

- **FR-002**: System MUST automatically deploy required model weights to remote machines before executing framework benchmarks.

- **FR-003**: System MUST display progress indicators during model transfer showing percentage complete and estimated time remaining per machine.

- **FR-004**: System MUST cache deployed models on remote machines and detect cached models to skip re-transfer on subsequent runs.

- **FR-005**: System MUST integrate framework benchmarks with the existing interactive menu, allowing model size selection alongside benchmark selection.

- **FR-006**: System MUST support real ML framework execution including CoreML (Swift native), MLX (Swift bindings), TensorFlow (Python via subprocess), and PyTorch (Python via subprocess).

- **FR-007**: System MUST provide LLM inference benchmarks measuring tokenization, prompt processing (prefill), and token generation (decode) with separate metrics for each phase.

- **FR-008**: System MUST display multi-phase progress indicators for LLM benchmarks showing model loading, prefill, and decode progress separately.

- **FR-009**: System MUST detect framework availability and versions on both local and remote machines, warning about incompatibilities.

- **FR-010**: System MUST handle model download failures gracefully with retry logic and resumption support where possible.

- **FR-011**: System MUST validate disk space availability on remote machines before model transfer and warn if insufficient.

- **FR-012**: System MUST export framework benchmark results in the same unified JSON format as Metal benchmarks, including framework name, model name, model size, and framework-specific metrics.

- **FR-013**: System MUST measure and report framework overhead separately from inference time to identify initialization and abstraction costs.

- **FR-014**: System MUST support framework comparison mode running the same logical operation through multiple frameworks with overhead analysis.

### Key Entities

- **ModelVariant**: Represents a specific model size option. Attributes include: model base name, size category (small/medium/large), weight file size, download URL, cached file path, framework compatibility.

- **ModelDeployment**: Tracks model deployment to a remote machine. Attributes include: model variant, target machine, deployment status (not deployed/transferring/cached), transfer progress percentage, cache timestamp.

- **FrameworkBenchmark**: Extends BenchmarkTask with framework-specific info. Attributes include: framework name, supported model variants, Python script path (if applicable), framework version requirements.

- **LLMProgress**: Tracks LLM-specific execution phases. Attributes include: current phase (loading/prefill/decode), phase progress percentage, tokens processed, tokens per second per phase.

- **FrameworkMetrics**: Extends PerformanceMetrics. Attributes include: framework overhead percentage, initialization time, model loading time, prefill tokens/sec, decode tokens/sec, framework-reported memory.

### Assumptions

- **Assumption 1**: Users understand framework benchmarks require additional setup (Python packages, model downloads) beyond base Metal benchmarks.

- **Assumption 2**: Model weights are distributed across size tiers: small (<500MB), medium (500MB-2GB), large (2-5GB) for graduated testing.

- **Assumption 3**: Remote machines have sufficient disk space (10GB+) for model caching across multiple runs and frameworks.

- **Assumption 4**: Model deployment uses SSH/SCP (Feature 002's infrastructure) for transferring weights to remote machines.

- **Assumption 5**: Progress indicators leverage existing real-time progress infrastructure from Feature 001, extended for multi-phase operations (download/load/prefill/decode).

- **Assumption 6**: Framework benchmarks integrate with Feature 002's multi-machine executor, enabling parallel framework benchmark execution across machines.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can select from at least 3 model size variants (small/medium/large) for each framework benchmark type.

- **SC-002**: Model deployment to remote machines displays progress with <5% accuracy on percentage complete and <10% accuracy on time remaining estimates.

- **SC-003**: Cached model detection on remote machines completes within 2 seconds, avoiding unnecessary re-transfers.

- **SC-004**: Model transfer progress updates at least once per second with visible percentage changes on transfers >100MB.

- **SC-005**: LLM benchmarks report separate prefill and decode metrics with tokens-per-second for each phase within 5% variance on repeated runs.

- **SC-006**: Multi-phase progress indicators (loading/prefill/decode) are clearly labeled and update in real-time during LLM execution.

- **SC-007**: Framework availability detection identifies installed frameworks within 3 seconds and provides actionable installation commands for missing ones.

- **SC-008**: Model download with progress completes within 5 minutes for models up to 2GB on typical broadband (with resume on failure).

- **SC-009**: Framework benchmark results appear in the same comparison view as Metal benchmarks, clearly labeled by framework and model size.

- **SC-010**: Cross-machine model deployment ensures all machines use identical model weights, validated by checksum comparison before execution.
