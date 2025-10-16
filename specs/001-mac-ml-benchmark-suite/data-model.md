# Data Model: Mac ML Benchmark Suite

**Date**: 2025-10-16
**Feature**: Mac ML Benchmark Suite
**Phase**: Phase 1 - Design & Contracts

## Overview

This document defines the data entities, relationships, and validation rules for the Mac ML Benchmark Suite. All entities are derived from the Key Entities section in spec.md and the technical decisions in research.md.

---

## Entity Diagram

```
┌─────────────────┐
│ HardwareProfile │
└────────┬────────┘
         │
         │ detected at startup
         │
         ▼
┌──────────────────────┐         ┌─────────────────┐
│ BenchmarkConfiguration│◄───────│  TaskParameter  │
└──────────┬────────────┘ configures└────────┬────────┘
           │                              │
           │ executes                     │ belongs to
           │                              │
           ▼                              ▼
   ┌───────────────┐                ┌──────────────┐
   │ BenchmarkRun  │───────────────►│ BenchmarkTask│
   └───────┬───────┘   runs          └──────────────┘
           │
           │ produces
           │
           ▼
   ┌───────────────┐
   │ BenchmarkResult│
   └───────────────┘
```

---

## Core Entities

### 1. HardwareProfile

**Purpose**: Represents the Mac hardware being benchmarked (from FR-007)

**Attributes**:
- `modelName`: String - Mac model identifier (e.g., "MacBook Pro (16-inch, 2023)")
- `chipIdentifier`: String - Apple Silicon chip variant (e.g., "M3 Max")
- `gpuCoreCount`: Int - Number of GPU cores
- `totalMemoryGB`: Int - Total system memory in gigabytes
- `gpuMemoryGB`: Int - GPU memory allocation limit in gigabytes
- `macOSVersion`: String - Operating system version (e.g., "14.1.2")
- `detectionTimestamp`: Date - When hardware was detected

**Validation Rules**:
- `chipIdentifier` must match pattern "M[1-3] (|Pro|Max|Ultra)"
- `gpuCoreCount` must be > 0
- `totalMemoryGB` must be >= 8 (minimum for MPS operations)
- `macOSVersion` must be >= "12.0" (minimum for stable MPS APIs)

**Relationships**:
- One HardwareProfile per benchmark run (captured at startup)
- Referenced by BenchmarkResult for hardware context

**State/Lifecycle**:
- Detected once at application startup via IOKit + Metal APIs
- Immutable for duration of execution
- Included in all exported results

**Example**:
```swift
HardwareProfile(
  modelName: "Mac Studio (2023)",
  chipIdentifier: "M2 Ultra",
  gpuCoreCount: 76,
  totalMemoryGB: 128,
  gpuMemoryGB: 64,
  macOSVersion: "14.2",
  detectionTimestamp: Date()
)
```

---

### 2. BenchmarkTask

**Purpose**: Represents a specific ML/AI workload to be benchmarked (from FR-002)

**Attributes**:
- `name`: String - Task identifier (e.g., "matrix-multiply")
- `displayName`: String - Human-readable name (e.g., "Matrix Multiplication")
- `taskType`: TaskType - Category enum (inference/training/processing)
- `description`: String - What this benchmark measures
- `defaultParameters`: [String: Any] - Default configuration values
- `parameterConstraints`: [String: ParameterConstraint] - Valid ranges/options for each parameter
- `resourceRequirements`: ResourceRequirements - Min memory, GPU cores needed

**TaskType Enum**:
```swift
enum TaskType: String, Codable {
  case inference       // LLM inference, image classification
  case training        // Training simulation, gradient computation
  case processing      // Matrix ops, activations, memory bandwidth
}
```

**Validation Rules**:
- `name` must be kebab-case, lowercase, unique
- `defaultParameters` must satisfy all `parameterConstraints`
- `resourceRequirements.minMemoryGB` <= HardwareProfile.totalMemoryGB (checked at runtime)

**Relationships**:
- Has many TaskParameters (configurable settings)
- Referenced by BenchmarkConfiguration (which tasks to run)
- Executed by BenchmarkRun

