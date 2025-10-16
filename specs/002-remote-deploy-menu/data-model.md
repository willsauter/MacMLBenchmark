# Data Model: Remote Deployment and Interactive Menu

**Date**: 2025-10-16
**Feature**: Remote Deployment and Interactive Menu
**Phase**: Phase 1 - Design & Contracts

## Overview

This document defines the data entities for remote deployment and multi-machine execution, extending Feature 001's existing models.

---

## New Entities

### RemoteMachine

**Purpose**: Represents a remote Mac for benchmark execution

**Attributes**:
- `id`: UUID
- `name`: String (user-friendly identifier)
- `hostname`: String (IP or DNS name)
- `username`: String
- `sshKeyPath`: String (path to private key, e.g., ~/.ssh/id_ed25519)
- `deploymentPath`: String (where tool is installed, default: ~/macmlbench)
- `deploymentStatus`: DeploymentState enum
- `hardwareProfile`: HardwareProfile? (detected after first connection)
- `lastDeployed`: Date?
- `lastConnected`: Date?

**Validation**:
- hostname must be valid IP or DNS
- sshKeyPath must exist locally
- deploymentPath must be absolute

### SSHConnection

**Purpose**: Active SSH connection state

**Attributes**:
- `machine`: RemoteMachine
- `connectionState`: ConnectionState enum (connecting/connected/disconnected/failed)
- `process`: Process? (active SSH process)
- `errorMessage`: String?

**Lifecycle**: connecting → connected → (executing) → disconnected

### DeploymentStatus

**Purpose**: Deployment state on remote machine

**Attributes**:
- `state`: DeploymentState enum (notDeployed/deploying/deployed/updateAvailable)
- `deployedVersion`: String?
- `deploymentTimestamp`: Date?

### MultiMachineRun

**Purpose**: Benchmark run across multiple machines

**Attributes**:
- `id`: UUID
- `machines`: [String] (machine IDs: "local" + remote UUIDs)
- `selectedTasks`: [String]
- `sharedConfiguration`: BenchmarkConfiguration
- `results`: [String: MachineResult] (machineId → result)
- `startTime`: Date
- `endTime`: Date?

### MachineResult

**Purpose**: Results from one machine in multi-machine run

**Attributes**:
- `machineId`: String
- `machineName`: String
- `hardware`: HardwareProfile
- `benchmarkResults`: [BenchmarkResult] (reuses from Feature 001)
- `status`: ExecutionStatus enum (success/failed/timeout/cancelled)
- `errorMessage`: String?

---

## Enums

```swift
enum DeploymentState: String, Codable {
    case notDeployed
    case deploying
    case deployed
    case updateAvailable
}

enum ConnectionState: String, Codable {
    case connecting
    case connected
    case disconnected
    case failed
}

enum ExecutionStatus: String, Codable {
    case success
    case failed
    case timeout
    case cancelled
}
```

---

## Phase 1 Data Model Complete

Ready for contracts (menu flow + SSH interface).
