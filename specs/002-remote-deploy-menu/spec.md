# Feature Specification: Remote Deployment and Interactive Menu

**Feature Branch**: `002-remote-deploy-menu`
**Created**: 2025-10-16
**Status**: Draft
**Input**: User description: "Okay, we need a way to remotely deploy the app. We need a menu system as well. So I need to be able to go into the menu and select the tests I would like to run and then run them or choose to run them against the local machine combined with some remote machines. So definitely make sure that we're done with the previous spec."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Interactive Menu Selection (Priority: P1)

A user wants to run the benchmark tool through an interactive menu that allows them to select which benchmarks to execute without having to remember command-line syntax or options.

**Why this priority**: This is the MVP - it provides immediate usability improvements and reduces the barrier to entry. Users can launch the tool, see their options visually, and make selections interactively.

**Independent Test**: Can be fully tested by launching the interactive menu, selecting benchmarks from a visual list, configuring parameters through prompts, and executing the selected benchmarks.

**Acceptance Scenarios**:

1. **Given** the user runs the benchmark tool in interactive mode, **When** the menu displays, **Then** the user sees a numbered list of available benchmark tasks with descriptions and can select one or more tasks by number.

2. **Given** the user has selected benchmark tasks, **When** the menu prompts for configuration, **Then** the user can set parameters (duration, size, batch size, threads) through interactive prompts with validation and defaults shown.

3. **Given** the user has configured parameters, **When** they confirm execution, **Then** the selected benchmarks run with the specified configuration and results are displayed.

4. **Given** the user is in the interactive menu, **When** they choose to exit or cancel, **Then** the menu closes gracefully without executing any benchmarks.

---

### User Story 2 - Remote Machine Deployment (Priority: P2)

A user wants to automatically deploy the benchmark tool to one or more remote Mac machines via SSH and run benchmarks remotely without manual transfer steps.

**Why this priority**: After users can select benchmarks interactively (P1), they need the ability to deploy and run on remote machines. This enables cross-machine comparisons and reduces manual deployment overhead.

**Independent Test**: Can be fully tested by configuring SSH connection details for a remote machine, deploying the benchmark tool automatically, and verifying the tool is transferred and functional on the remote system.

**Acceptance Scenarios**:

1. **Given** the user provides SSH connection details (hostname/IP, username, SSH key path), **When** they initiate remote deployment, **Then** the system connects to the remote machine, transfers the benchmark executable, and verifies successful deployment.

2. **Given** the tool is deployed to a remote machine, **When** the user runs a benchmark remotely, **Then** the benchmark executes on the remote machine and results are returned to the local system.

3. **Given** deployment fails (connection refused, authentication failure, insufficient permissions), **When** the error occurs, **Then** the system displays a clear error message explaining the issue and suggests remediation steps.

4. **Given** the user has previously deployed to a machine, **When** they deploy again, **Then** the system detects the existing installation and offers to update or skip deployment.

5. **Given** the remote machine is not Mac Silicon, **When** deployment is attempted, **Then** the system warns the user that benchmarks require Apple Silicon and asks whether to continue anyway.

---

### User Story 3 - Multi-Machine Benchmark Execution (Priority: P3)

A user wants to run benchmarks simultaneously on the local machine and one or more remote machines, then automatically aggregate and compare the results to see performance differences across hardware.

**Why this priority**: After users can deploy to remote machines (P2), they need to orchestrate multi-machine benchmarks and get comparative results. This delivers the core value proposition of understanding GPU performance across different Mac Silicon variants.

**Independent Test**: Can be fully tested by configuring multiple machines (local + 2 remote), running the same benchmark configuration across all machines, and verifying that results are collected from all machines and presented in a comparative format.

**Acceptance Scenarios**:

1. **Given** the user has configured multiple machines (local + remote), **When** they select benchmarks to run across all machines, **Then** the system executes benchmarks in parallel on all machines and tracks progress for each.

2. **Given** benchmarks are running on multiple machines, **When** one machine completes before others, **Then** the system displays that machine's results immediately while continuing to wait for remaining machines.

3. **Given** all machines have completed benchmarks, **When** results are aggregated, **Then** the system displays a comparison table showing each machine's hardware specs and benchmark results side-by-side with performance deltas highlighted.

4. **Given** one or more remote machines fail during execution, **When** the failure occurs, **Then** the system continues execution on remaining machines and indicates which machines failed in the final results.

5. **Given** the user wants to save multi-machine results, **When** they specify an output file, **Then** the system exports results from all machines in a structured format with hardware identification for each machine.

---

### Edge Cases

- **What happens when SSH connection is lost mid-execution?** The system should detect connection loss, mark that machine's benchmark as failed, continue with other machines, and attempt to reconnect or timeout gracefully with clear status indication.

- **What happens when remote machine has different macOS versions?** The system should detect version compatibility before deployment, warn if the remote macOS version may not support the benchmark tool, and allow user to decide whether to proceed.

- **What happens when multiple users deploy to the same remote machine?** The system should handle concurrent deployments gracefully, either using user-specific directories or detecting conflicts and warning the user.

- **What happens when the benchmark executable is incompatible with remote architecture?** The system should detect architecture mismatches (Intel vs Apple Silicon) before attempting execution and provide clear error messages.

