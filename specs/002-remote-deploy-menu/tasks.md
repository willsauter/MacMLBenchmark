# Tasks: Remote Deployment and Interactive Menu

**Input**: Design documents from `/specs/002-remote-deploy-menu/`
**Prerequisites**: plan.md (complete), spec.md (complete), research.md (complete), data-model.md (complete), contracts/ (complete)
**Extends**: Feature 001 (Mac ML Benchmark Suite) - builds on existing codebase

**Tests**: Manual validation against acceptance scenarios, unit tests for SSH and menu logic

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths

---

## Phase 1: Setup (Extension Infrastructure)

**Purpose**: Prepare for new menu and remote capabilities

- [x] T001 Create config/ directory for SSH profile storage
- [x] T002 Create src/menu/ and src/remote/ directories for new functionality
- [x] T003 Update Package.swift to include new source directories if needed
- [x] T004 Update .gitignore to exclude config/machines.json from version control

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and infrastructure for menu and remote execution

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create DeploymentState enum (notDeployed/deploying/deployed/updateAvailable) in src/models/DeploymentState.swift
- [x] T006 Create ConnectionState enum (connecting/connected/disconnected/failed) in src/models/ConnectionState.swift
- [x] T007 Create ExecutionStatus enum (success/failed/timeout/cancelled) in src/models/ExecutionStatus.swift
- [x] T008 Create RemoteMachine struct with id, name, hostname, username, sshKeyPath, deploymentPath, deploymentStatus, hardwareProfile in src/models/RemoteMachine.swift conforming to Codable
- [x] T009 Create SSHConnection class with machine, connectionState, process, errorMessage in src/models/SSHConnection.swift
- [x] T010 Create DeploymentStatus struct with state, deployedVersion, deploymentTimestamp in src/models/DeploymentStatus.swift conforming to Codable
- [x] T011 Create MultiMachineRun struct with id, machines, selectedTasks, sharedConfiguration, results, timestamps in src/models/MultiMachineRun.swift conforming to Codable
- [x] T012 Create MachineResult struct with machineId, machineName, hardware, benchmarkResults, status, errorMessage in src/models/MachineResult.swift conforming to Codable
- [x] T013 Create MachineProfileStore class for loading/saving SSH profiles to config/machines.json in src/remote/MachineProfileStore.swift
- [x] T014 Create SSHClient class with connection methods (connect, testConnection, executeCommand) using Process API in src/remote/SSHClient.swift
- [x] T015 Create DeploymentManager class with deploy, verify, checkVersion methods in src/remote/DeploymentManager.swift
- [x] T016 Create MenuState class tracking current menu state and user selections in src/menu/MenuState.swift
- [x] T017 Create TerminalUI class with methods for clearing screen, displaying menus, reading input in src/menu/TerminalUI.swift

**Checkpoint**: Foundation ready - user story implementation can begin

---

## Phase 3: User Story 1 - Interactive Menu (Priority: P1) 🎯 MVP

**Goal**: Launch interactive menu, select benchmarks and parameters, execute locally

**Independent Test**: Run `macmlbench menu`, select benchmarks interactively, configure params, execute and see results

### Implementation for User Story 1

- [x] T018 [P] [US1] Create MenuCommand struct as ArgumentParser command in src/cli/MenuCommand.swift
- [x] T019 [P] [US1] Implement main menu display showing options (Run Benchmarks, Manage Machines, Exit) in MenuCommand
- [x] T020 [US1] Implement benchmark selection screen displaying all tasks with multi-select in MenuCommand
- [x] T021 [US1] Implement parameter configuration prompts for duration, size, batch, threads with validation in MenuCommand
- [x] T022 [US1] Implement confirmation screen showing selected benchmarks and configuration in MenuCommand
- [x] T023 [US1] Wire menu execution to existing BenchmarkExecutor for local runs in MenuCommand
- [x] T024 [US1] Add menu input validation with helpful error messages for invalid selections in TerminalUI
- [x] T025 [US1] Implement graceful menu exit on user cancel or quit command in MenuCommand
- [x] T026 [US1] Add MenuCommand to main.swift subcommands list
- [x] T027 [US1] Test interactive menu flow with local benchmark execution

**Checkpoint**: Interactive menu functional for local benchmarks

---

## Phase 4: User Story 2 - Remote Deployment (Priority: P2)

**Goal**: Deploy tool to remote machines via SSH and execute benchmarks remotely

**Independent Test**: Configure remote machine, deploy tool, run benchmark remotely, verify results returned

### Implementation for User Story 2

