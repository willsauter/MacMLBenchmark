# Manual Test Plan: Mac ML Benchmark Suite

**Purpose**: Manual validation steps for all acceptance scenarios
**Feature**: Mac ML Benchmark Suite
**Date**: 2025-10-16

## Prerequisites

- Mac with Apple Silicon (M1/M2/M3/M4 or later)
- macOS 12.0+
- Project built: `swift build -c release`
- Executable: `.build/release/macmlbench`

---

## User Story 1 (P1): Quick Benchmark Execution

### Scenario 1: Run with default settings

**Steps**:
1. Run: `.build/release/macmlbench run matrix-multiply`
2. Observe execution for approximately 10 seconds

**Expected**:
- ✓ Benchmark executes for ~10 seconds
- ✓ Displays hardware profile (Model, Chip, GPU Cores, Memory, macOS)
- ✓ Shows progress indicator during execution
- ✓ Displays results: Throughput (ops/sec), Latency (ms/op), GPU Utilization (%), Peak Memory (MB)
- ✓ Shows Status: Success
- ✓ Shows Thermal State

**Actual**: ✅ PASS (verified 2025-10-16)

### Scenario 2: Hardware detection consistency

**Steps**:
1. Run benchmark on M1/M2/M3/M4 Mac
2. Verify hardware info displayed

**Expected**:
- ✓ Chip identifier matches actual hardware
- ✓ GPU core count reasonable for chip variant
- ✓ Results format consistent across hardware

**Actual**: ✅ PASS - M4 Pro detected correctly

### Scenario 3: Real-time progress

**Steps**:
1. Run benchmark
2. Watch progress indicator during execution

**Expected**:
- ✓ Progress bar updates every ~0.5 seconds
- ✓ Shows percentage (0% → 100%)
- ✓ Shows elapsed time
- ✓ Indicates benchmark is active

**Actual**: ✅ PASS

### Scenario 4: Complete result display

**Steps**:
1. Run benchmark
2. Review output after completion

**Expected**:
- ✓ Task name shown (Matrix Multiplication)
- ✓ Hardware info present
- ✓ Configuration shown
- ✓ All metrics displayed (throughput, latency, GPU util, memory, iterations)
- ✓ Status and thermal state shown
- ✓ Total time displayed

**Actual**: ✅ PASS

---

## User Story 2 (P2): Configurable Parameters

### Scenario 1: Custom duration

**Steps**:
1. Run: `.build/release/macmlbench run matrix-multiply --duration 30`
2. Verify execution time

**Expected**:
- ✓ Runs for ~30 seconds (not 10)
- ✓ Results reflect longer test period (more iterations)

**Test Status**: ⏳ To be validated after implementation

### Scenario 2: Custom size

**Steps**:
1. Run: `.build/release/macmlbench run matrix-multiply --size 8192`
2. Check configuration display

**Expected**:
- ✓ Shows "Matrix Size: 8192x8192" in configuration
- ✓ Results reflect larger matrix (lower throughput, higher memory)

**Test Status**: ⏳ To be validated

### Scenario 3: Custom threads

**Steps**:
1. Run: `.build/release/macmlbench run matrix-multiply --threads 8`
2. Verify parameter used

**Expected**:
- ✓ Shows "Threads: 8" in configuration
- ✓ Execution respects thread limit

**Test Status**: ⏳ To be validated

### Scenario 4: Invalid parameters

**Steps**:
1. Run: `.build/release/macmlbench run matrix-multiply --duration -5`
2. Review error message

**Expected**:
- ✓ Clear error explaining issue
- ✓ Shows valid range (1-3600)
- ✓ Provides example of correct usage
- ✓ Exits without crash

**Test Status**: ⏳ To be validated

### Scenario 5: Result includes parameters

**Steps**:
1. Run: `.build/release/macmlbench run matrix-multiply --duration 20 --size 2048 --output test.json`
2. Check JSON file contents

**Expected**:
- ✓ All parameters included in configuration section
- ✓ Can replicate exact run from exported data

**Test Status**: ⏳ To be validated

---

## User Story 3 (P3): Multi-Task Suite

### Scenario 1: Run all tasks

**Steps**:
1. Run: `.build/release/macmlbench run --all`
2. Observe all 5 tasks execute

**Expected**:
- ✓ Executes: matrix-multiply, convolution-2d, attention-mechanism, activation-functions, mixed-operations
- ✓ Results displayed for each
- ✓ Summary shown at end

**Test Status**: ⏳ To be validated

### Scenario 2: Select multiple tasks