- **What happens when remote machines have firewall or SSH restrictions?** The system should timeout gracefully with informative error messages and suggest checking SSH configuration, firewall rules, or network connectivity.

- **What happens when the user cancels a multi-machine benchmark run?** The system should send cancellation signals to all machines, wait for graceful shutdown on each, and display partial results from machines that completed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide an interactive menu mode that displays available benchmarks and allows users to select one or more tasks to execute.

- **FR-002**: System MUST allow users to configure benchmark parameters (duration, size, threads, batch size) through interactive prompts with input validation and default value display.

- **FR-003**: System MUST support remote deployment of the benchmark executable to Mac machines via SSH with automatic file transfer.

- **FR-004**: System MUST validate SSH connectivity and authentication before attempting deployment, providing clear error messages for connection failures.

- **FR-005**: System MUST detect remote machine hardware (Mac Silicon variant, macOS version) and warn users if compatibility issues exist.

- **FR-006**: System MUST support executing benchmarks on remote machines via SSH with real-time progress feedback transmitted back to the local machine.

- **FR-007**: System MUST allow users to configure multiple remote machines and execute benchmarks across all machines (local + remote) in a single operation.

- **FR-008**: System MUST collect results from all machines (local and remote) and aggregate them for comparison.

- **FR-009**: System MUST display multi-machine comparison results showing hardware specs and benchmark metrics for each machine side-by-side.

- **FR-010**: System MUST handle partial failures gracefully, continuing execution on functional machines when individual machines fail.

- **FR-011**: System MUST support saving SSH connection profiles (hostname, username, key path) for reuse across multiple benchmark runs.

- **FR-012**: System MUST detect existing deployments on remote machines and offer options to update, skip, or force redeployment.

- **FR-013**: System MUST provide a way to exit the interactive menu at any point without executing benchmarks.

- **FR-014**: System MUST export multi-machine benchmark results in a structured format that preserves machine identity and hardware specifications.

### Key Entities

- **RemoteMachine**: Represents a remote Mac that can execute benchmarks. Attributes include: hostname/IP address, username, SSH key path, deployment status, hardware profile (detected after connection), last deployment timestamp.

- **SSHConnection**: Represents an active or configured SSH connection. Attributes include: machine reference, connection state (connected/disconnected/failed), authentication method, last successful connection timestamp, error details (if failed).

- **DeploymentStatus**: Represents the state of tool deployment on a remote machine. Attributes include: machine reference, deployment state (not deployed/deploying/deployed/update available), deployed version, deployment timestamp, deployment path on remote system.

- **MultiMachineRun**: Represents a benchmark execution across multiple machines. Attributes include: machine list (local + remotes), selected tasks, shared configuration parameters, per-machine results, overall status, start/end timestamps.

- **MachineResult**: Represents benchmark results from a single machine in a multi-machine run. Attributes include: machine identifier, hardware profile, benchmark results array, execution status (success/failed/timeout), error details (if applicable).

### Assumptions

- **Assumption 1**: Users have SSH access credentials (username + SSH key or password) for remote machines they want to benchmark.

- **Assumption 2**: Remote machines are Mac systems with network connectivity and SSH enabled (System Settings > General > Sharing > Remote Login).

- **Assumption 3**: The benchmark executable is compatible across macOS versions 12.0+ and can be transferred as a single binary without recompilation on remote systems.

- **Assumption 4**: Users running multi-machine benchmarks understand that network latency and SSH overhead are not part of benchmark measurements - only GPU performance metrics are compared.

- **Assumption 5**: The interactive menu will be a terminal-based UI (not a graphical application) using keyboard navigation and text prompts suitable for CLI users.

- **Assumption 6**: Remote machines have sufficient permissions for the user to write to their home directory and execute binaries (~/ is writable and executable).

- **Assumption 7**: SSH connections use standard port 22 unless explicitly configured otherwise.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can launch the interactive menu and select benchmarks without consulting documentation, completing task selection within 1 minute.

- **SC-002**: Interactive parameter configuration includes inline help showing valid ranges and defaults, with 0% of users entering invalid values that aren't caught by validation prompts.

- **SC-003**: Remote deployment to a new machine completes within 30 seconds for first-time deployment (including SSH connection, transfer, and verification).

- **SC-004**: Remote deployment success rate is >95% when SSH credentials are valid and network is functional.

- **SC-005**: Remote benchmark execution returns real-time progress updates with <2 second latency between remote execution progress and local display updates.

- **SC-006**: Multi-machine benchmark execution (3 machines) completes within 120% of single-machine execution time (minimal coordination overhead).

- **SC-007**: Multi-machine result comparison clearly identifies the fastest and slowest machines for each benchmark task with percentage differences highlighted.

- **SC-008**: SSH connection profiles can be saved and reused, reducing setup time for subsequent multi-machine runs to under 10 seconds.

- **SC-009**: System detects and reports deployment state (deployed/not deployed/update needed) within 5 seconds when connecting to a previously used remote machine.

- **SC-010**: Multi-machine results export contains sufficient information to identify each machine's hardware and reproduce the exact test configuration on any machine.
