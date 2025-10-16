# Research & Technical Decisions: Remote Deployment and Interactive Menu

**Date**: 2025-10-16
**Feature**: Remote Deployment and Interactive Menu
**Phase**: Phase 0 - Outline & Research

## Overview

This document consolidates research findings and technical decisions for implementing interactive menu navigation and SSH-based remote deployment for the Mac ML Benchmark Suite. All decisions build on Feature 001's foundation and prioritize simplicity and native macOS capabilities.

---

## Decision 1: Interactive Menu Library

**Decision**: Native Swift with Foundation's FileHandle for terminal I/O (no external dependencies)

**Rationale**:
- **No New Dependencies**: Keeps project simple, aligns with Code Quality principle (YAGNI)
- **Foundation's FileHandle**: Provides raw terminal I/O sufficient for numbered menus and text prompts
- **Swift's `readLine()`**: Built-in function handles user input with proper buffering
- **ANSI Escape Codes**: Native terminal control for cursor positioning, clearing screen, colors

**Menu Implementation Approach**:
- Clear screen with ANSI codes (`\u{001B}[2J\u{001B}[H`)
- Display numbered options
- Read user input with `readLine()`
- Validate selections and loop until valid
- No complex TUI framework needed for simple numbered menus

**Alternatives Considered**:
- **ncurses/curses**: C library, requires FFI, overkill for simple numbered menus
- **Terminal UI frameworks (Ink, etc.)**: External dependencies, adds complexity for simple use case
- **Native only**: ✅ Chosen - simple, zero dependencies, works everywhere

---

## Decision 2: SSH Execution Method

**Decision**: Swift's `Process` API with `ssh` and `scp` command-line tools

**Rationale**:
- **Process API**: Native Swift way to execute shell commands and capture output
- **System ssh/scp**: Pre-installed on all Macs, no additional dependencies
- **SSH Key Support**: Works with standard ~/.ssh/id_ed25519 or ~/.ssh/id_rsa keys
- **Real-time Output**: Process API supports async reading of stdout/stderr for progress updates

**SSH Command Patterns**:
```swift
// Deploy: scp .build/release/macmlbench user@host:~/macmlbench
// Execute: ssh user@host "~/macmlbench run matrix-multiply --output results.json"
// Download: scp user@host:~/results.json ./results/remote-results.json
```

**Alternatives Considered**:
- **Swift NIO SSH**: Complex, async framework, overkill for simple SSH exec
- **libssh2 bindings**: C library, requires FFI, maintenance burden
- **Process + system ssh**: ✅ Chosen - simple, reliable, zero new dependencies

---

## Decision 3: SSH Profile Storage

**Decision**: JSON file in `config/machines.json` using Swift Codable

**Rationale**:
- **Consistency**: Matches existing result export using JSON + Codable
- **Human-Editable**: Users can manually edit config/machines.json if needed
- **Simple Storage**: No database needed for small number of machine profiles
- **Reuses Code**: JSONEncoder/Decoder already used in Feature 001

**Profile Structure**:
```json
{
  "machines": [
    {
      "id": "uuid",
      "name": "Mac Studio",
      "hostname": "10.20.1.64",
      "username": "willsauter",
      "sshKeyPath": "~/.ssh/id_ed25519",
      "deploymentPath": "~/macmlbench",
      "lastDeployed": "2025-10-16T10:30:00Z"
    }
  ]
}
```

**Alternatives Considered**:
- **Property list (.plist)**: Mac-specific, not cross-platform readable
- **YAML**: Requires external parser dependency
- **JSON**: ✅ Chosen - standard, built-in support, human-readable

---

## Decision 4: Remote Execution Flow

**Decision**: Deploy once, execute many times with SSH exec

**Rationale**:
- **Efficient**: Transfer ~2MB binary once, subsequent runs just execute via SSH
- **Version Tracking**: Store deployed version, detect when updates needed
- **Fast Execution**: SSH exec has minimal overhead compared to re-transfer every time

**Flow**:
1. Check if deployed (ssh host "[ -f ~/macmlbench ] && echo exists")
2. If not deployed or outdated: scp binary to remote
3. Execute benchmark: ssh host "~/macmlbench run <task> --output ~/results.json"
4. Download results: scp remote:~/results.json local:~/results/remote-machine.json
5. Parse and display/compare

**Alternatives Considered**:
- **Transfer every time**: Slow (2MB over network per run)
- **Build on remote**: Requires Swift toolchain on remote, complex
- **Deploy once, exec many**: ✅ Chosen - fast, simple, caches deployment

---

## Decision 5: Multi-Machine Coordination

**Decision**: Parallel SSH execution using DispatchQueue with async/await

**Rationale**:
- **Swift Concurrency**: Native async/await support in Swift 5.9+
- **Parallel Execution**: Run benchmarks on all machines simultaneously
- **Progress Tracking**: Async streams for real-time updates from each machine
- **Error Isolation**: Task failures don't crash entire run

**Coordination Pattern**:
```swift
await withTaskGroup(of: MachineResult.self) { group in
    for machine in machines {
        group.addTask {
            await executeBenchmarkRemotely(on: machine)
        }
    }

    for await result in group {
        displayResult(result)
    }
}
```

**Alternatives Considered**:
- **Sequential execution**: Too slow for multi-machine (3x slower for 3 machines)
- **DispatchQueue only**: Less elegant than async/await for coordination
- **Async/await with TaskGroup**: ✅ Chosen - modern, clean, handles errors well

