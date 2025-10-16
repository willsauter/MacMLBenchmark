# Tasks: Mac ML Benchmark Suite

**Input**: Design documents from `/specs/001-mac-ml-benchmark-suite/`
**Prerequisites**: plan.md (complete), spec.md (complete), research.md (complete), data-model.md (complete), contracts/ (complete)

**Tests**: Manual validation against acceptance scenarios (no automated test suite per spec assumptions)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- Project type: Single Swift CLI tool

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create Swift Package with Package.swift at repository root defining macmlbench executable target
- [x] T002 Initialize project structure creating src/, tests/, and results/ directories
- [x] T003 [P] Add Metal Performance Shaders framework dependency to Package.swift
- [x] T004 [P] Add ArgumentParser dependency (v1.2+) to Package.swift
- [x] T005 [P] Create .gitignore file excluding .build/, results/*.json, results/*.csv, and .swiftpm/
- [x] T006 Create README.md with project overview and link to quickstart.md

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 Create HardwareProfile struct with all attributes in src/models/HardwareProfile.swift conforming to Codable
- [x] T008 Create TaskType enum (inference/training/processing) in src/models/TaskType.swift conforming to String, Codable
- [x] T009 Create ParameterType enum (duration/size/count) in src/models/ParameterType.swift
- [x] T010 Create ParameterConstraint enum (range/options/conditional) in src/models/ParameterConstraint.swift
- [x] T011 Create TaskParameter struct with all attributes in src/models/TaskParameter.swift conforming to Codable
- [x] T012 Create BenchmarkTask struct with all attributes in src/models/BenchmarkTask.swift conforming to Codable
- [x] T013 Create BenchmarkConfiguration struct with id, selectedTasks, parameterOverrides in src/models/BenchmarkConfiguration.swift conforming to Codable
- [x] T014 Create PerformanceMetrics struct with throughput, latency, GPU utilization in src/models/PerformanceMetrics.swift conforming to Codable
- [x] T015 Create ResultStatus enum (success/failed/throttled/partiallyCompleted) in src/models/ResultStatus.swift conforming to String, Codable
- [x] T016 Create ThermalState enum (nominal/fair/serious/critical) in src/models/ThermalState.swift conforming to String, Codable
- [x] T017 Create BenchmarkResult struct with all attributes in src/models/BenchmarkResult.swift conforming to Codable
- [x] T018 Create BenchmarkRun class with configuration, startTime, currentTask, completedTasks, failedTasks, partialResults, isCancelled in src/models/BenchmarkRun.swift
- [x] T019 Implement hardware detection function using IOKit and sysctl in src/hardware/HardwareDetector.swift returning HardwareProfile
- [x] T020 Implement GPU capability detection using MTLDevice in src/hardware/MetalCapabilities.swift returning GPU core count and memory
- [x] T021 Implement thermal state monitoring using ProcessInfo.thermalState in src/hardware/ThermalMonitor.swift
- [x] T022 Create BenchmarkProtocol protocol defining execute, validate, and setup methods in src/benchmarks/BenchmarkProtocol.swift
- [x] T023 Create MetricsCollector class for GPU performance metrics using Metal completion handlers in src/metrics/MetricsCollector.swift
- [x] T024 Implement parameter validation logic checking ranges and constraints in src/cli/ParameterValidator.swift
- [x] T025 Create ResultFormatter class for human-readable output to stdout in src/output/ResultFormatter.swift
- [x] T026 [P] Create JSONExporter class using JSONEncoder with ISO8601 date strategy in src/output/JSONExporter.swift
- [x] T027 [P] Create CSVExporter class for flattened result rows in src/output/CSVExporter.swift

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Quick Benchmark Execution (Priority: P1) 🎯 MVP

**Goal**: Run single benchmark with defaults, display results immediately (FR-001, FR-010)

**Independent Test**: Run `macmlbench run matrix-multiply`, verify it executes for 10 seconds and displays throughput, latency, GPU utilization

### Implementation for User Story 1

- [x] T028 [P] [US1] Create MatrixMultiplyBenchmark class implementing BenchmarkProtocol in src/benchmarks/MatrixMultiplyBenchmark.swift
- [x] T029 [P] [US1] Implement matrix multiplication using MPSMatrixMultiplication in MatrixMultiplyBenchmark with configurable size and batch parameters
- [x] T030 [US1] Create BenchmarkRegistry class storing all available tasks with default parameters in src/benchmarks/BenchmarkRegistry.swift
- [x] T031 [US1] Register matrix-multiply task in BenchmarkRegistry with defaults (duration: 10, batch_size: 32, size: 4096)
- [x] T032 [US1] Implement Run command struct using ArgumentParser with tasks argument in src/cli/RunCommand.swift
- [x] T033 [US1] Implement argument parsing for task name in RunCommand.validate() method
- [x] T034 [US1] Create BenchmarkExecutor class handling single task execution with progress tracking in src/BenchmarkExecutor.swift
- [x] T035 [US1] Implement progress indicator using DispatchQueue timer displaying percentage and elapsed time in BenchmarkExecutor
- [x] T036 [US1] Implement result display logic calling ResultFormatter.format() after task completion in BenchmarkExecutor
- [x] T037 [US1] Create main.swift entry point with MacMLBench ParsableCommand structure and Run subcommand
- [x] T038 [US1] Wire hardware detection at startup displaying HardwareProfile before benchmark execution in main.swift
- [x] T039 [US1] Implement error handling for unsupported hardware displaying helpful message in HardwareDetector

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. User can run `macmlbench run matrix-multiply` and see results.

---

## Phase 4: User Story 2 - Configurable Benchmark Parameters (Priority: P2)

**Goal**: Customize duration, size, threads, batch_size via CLI flags (FR-004, FR-008)

**Independent Test**: Run `macmlbench run matrix-multiply --duration 30 --size 8192 --batch-size 64`, verify parameters are respected

### Implementation for User Story 2

- [x] T040 [P] [US2] Add duration option to RunCommand with default 10, range validation 1-3600 in src/cli/RunCommand.swift
- [x] T041 [P] [US2] Add batch-size option to RunCommand with task-specific default, range validation 1-1024 in src/cli/RunCommand.swift
- [x] T042 [P] [US2] Add threads option to RunCommand with system core count default, range validation 1-cores in src/cli/RunCommand.swift
- [x] T043 [P] [US2] Add size option to RunCommand with task-specific default, range validation 128-8192 in src/cli/RunCommand.swift
- [x] T044 [US2] Implement RunCommand.validate() checking all parameter ranges using ParameterValidator
- [x] T045 [US2] Implement helpful error message formatting for invalid parameters in ParameterValidator showing valid ranges and examples
- [x] T046 [US2] Modify BenchmarkExecutor to merge CLI parameter overrides with task default parameters before execution
- [x] T047 [US2] Update MatrixMultiplyBenchmark to accept custom size and batch_size parameters from configuration
- [x] T048 [US2] Add parameter values to result output showing configuration used in ResultFormatter
- [x] T049 [US2] Implement cross-parameter validation checking batch_size * element_size < available_memory in ParameterValidator

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. User can customize all parameters.

---

## Phase 5: User Story 3 - Multi-Task Benchmark Suite (Priority: P3)

**Goal**: Run multiple tasks with --all flag, export results, compare runs (FR-003, FR-011, FR-012, FR-014)

**Independent Test**: Run `macmlbench run --all --output results.json`, verify all 5 tasks execute and JSON file contains all results

### Implementation for User Story 3

- [x] T050 [P] [US3] Create ConvolutionBenchmark class implementing BenchmarkProtocol using MPSCNNConvolution in src/benchmarks/ConvolutionBenchmark.swift
- [x] T051 [P] [US3] Create AttentionBenchmark class with custom Metal compute kernel for scaled dot-product attention in src/benchmarks/AttentionBenchmark.swift
- [x] T052 [P] [US3] Create ActivationBenchmark class using MPSCNNNeuronGELU/ReLU/Softmax in src/benchmarks/ActivationBenchmark.swift
- [x] T053 [P] [US3] Create MixedOperationsBenchmark combining matmul, activation, and normalization operations in src/benchmarks/MixedOperationsBenchmark.swift
- [x] T054 [US3] Register all 5 benchmark tasks in BenchmarkRegistry with appropriate defaults and parameter constraints
- [x] T055 [US3] Add --all flag to RunCommand enabling selection of all available tasks in src/cli/RunCommand.swift
- [x] T056 [US3] Implement multi-task argument parsing supporting multiple task names in RunCommand
- [x] T057 [US3] Modify BenchmarkExecutor to execute tasks sequentially tracking completed and failed tasks
- [x] T058 [US3] Implement failure handling continuing execution if one task fails, collecting errors in BenchmarkRun.failedTasks
- [x] T059 [US3] Add summary report generation showing results for all tasks in ResultFormatter
- [x] T060 [US3] Add --output option to RunCommand accepting file path with .json or .csv extension
- [x] T061 [US3] Implement result export calling JSONExporter or CSVExporter based on file extension after all tasks complete
- [x] T062 [US3] Create List command struct displaying all available tasks with descriptions in src/cli/ListCommand.swift
- [x] T063 [US3] Add --verbose flag to List command showing full parameter constraints in ListCommand
- [x] T064 [US3] Create Compare command struct accepting multiple file paths in src/cli/CompareCommand.swift
- [x] T065 [US3] Implement JSON file loading and parsing in Compare command validating format
- [x] T066 [US3] Implement task matching by name across loaded result files in CompareCommand
- [x] T067 [US3] Implement delta calculation for throughput, latency, GPU utilization showing percentage changes in CompareCommand
- [x] T068 [US3] Format comparison output highlighting significant differences (>10% change) in CompareCommand
- [x] T069 [US3] Create Hardware command struct calling HardwareDetector and displaying profile in src/cli/HardwareCommand.swift
- [x] T070 [US3] Add --json flag to Hardware command outputting structured JSON in HardwareCommand
- [x] T071 [US3] Create Version command struct displaying version, build date, Swift version in src/cli/VersionCommand.swift
- [x] T072 [US3] Wire all commands (Run, List, Compare, Hardware, Version) as subcommands in main.swift MacMLBench ParsableCommand

**Checkpoint**: All user stories should now be independently functional. Full benchmark suite works with export and comparison.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T073 [P] Implement SIGINT handler for graceful cancellation setting BenchmarkRun.isCancelled and cleaning up GPU resources in BenchmarkExecutor
- [x] T074 [P] Add resource constraint error handling catching Metal allocation failures and suggesting parameter reductions in BenchmarkExecutor
- [x] T075 [P] Implement thermal throttling warning prompting user if ThermalState is serious or critical before execution in BenchmarkExecutor
- [x] T076 [P] Add result variance checking warning if <10% reproducibility not achieved on repeated runs in ResultFormatter
- [x] T077 Create unit tests for ParameterValidator checking range validation logic in tests/unit/ParameterValidatorTests.swift
- [x] T078 Create unit tests for MetricsCollector verifying throughput and latency calculations in tests/unit/MetricsCollectorTests.swift
- [x] T079 Create unit tests for JSONExporter/CSVExporter validating output format correctness in tests/unit/ExporterTests.swift
- [x] T080 Document manual validation steps for each acceptance scenario in tests/integration/ManualTestPlan.md
- [x] T081 Update quickstart.md with build instructions and usage examples covering all three user stories
- [x] T082 Add inline code comments explaining Metal API usage in benchmark implementations
- [x] T083 Verify all error messages include helpful guidance and examples per FR-008 requirement

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Extends US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Uses infrastructure from US1/US2 but independently testable

### Within Each User Story

- Foundational models before execution logic
- CLI parsing before executor implementation
- Core benchmark before output formatting
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational model creation tasks (T007-T018) can run in parallel
- All Foundational infrastructure tasks (T019-T027) can run in parallel after models
- Within US1: T028-T029 (benchmark implementation) can run in parallel
- Within US2: T040-T043 (CLI options) can run in parallel
- Within US3: T050-T053 (benchmark implementations) can run in parallel
- Polish phase: T073-T079 (error handling and tests) can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch benchmark and registry in parallel:
Task: "Create MatrixMultiplyBenchmark class implementing BenchmarkProtocol in src/benchmarks/MatrixMultiplyBenchmark.swift"
Task: "Implement matrix multiplication using MPSMatrixMultiplication in MatrixMultiplyBenchmark with configurable size and batch parameters"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (T028-T039)
4. **STOP and VALIDATE**: Run `macmlbench run matrix-multiply`, verify output matches acceptance scenarios
5. MVP is deployable and usable at this point

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP with single benchmark!)
3. Add User Story 2 → Test independently → Deploy/Demo (MVP + parameter customization!)
4. Add User Story 3 → Test independently → Deploy/Demo (Full suite with 5 tasks + export + comparison!)
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (T028-T039)
   - Developer B: User Story 2 (T040-T049) - can start immediately after US1 structure exists
   - Developer C: User Story 3 benchmark tasks (T050-T053)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify manual validation steps in tests/integration/ManualTestPlan.md against spec.md acceptance scenarios
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- No automated test suite required per spec Assumption 3 - manual validation sufficient

---

## Task Count Summary

- **Phase 1 (Setup)**: 6 tasks
- **Phase 2 (Foundational)**: 21 tasks
- **Phase 3 (User Story 1 - P1 MVP)**: 12 tasks
- **Phase 4 (User Story 2 - P2)**: 10 tasks
- **Phase 5 (User Story 3 - P3)**: 23 tasks
- **Phase 6 (Polish)**: 11 tasks

**Total**: 83 tasks

**Parallel Opportunities**: 31 tasks marked [P] can run in parallel within their phases
