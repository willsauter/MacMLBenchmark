# Tasks: ML Library Benchmarks

**Input**: Design documents from `/specs/003-ml-library-benchmarks/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/
**Extends**: Features 001 (Metal benchmarks) + 002 (menu/remote)

**Tests**: Manual validation + framework availability tests

**Organization**: Tasks grouped by user story for independent implementation.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

**Purpose**: Prepare for framework integration

- [x] T001 Create models/ directory for cached model weights
- [x] T002 Create src/benchmarks/framework/ directory
- [x] T003 Create src/python/ directory for Python benchmark scripts
- [x] T004 Create src/python/requirements.txt with tensorflow-macos, torch, transformers
- [x] T005 Update .gitignore to exclude models/*.bin and models/*.onnx

---

## Phase 2: Foundational

**Purpose**: Core models and infrastructure for framework benchmarks

- [x] T006 Create ModelSize enum (small/medium/large) in src/models/ModelSize.swift
- [x] T007 Create LLMPhase enum (loading/prefill/decode) in src/models/LLMPhase.swift
- [x] T008 Create ModelVariant struct with modelName, sizeCategory, fileSizeMB, downloadURL, cachedPath in src/models/ModelVariant.swift
- [x] T009 Create ModelDeployment struct tracking model transfer to remotes in src/models/ModelDeployment.swift
- [x] T010 Create FrameworkMetrics struct extending PerformanceMetrics with framework-specific fields in src/models/FrameworkMetrics.swift
- [x] T011 Create LLMProgress struct tracking loading/prefill/decode phases in src/models/LLMProgress.swift
- [x] T012 Create ModelCache class for managing cached model weights in src/benchmarks/framework/ModelCache.swift
- [x] T013 Create PythonBridge class for executing Python scripts via Process API in src/benchmarks/framework/PythonBridge.swift

**Checkpoint**: Foundation ready

---

## Phase 3: User Story 1 - Framework Integration (P1) 🎯 MVP

**Goal**: Run CoreML/MLX benchmarks with model selection locally

**Independent Test**: Select CoreML benchmark with small model, run locally, see results

- [x] T014 [P] [US1] Create CoreMLBenchmark class using CoreML framework for image classification in src/benchmarks/framework/CoreMLBenchmark.swift
- [x] T015 [P] [US1] Create MLXBenchmark class using MLX Swift bindings for matrix ops in src/benchmarks/framework/MLXBenchmark.swift
- [x] T016 [US1] Create PythonFrameworkBenchmark wrapper executing Python scripts and parsing JSON output in src/benchmarks/framework/PythonFrameworkBenchmark.swift
- [x] T017 [US1] Write tensorflow_benchmark.py script outputting JSON metrics in src/python/tensorflow_benchmark.py
- [x] T018 [US1] Write pytorch_benchmark.py script using torch MPS backend in src/python/pytorch_benchmark.py
- [x] T019 [US1] Register framework benchmarks in BenchmarkRegistry with model size options
- [x] T020 [US1] Extend MenuCommand to show model size selection for framework benchmarks
- [x] T021 [US1] Test CoreML benchmark with small model locally

**Checkpoint**: Framework benchmarks work locally with model selection

---

## Phase 4: User Story 2 - Model Deployment (P2)

**Goal**: Deploy models to remote machines with progress indicators

**Independent Test**: Deploy GPT-2 small to remote, see transfer progress, verify cached

- [x] T022 [US2] Create ModelDeployer class using SSHClient for model transfer in src/remote/ModelDeployer.swift
- [x] T023 [US2] Implement model transfer with progress tracking using scp in ModelDeployer
- [x] T024 [US2] Implement model cache detection on remote via SSH checksum in ModelDeployer
- [x] T025 [US2] Add disk space validation before model transfer in ModelDeployer
- [x] T026 [US2] Extend MultiMachineExecutor to deploy models before framework benchmarks
- [x] T027 [US2] Add model deployment progress to menu UI showing per-machine transfer status
- [x] T028 [US2] Test model deployment to M3 Ultra with progress display

**Checkpoint**: Models deploy to remotes with progress

---

## Phase 5: User Story 3 - LLM Progress (P3)

**Goal**: LLM benchmarks with multi-phase progress (load/prefill/decode)

**Independent Test**: Run LLM benchmark, see loading → prefill → decode progress

- [x] T029 [US3] Write llm_inference.py with GPT-2 variants and phase progress output in src/python/llm_inference.py
- [x] T030 [US3] Implement LLM progress parsing from Python JSON output in PythonFrameworkBenchmark
- [x] T031 [US3] Create LLMProgressDisplay showing phase-specific progress bars in src/menu/LLMProgressDisplay.swift
- [x] T032 [US3] Add prefill vs decode token/sec reporting in FrameworkMetrics
- [x] T033 [US3] Test LLM benchmark with progress phases on local + remote

**Checkpoint**: LLM benchmarks work with detailed progress

---

## Phase 6: Polish

- [x] T034 [P] Add framework availability detection in Python and Swift
- [x] T035 [P] Implement model download with resume on failure
- [x] T036 Create framework comparison mode comparing Metal vs libraries
- [x] T037 Update quickstart with framework setup instructions
- [x] T038 Test cross-machine model consistency with checksum validation

---

## Task Count

- **Total**: 38 tasks
- **P1 (MVP)**: 8 tasks (CoreML/MLX local)
- **P2**: 7 tasks (Model deployment)
- **P3**: 5 tasks (LLM progress)
- **Polish**: 5 tasks

Ready for `/speckit.implement`!