---

## Decision 6: Menu Navigation Flow

**Decision**: State machine with numbered selections and confirmation steps

**Rationale**:
- **Simple UX**: Numbered menus are intuitive and work on any terminal
- **State Tracking**: Menu knows current state (selecting tasks, configuring params, selecting machines, confirming)
- **Validation at Each Step**: Prevents invalid states, clear error messages

**Menu States**:
1. **Main Menu**: Select benchmarks, configure machines, or exit
2. **Benchmark Selection**: Multi-select benchmarks (1,3,5 or "all")
3. **Parameter Configuration**: Set duration, size, batch, threads
4. **Machine Selection**: Choose local only, or local + remotes
5. **Confirmation**: Review selections, execute or go back
6. **Execution**: Show progress, display results
7. **Results**: View, export, or return to main menu

**Alternatives Considered**:
- **Flat menu**: Confusing with too many options at once
- **Wizard-style**: ✅ Chosen - guides user through logical flow

---

## Decision 7: Remote Hardware Detection

**Decision**: Execute `macmlbench hardware --json` on remote and parse output

**Rationale**:
- **Reuse Existing Code**: Feature 001's hardware command already detects and formats hardware
- **Consistent Detection**: Same logic runs locally and remotely
- **JSON Parsing**: Easy to deserialize on local machine

**Detection Flow**:
```
ssh remote "~/macmlbench hardware --json" → JSON output
Parse JSON → HardwareProfile
Compare with local → detect compatibility issues
```

**Alternatives Considered**:
- **Separate detection logic**: Duplicates code, inconsistent
- **Reuse existing command**: ✅ Chosen - DRY, consistent, simple

---

## Decision 8: Deployment Verification

**Decision**: Execute `macmlbench version` on remote and compare with local

**Rationale**:
- **Version Check**: Ensures deployed tool matches local version
- **Functional Test**: If version command works, deployment succeeded
- **Update Detection**: Different versions trigger update prompt

**Verification**:
```
ssh remote "~/macmlbench version" → "1.0.0"
Compare with local version
If mismatch: prompt for update
```

**Alternatives Considered**:
- **File checksum**: More complex, same reliability
- **Version command**: ✅ Chosen - simple, functional test included

---

## Decision 9: Result Aggregation Format

**Decision**: Extend existing JSON export with machine metadata array

**Rationale**:
- **Consistent Format**: Reuses BenchmarkResult from Feature 001
- **Machine Grouping**: Array of machines, each with hardware + results
- **Comparison Ready**: Structure optimized for comparison display

**Multi-Machine Export Structure**:
```json
{
  "multiMachineRun": {
    "id": "uuid",
    "timestamp": "2025-10-16T10:30:00Z",
    "configuration": { "tasks": [...], "parameters": {...} },
    "machines": [
      {
        "machineId": "local",
        "hardware": {...},
        "results": [...]
      },
      {
        "machineId": "remote-1",
        "hostname": "10.20.1.64",
        "hardware": {...},
        "results": [...]
      }
    ]
  }
}
```

**Alternatives Considered**:
- **Separate files per machine**: Harder to compare
- **Unified structure**: ✅ Chosen - easier comparison, single export

---

## Decision 10: Error Handling Strategy

**Decision**: Fail-fast for menu/validation, graceful degradation for remote failures

**Rationale**:
- **Menu Errors**: Invalid input loops until valid (no crashes)
- **SSH Connection Errors**: Clear messages, suggest fixes, don't retry infinitely
- **Remote Execution Errors**: Continue with other machines, mark failed ones
- **Timeout Handling**: 60s timeout for SSH connection, 2x benchmark duration for execution

**Error Categories**:
- **User Input**: Invalid menu selections → re-prompt with helpful message
- **SSH Connection**: Authentication/network failures → display error, suggest checking SSH config
- **Deployment**: Permission/disk space → clear message with remediation
- **Remote Execution**: Benchmark failures → continue with other machines, report in summary

**Alternatives Considered**:
- **Crash on any error**: Poor UX
- **Graceful degradation**: ✅ Chosen - maximizes successful results

---

## Open Questions & Assumptions

### Resolved Assumptions from Spec:
- ✅ SSH access required (Assumption 1)
- ✅ Remote Macs with SSH enabled (Assumption 2)
- ✅ Binary compatibility macOS 12.0+ (Assumption 3)
- ✅ Network latency not in measurements (Assumption 4)
- ✅ Terminal-based UI (Assumption 5)
- ✅ Home directory writable (Assumption 6)
- ✅ SSH port 22 standard (Assumption 7)

### Implementation Assumptions:
- SSH keys preferred over passwords (more secure, easier automation)
- Interactive menu runs in current terminal (not separate window)
- Remote machines accessible from local network (no VPN/tunnel complexity in MVP)
- Deployment path always ~/macmlbench (configurable in future if needed)

---

## Summary

All technical decisions made with rationale documented. No NEEDS CLARIFICATION items remain. The chosen stack (Swift Process API + native terminal I/O + async/await) aligns with:
- Complete Feature Delivery (can implement all user stories independently)
- Code Quality (simple, no unnecessary dependencies, reuses Feature 001)
- Testing Discipline (manual validation + unit tests for SSH/menu logic)
- Performance Goals (minimal overhead, parallel execution)
- Success Criteria (fast deployment, real-time updates, clear comparisons)

**Phase 0 Complete** - Ready for Phase 1 (data model & contracts design).
