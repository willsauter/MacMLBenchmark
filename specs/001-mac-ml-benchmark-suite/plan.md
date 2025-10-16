# Implementation Plan: Mac ML Benchmark Suite

**Branch**: `001-mac-ml-benchmark-suite` | **Date**: 2025-10-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-mac-ml-benchmark-suite/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a benchmark suite for Mac Silicon GPUs that allows ML/AI developers to measure and compare GPU performance across different workloads. Users can run individual or comprehensive benchmarks with configurable parameters (duration, size, threads, batch) and export results for analysis. The MVP (P1) delivers a single-command benchmark experience, P2 adds parameter customization, and P3 provides multi-task comparison capabilities.

## Technical Context

**Language/Version**: Swift 5.9+ (for Metal Performance Shaders access and macOS system APIs)
**Primary Dependencies**: Metal Performance Shaders (MPS), Foundation, ArgumentParser (CLI), SwiftJSON (result export)
**Storage**: File system (JSON/CSV result files), no database required
**Testing**: XCTest for unit tests, manual validation against acceptance scenarios (no automated test suite requirement per spec assumptions)
**Target Platform**: macOS 12.0+ on Apple Silicon (M1/M2/M3 and variants)
**Project Type**: Single project (command-line tool)
**Performance Goals**: Benchmarks complete in 10-30 seconds (default params), full suite under 5 minutes, <10% result variance on repeated runs
**Constraints**: Mac Silicon GPU exclusive, Metal API dependent, must detect and report thermal throttling, graceful handling of resource constraints
**Scale/Scope**: 5+ distinct benchmark task types, 4+ configurable parameters per task, support for M1/M2/M3 hardware variants

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify compliance with all principles in `.specify/memory/constitution.md`:

- [x] **Complete Feature Delivery**: All user stories for this feature will be fully implemented and tested before moving to next feature
- [x] **Incremental User Story Implementation**: User stories are prioritized (P1, P2, P3) and independently testable - P1 MVP, P2 adds configuration, P3 adds multi-task
- [x] **Testing Discipline**: Testing strategy is explicit - manual validation against acceptance scenarios, no automated test suite required per spec assumptions
- [x] **Code Quality**: Implementation will follow YAGNI, single responsibility, and clarity over cleverness - straightforward CLI tool without unnecessary abstractions
- [x] **Documentation Standards**: spec.md (complete), plan.md (this file), tasks.md (next phase), and quickstart.md (Phase 1) will be maintained

**Complexity Justification**: No violations - all gates pass.

## Project Structure

### Documentation (this feature)

```
specs/001-mac-ml-benchmark-suite/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (technical decisions)
├── data-model.md        # Phase 1 output (entities and relationships)
├── quickstart.md        # Phase 1 output (how to build and run)
├── contracts/           # Phase 1 output (CLI interface contracts)
│   └── cli-interface.md # Command-line API specification
├── checklists/          # Quality validation
│   └── requirements.md  # Spec quality checklist (complete)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
src/
├── models/              # Data entities (BenchmarkTask, Configuration, Result, HardwareProfile, TaskParameter)
├── benchmarks/          # Benchmark task implementations (LLM, Image, Matrix, Training, etc.)
├── hardware/            # Hardware detection and monitoring (Metal API wrappers, thermal state)
├── metrics/             # Performance metric collection and calculation
├── output/              # Result formatting and export (human-readable, JSON, CSV)
├── cli/                 # Command-line interface (ArgumentParser, command routing)
└── main.swift           # Entry point

tests/
├── integration/         # Manual integration tests based on acceptance scenarios
└── unit/                # Unit tests for core logic (validation, calculation, formatting)

results/                 # Default directory for exported benchmark results (created at runtime)
```

**Structure Decision**: Single project structure selected. This is a standalone CLI tool with no web/mobile components. All code resides in `src/` organized by concern (models, benchmarks, hardware, metrics, output, cli). The `benchmarks/` directory will contain individual benchmark task implementations, each conforming to a common protocol. The `hardware/` directory isolates Mac-specific Metal and system APIs for testability. The `cli/` directory handles argument parsing and user interaction, keeping it separate from core benchmark logic.

## Complexity Tracking

*No violations - Constitution Check passed. This section is empty.*