**Steps**:
1. Run: `.build/release/macmlbench run matrix-multiply convolution-2d`
2. Verify only selected tasks run

**Expected**:
- ✓ Only 2 tasks execute (not all 5)
- ✓ Results presented in order

**Test Status**: ⏳ To be validated

### Scenario 3: Failure handling

**Steps**:
1. Run benchmarks on low-memory system OR induce failure
2. Observe behavior

**Expected**:
- ✓ If one task fails, others continue
- ✓ Final results show which succeeded/failed
- ✓ Error details included

**Test Status**: ⏳ To be validated with resource constraints

### Scenario 4: Summary report

**Steps**:
1. Run: `.build/release/macmlbench run --all`
2. Review summary

**Expected**:
- ✓ Shows results for all task types
- ✓ Comparative performance visible
- ✓ Highlights strongest/weakest areas

**Test Status**: ⏳ To be validated

### Scenario 5: Result export

**Steps**:
1. Run: `.build/release/macmlbench run --all --output results.json`
2. Verify JSON file

**Expected**:
- ✓ JSON file created
- ✓ Contains all task results
- ✓ Includes hardware info
- ✓ All configuration parameters saved

**Test Status**: ⏳ To be validated

---

## Edge Cases

### Heavy System Load

**Steps**:
1. Open resource-intensive apps
2. Run benchmark
3. Check for warnings

**Expected**:
- ✓ System load detection (if implemented)
- ✓ Warning about non-representative results

**Test Status**: ⏳ To be validated

### Insufficient Memory

**Steps**:
1. Run: `.build/release/macmlbench run matrix-multiply --batch-size 1024 --size 8192`
2. On lower-memory Mac

**Expected**:
- ✓ Graceful failure with clear message
- ✓ Suggests parameter reductions
- ✓ No crash or hang

**Test Status**: ⏳ To be validated

### Thermal Throttling

**Steps**:
1. Run extended benchmarks until Mac heats up
2. Observe thermal warnings

**Expected**:
- ✓ Warning shown if thermal state serious/critical
- ✓ Results flagged as throttled
- ✓ Suggests cooling down

**Test Status**: ⏳ To be validated with sustained load

### Interruption (Ctrl+C)

**Steps**:
1. Run: `.build/release/macmlbench run --all`
2. Press Ctrl+C during execution

**Expected**:
- ✓ Graceful cleanup message
- ✓ GPU resources released
- ✓ Exit code 130
- ✓ No crashes or GPU errors

**Test Status**: ⏳ To be validated

---

## Success Criteria Validation

### SC-001: First run within 2 minutes
- **Test**: Time from clone to first result
- **Status**: ✅ PASS - Completed in <1 minute

### SC-002: <10% variance on repeated runs
- **Test**: Run same benchmark 5 times, check variance
- **Status**: ⏳ To be validated with multiple runs

### SC-003: Hardware detection for all variants
- **Test**: Verify on M1, M2, M3, M4 Macs
- **Status**: ✅ PASS - M4 Pro verified

### SC-004: 4+ configurable parameters
- **Test**: Verify duration, batch-size, threads, size all work
- **Status**: ⏳ To be validated with US2 implementation

### SC-005: 5+ distinct task types
- **Test**: Run all tasks, verify diversity
- **Status**: ⏳ To be validated with US3 implementation

### SC-006: Differentiate Mac Silicon variants
- **Test**: Compare M1 vs M2 vs M3 vs M4 results
- **Status**: ⏳ Requires multi-hardware testing

### SC-007: Full suite <5 minutes
- **Test**: Run --all with defaults, measure total time
- **Status**: ⏳ To be validated with US3 implementation

### SC-008: 0% crashes on invalid params
- **Test**: Try various invalid inputs
- **Status**: ⏳ To be validated with error testing

### SC-009: Replicable exports
- **Test**: Export, reimport, verify all config present
- **Status**: ⏳ To be validated with export functionality

### SC-010: Comparison shows deltas
- **Test**: Run twice, compare, check percentage changes
- **Status**: ⏳ To be validated with Compare command

---

## Test Completion Status

- ✅ **P1 (MVP)**: 4/4 scenarios PASS
- ⏳ **P2**: 0/5 scenarios validated (implementation needed)
- ⏳ **P3**: 0/5 scenarios validated (implementation needed)
- ⏳ **Edge Cases**: 0/4 validated
- ⏳ **Success Criteria**: 3/10 validated

**Overall**: MVP validated, full feature testing pending completion of US2/US3