**Built-in Tasks** (from research.md Decision 3):
1. `matrix-multiply`: Large matrix multiplication (transformer layer simulation)
2. `convolution-2d`: 2D convolution operations (CNN simulation)
3. `attention-mechanism`: Scaled dot-product attention (LLM representative)
4. `activation-functions`: GELU/ReLU/Softmax at scale (memory bandwidth test)
5. `mixed-operations`: Combined matmul + activations + normalization (training sim)

**Example**:
```swift
BenchmarkTask(
  name: "matrix-multiply",
  displayName: "Matrix Multiplication",
  taskType: .inference,
  description: "Measures GPU throughput for large matrix operations",
  defaultParameters: ["size": 4096, "batch_size": 32],
  parameterConstraints: [
    "size": .range(min: 128, max: 8192),
    "batch_size": .range(min: 1, max: 1024)
  ],
  resourceRequirements: ResourceRequirements(minMemoryGB: 2, minGPUCores: 8)
)
```

---

### 3. TaskParameter

**Purpose**: Represents a configurable setting for a benchmark task (from FR-004)

**Attributes**:
- `name`: String - Parameter identifier (e.g., "duration", "batch_size")
- `displayName`: String - Human-readable name (e.g., "Batch Size")
- `parameterType`: ParameterType - Type enum (duration/size/count)
- `defaultValue`: Any - Default value if not specified
- `constraint`: ParameterConstraint - Valid range or options
- `unit`: String - Units for display (e.g., "seconds", "MB", "count")
- `description`: String - What this parameter controls

**ParameterType Enum**:
```swift
enum ParameterType {
  case duration    // Time in seconds
  case size        // Dimension, resolution, length
  case count       // Thread count, batch size, iterations
}
```

**ParameterConstraint Types**:
```swift
enum ParameterConstraint {
  case range(min: Int, max: Int)
  case options([Any])
  case conditional(constraint: (Any) -> Bool, message: String)
}
```

**Common Parameters** (all tasks):
- `duration`: Int (1-3600 seconds, default 10)
- `threads`: Int (1-system_cores, default system_cores)
- `batch_size`: Int (1-1024, default task-specific)

**Task-Specific Parameters**:
- Matrix: `size` (matrix dimension, 128-8192)
- Convolution: `image_size` (256-4096), `kernel_size` (3-11)
- Attention: `sequence_length` (128-8192), `head_count` (8-64)

**Validation Rules**:
- All parameters must satisfy their constraints before execution (FR-008)
- Cross-parameter validation (e.g., batch_size * element_size < memory) at runtime

**Example**:
```swift
TaskParameter(
  name: "batch_size",
  displayName: "Batch Size",
  parameterType: .count,
  defaultValue: 32,
  constraint: .range(min: 1, max: 1024),
  unit: "batches",
  description: "Number of samples processed in parallel"
)
```

---

### 4. BenchmarkConfiguration

**Purpose**: Represents the settings for a specific benchmark run (from spec Key Entities)

**Attributes**:
- `id`: UUID - Unique run identifier
- `selectedTasks`: [String] - List of task names to execute (or "all")
- `parameterOverrides`: [String: [String: Any]] - Custom parameters per task
- `hardware`: HardwareProfile - Snapshot of hardware at config time
- `createdAt`: Date - When configuration was created

**Validation Rules**:
- `selectedTasks` must reference valid BenchmarkTask names
- All `parameterOverrides` must satisfy corresponding TaskParameter constraints
- Validation occurs before any GPU allocation (FR-008)

**Relationships**:
- References HardwareProfile (current hardware)
- References BenchmarkTasks (which to run)
- Used by BenchmarkRun to execute benchmarks

**State/Lifecycle**:
- Created from CLI arguments
- Validated before execution
- Immutable after validation
- Stored in BenchmarkResult for reproducibility

**Example**:
```swift
BenchmarkConfiguration(
  id: UUID(),
  selectedTasks: ["matrix-multiply", "convolution-2d"],
  parameterOverrides: [
    "matrix-multiply": ["duration": 30, "size": 8192],
    "convolution-2d": ["duration": 30, "image_size": 2048]
  ],
  hardware: currentHardwareProfile,
  createdAt: Date()
)
```