- [x] T028 [P] [US2] Implement SSH connection testing with timeout and error handling in SSHClient
- [x] T029 [P] [US2] Implement binary deployment via scp in DeploymentManager
- [x] T030 [US2] Implement deployment verification using remote version command in DeploymentManager
- [x] T031 [US2] Implement remote hardware detection using ssh exec of hardware command in SSHClient
- [x] T032 [US2] Create RemoteExecutor class for executing benchmarks via SSH with output streaming in src/remote/RemoteExecutor.swift
- [x] T033 [US2] Implement result download from remote machine via scp in RemoteExecutor
- [x] T034 [US2] Add "Add Remote Machine" option to menu for SSH configuration in MenuCommand
- [x] T035 [US2] Implement machine profile persistence to config/machines.json in MachineProfileStore
- [x] T036 [US2] Implement update detection comparing local vs remote versions in DeploymentManager
- [x] T037 [US2] Add deployment error handling with helpful messages (auth failures, connection refused, permissions) in SSHClient
- [x] T038 [US2] Test remote deployment and execution end-to-end

**Checkpoint**: Remote deployment and execution functional

---

## Phase 5: User Story 3 - Multi-Machine Execution (Priority: P3)

**Goal**: Run benchmarks across local + multiple remote machines in parallel with aggregated results

**Independent Test**: Configure 2+ machines, run same benchmark on all, verify parallel execution and comparison display

### Implementation for User Story 3

- [x] T039 [US3] Implement multi-machine selection UI in menu showing local + configured remotes in MenuCommand
- [x] T040 [US3] Create MultiMachineExecutor class coordinating parallel execution using async/await TaskGroup in src/remote/MultiMachineExecutor.swift
- [x] T041 [US3] Implement parallel remote execution launching SSH commands concurrently in MultiMachineExecutor
- [x] T042 [US3] Implement progress tracking for multiple machines with per-machine status updates in MultiMachineExecutor
- [x] T043 [US3] Add partial failure handling continuing with successful machines in MultiMachineExecutor
- [x] T044 [US3] Create MultiMachineResultFormatter for side-by-side comparison display in src/output/MultiMachineResultFormatter.swift
- [x] T045 [US3] Implement machine comparison highlighting fastest/slowest for each task in MultiMachineResultFormatter
- [x] T046 [US3] Implement multi-machine result aggregation creating MachineResult for each machine in MultiMachineExecutor
- [x] T047 [US3] Create MultiMachineExporter for exporting results with machine identification in src/output/MultiMachineExporter.swift
- [x] T048 [US3] Wire multi-machine execution to menu's machine selection screen in MenuCommand
- [x] T049 [US3] Test multi-machine execution with 3 machines (local + 2 remote)

**Checkpoint**: Multi-machine execution and comparison functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Error handling, testing, documentation

- [x] T050 [P] Implement SSH connection timeout handling (60s for connect, 2x duration for exec) in SSHClient
- [x] T051 [P] Add remote architecture detection warning for Intel Macs in DeploymentManager
- [x] T052 [P] Implement cancellation propagation to remote machines in MultiMachineExecutor
- [x] T053 Create unit tests for SSHClient connection and command execution in tests/unit/SSHClientTests.swift
- [x] T054 Create unit tests for menu state transitions and input validation in tests/unit/MenuStateTests.swift
- [x] T055 Create integration test plan for remote deployment scenarios in tests/integration/RemoteDeploymentTests.md
- [x] T056 Update quickstart.md with examples for all three user stories
- [x] T057 Add inline comments explaining SSH Process API usage
- [x] T058 Verify all error messages include remediation steps per FR requirements

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational
  - Can proceed sequentially (P1 → P2 → P3)
  - P2 and P3 depend on P1 menu infrastructure
- **Polish (Phase 6)**: Depends on desired user stories complete

### User Story Dependencies

- **US1 (P1)**: Independent - menu works with existing local execution
- **US2 (P2)**: Can reuse US1 menu for machine config, extends with SSH
- **US3 (P3)**: Requires US2 deployment + uses US1 menu for multi-machine selection

### Parallel Opportunities

- Foundational: T005-T007 (enums), T008-T012 (models), T013-T017 (infrastructure) can run in parallel
- US1: T018-T019 (menu screens) can run in parallel
- US2: T028-T031 (SSH operations) can run in parallel
- Polish: T050-T052 (error handling), T053-T055 (tests) can run in parallel

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (T018-T027)
4. **STOP and VALIDATE**: Test interactive menu with local execution
5. MVP usable - easier benchmark selection without CLI syntax

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 → Interactive menu working
3. Add US2 → Remote deployment working
4. Add US3 → Multi-machine comparison working

---

## Task Count Summary

- **Phase 1 (Setup)**: 4 tasks
- **Phase 2 (Foundational)**: 13 tasks
- **Phase 3 (User Story 1 - P1 MVP)**: 10 tasks
- **Phase 4 (User Story 2 - P2)**: 11 tasks
- **Phase 5 (User Story 3 - P3)**: 11 tasks
- **Phase 6 (Polish)**: 9 tasks

**Total**: 58 tasks

**Parallel Opportunities**: 18 tasks marked [P]
