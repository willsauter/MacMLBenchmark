# Implementation Plan: Remote Deployment and Interactive Menu

**Branch**: `002-remote-deploy-menu` | **Date**: 2025-10-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-remote-deploy-menu/spec.md`

## Summary

Add interactive menu system and remote deployment capabilities to the Mac ML Benchmark Suite. Users can launch an interactive menu to select benchmarks and configure parameters, deploy the tool to remote Mac machines via SSH, and execute benchmarks across multiple machines (local + remote) with automatic result aggregation and comparison. The MVP (P1) delivers an interactive menu, P2 adds SSH deployment, and P3 provides multi-machine orchestration.

## Technical Context

**Language/Version**: Swift 5.9+ (consistent with Feature 001)
**Primary Dependencies**: Existing (ArgumentParser, Metal), New: Process/SSH for remote execution, terminal UI library for interactive menu
**Storage**: File system (JSON for SSH profiles and multi-machine results), extends existing result export
**Testing**: Manual validation against acceptance scenarios, unit tests for SSH connection and deployment logic
**Target Platform**: macOS 12.0+ on Apple Silicon (local), remote Macs with SSH enabled
**Project Type**: Single project (extends existing CLI tool with interactive mode)
**Performance Goals**: Interactive menu response <100ms, remote deployment <30s, multi-machine execution within 120% of single-machine time
**Constraints**: Requires SSH access to remote machines, network connectivity, remote machines must be Macs with macOS 12.0+
**Scale/Scope**: Support 1-10 remote machines per run, handle SSH connection pooling, parallel remote execution

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify compliance with all principles in `.specify/memory/constitution.md`:

- [x] **Complete Feature Delivery**: All user stories for this feature will be fully implemented and tested before moving to next feature
- [x] **Incremental User Story Implementation**: User stories are prioritized (P1, P2, P3) and independently testable - P1 interactive menu, P2 SSH deployment, P3 multi-machine
- [x] **Testing Discipline**: Testing strategy is explicit - manual validation against acceptance scenarios, unit tests for SSH logic
- [x] **Code Quality**: Implementation will follow YAGNI, single responsibility, and clarity over cleverness - reuse existing models where possible
- [x] **Documentation Standards**: spec.md (complete), plan.md (this file), tasks.md (next phase), and quickstart.md (Phase 1) will be maintained

**Complexity Justification**: No violations - all gates pass.

## Project Structure

### Documentation (this feature)

```
specs/002-remote-deploy-menu/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (technical decisions)
├── data-model.md        # Phase 1 output (entities and relationships)
├── quickstart.md        # Phase 1 output (how to use new features)
├── contracts/           # Phase 1 output (menu and SSH interfaces)
│   ├── menu-interface.md     # Interactive menu flow
│   └── ssh-interface.md      # Remote deployment API
├── checklists/          # Quality validation
│   └── requirements.md  # Spec quality checklist (complete)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root - extends Feature 001)

```
src/
├── models/              # Extends existing (add RemoteMachine, SSHConnection, DeploymentStatus, MultiMachineRun, MachineResult)
├── benchmarks/          # Existing (no changes)
├── hardware/            # Existing (no changes)
├── metrics/             # Existing (no changes)
├── output/              # Extends (add multi-machine result formatter)
├── cli/                 # Extends (add MenuCommand, DeployCommand, RemoteCommand)
├── remote/              # NEW - Remote execution (SSHClient, DeploymentManager, RemoteExecutor)
├── menu/                # NEW - Interactive menu (MenuUI, MenuState, InputHandler)
├── BenchmarkExecutor.swift  # Existing (minor extensions for remote execution)
└── main.swift           # Extends (add menu and remote commands)

tests/
├── integration/         # Extends (add remote deployment tests)
└── unit/                # Extends (add SSH client tests, menu tests)

config/                  # NEW - SSH profiles storage
└── machines.json        # Saved remote machine configurations
```

**Structure Decision**: Extends existing single project structure from Feature 001. New functionality added in `remote/` and `menu/` directories to keep concerns separated. Reuses all existing models (BenchmarkTask, BenchmarkResult, HardwareProfile, etc.) and adds new entities specific to remote execution and multi-machine orchestration.

## Complexity Tracking

*No violations - Constitution Check passed. This section is empty.*