---

### 5. BenchmarkRun

**Purpose**: Represents an active benchmark execution (runtime state)

**Attributes**:
- `configuration`: BenchmarkConfiguration - What is being executed
- `startTime`: Date - When execution began
- `currentTask`: String? - Name of currently executing task (nil if complete)
- `completedTasks`: [String] - Names of tasks that have finished
- `failedTasks`: [String: String] - Task name -> error message mapping
- `partialResults`: [BenchmarkResult] - Results collected so far
- `isCancelled`: Bool - Whether user requested cancellation (Ctrl+C)

**Validation Rules**:
- Cannot start if configuration validation failed
- Must handle interruption gracefully (edge case requirement)

**Relationships**:
- Uses BenchmarkConfiguration to determine what to execute
- Produces multiple BenchmarkResults (one per task)
- Tracks execution state for progress reporting (FR-009)

**State/Lifecycle**:
1. **Initialized**: Configuration validated, GPU resources allocated
2. **Running**: Executing tasks sequentially or in parallel
3. **Completed**: All tasks finished (success or failure)
4. **Cancelled**: User interrupted execution (SIGINT)

**Lifecycle Transitions**:
```
Initialized ──[start]──> Running ──[all tasks done]──> Completed
                │                       │
                └───[SIGINT]────────────┴────> Cancelled
```

**Example**:
```swift
BenchmarkRun(
  configuration: config,
  startTime: Date(),
  currentTask: "matrix-multiply",
  completedTasks: [],
  failedTasks: [:],
  partialResults: [],
  isCancelled: false
)
```

---

### 6. BenchmarkResult

**Purpose**: Represents the outcome of a benchmark execution (from FR-010, FR-011)

**Attributes**:
- `id`: UUID - Unique result identifier
- `configuration`: BenchmarkConfiguration - Settings used for this run
- `taskName`: String - Which task was executed
- `startTimestamp`: Date - When task execution began
- `endTimestamp`: Date - When task execution completed
- `duration`: TimeInterval - Total elapsed time (seconds)
- `metrics`: PerformanceMetrics - Collected performance data
- `status`: ResultStatus - Success or failure
- `errorMessage`: String? - Error details if status == .failed
- `thermalState`: ThermalState - System thermal state during execution

**PerformanceMetrics Struct** (from FR-006):
```swift
struct PerformanceMetrics: Codable {
  let throughputOpsPerSec: Double  // Operations completed per second
  let latencyMs: Double             // Milliseconds per operation
  let gpuUtilizationPercent: Double // GPU busy percentage (0-100)
  let peakMemoryUsageMB: Int        // Peak GPU memory used (MB)
  let averageMemoryUsageMB: Int     // Average GPU memory during run (MB)
  let iterationsCompleted: Int      // Total operations completed
}
```

**ResultStatus Enum**:
```swift
enum ResultStatus: String, Codable {
  case success             // Completed without errors
  case failed              // Execution failed
  case throttled           // Completed but thermal throttling detected
  case partiallyCompleted  // Interrupted but saved partial results
}
```

**ThermalState Enum** (from edge case requirements):
```swift
enum ThermalState: String, Codable {
  case nominal    // Normal operating temperature
  case fair       // Slightly elevated, no throttling
  case serious    // Elevated, possible throttling
  case critical   // Throttling active
}
```

**Validation Rules**:
- `metrics` values must be non-negative
- `duration` must match (endTimestamp - startTimestamp) within 1ms tolerance
- `status` must be `.throttled` if `thermalState` == `.serious` or `.critical`

**Relationships**:
- References BenchmarkConfiguration (what was run)
- Referenced by exported JSON/CSV files
- Compared against other BenchmarkResults (FR-014)

**Export Formats**:
- **JSON**: Full nested structure with all fields (FR-011)
- **CSV**: Flattened row format for spreadsheet import
- **Human-Readable**: Formatted text output to stdout (FR-010)

**Example**:
```swift
BenchmarkResult(
  id: UUID(),
  configuration: config,
  taskName: "matrix-multiply",
  startTimestamp: Date(),
  endTimestamp: Date().addingTimeInterval(10),
  duration: 10.0,
  metrics: PerformanceMetrics(
    throughputOpsPerSec: 12500.0,
    latencyMs: 0.08,
    gpuUtilizationPercent: 95.0,
    peakMemoryUsageMB: 2048,
    averageMemoryUsageMB: 1856,
    iterationsCompleted: 125000
  ),
  status: .success,
  errorMessage: nil,
  thermalState: .nominal
)
```

---

## Supporting Types

### ResourceRequirements

**Purpose**: Specifies minimum hardware needed for a benchmark task

**Attributes**:
- `minMemoryGB`: Int - Minimum system memory required
- `minGPUCores`: Int - Minimum GPU cores required
- `minMacOSVersion`: String - Minimum macOS version

**Validation**:
- Checked against HardwareProfile before task execution
- If requirements not met, task skipped with clear error message

---

## Data Flow

### 1. Startup Flow
```
1. Detect Hardware → HardwareProfile
2. Load BenchmarkTasks → [BenchmarkTask] registry
3. Parse CLI Arguments → BenchmarkConfiguration
4. Validate Configuration against HardwareProfile
5. Create BenchmarkRun
```

### 2. Execution Flow
```
For each task in configuration.selectedTasks:
  1. Check ResourceRequirements against HardwareProfile
  2. Merge task.defaultParameters with configuration.parameterOverrides
  3. Allocate GPU resources (Metal buffers, command queue)
  4. Execute benchmark loop for specified duration
  5. Collect metrics via Metal completion callbacks
  6. Create BenchmarkResult
  7. Append to BenchmarkRun.partialResults
  8. Display result to stdout
```

### 3. Export Flow
```
1. Collect all BenchmarkResults from BenchmarkRun
2. Encode to JSON using Swift Codable
3. Write to file at specified path
4. (Optional) Convert to CSV format via flattening
```

---

## Validation Summary

### Pre-Execution Validation (FR-008):
- ✅ Parameter types match expectations
- ✅ Parameter values within constraints
- ✅ Cross-parameter conflicts resolved
- ✅ Hardware requirements met
- ✅ Task names valid

### Runtime Validation:
- ✅ Memory allocation successful (catch Metal errors)
- ✅ Thermal state monitored (flag throttling)
- ✅ Interruption handling (SIGINT → cleanup)

### Post-Execution Validation:
- ✅ Metrics within expected ranges (non-negative, realistic values)
- ✅ Result completeness (all fields populated)
- ✅ Export format correctness (valid JSON/CSV)

---

## Persistence Strategy

**No Database Required** (from research.md Decision 6):
- All data in-memory during execution
- Results persisted only on explicit export (--output flag)
- File format: JSON (primary), CSV (optional)
- Location: `./results/` directory (created at runtime)
- File naming: `benchmark_<timestamp>_<task>.json`

**Result Comparison** (FR-014):
- Load multiple JSON files
- Parse into [BenchmarkResult]
- Calculate deltas between matching tasks
- Display percentage changes in metrics

---

## Implementation Notes

### Swift Codable Conformance
All entities must conform to `Codable` protocol for JSON export:
```swift
struct BenchmarkResult: Codable {
  // ... all fields must be Codable types
}
```

### Enum Raw Values
All enums use `String` raw values for human-readable JSON:
```swift
enum TaskType: String, Codable {
  case inference = "inference"
  case training = "training"
  case processing = "processing"
}
```

### Date Encoding
Use ISO8601 format for all dates in exports:
```swift
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
```

---

## Phase 1 Data Model Complete

All entities defined with:
- ✅ Attributes from spec Key Entities
- ✅ Validation rules from Functional Requirements
- ✅ Relationships and lifecycle states
- ✅ Export formats (JSON/CSV)
- ✅ Swift type mappings for implementation

Ready for contracts/ specification (CLI interface design).
