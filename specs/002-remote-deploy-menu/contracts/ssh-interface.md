# SSH Interface Contract: Remote Deployment

**Date**: 2025-10-16
**Feature**: Remote Deployment and Interactive Menu

## CLI Commands

### Deploy Command
```bash
macmlbench deploy <hostname> --username <user> [--key <path>]
```

Deploys benchmark tool to remote machine.

### Remote Command
```bash
macmlbench remote <hostname> run <task> [options]
```

Executes benchmark on remote machine and returns results.

## SSH Operations

### 1. Test Connection
```bash
ssh -o ConnectTimeout=10 user@host "echo connected"
```

### 2. Deploy Binary
```bash
scp -o ConnectTimeout=30 .build/release/macmlbench user@host:~/macmlbench
ssh user@host "chmod +x ~/macmlbench"
```

### 3. Verify Deployment
```bash
ssh user@host "~/macmlbench version"
```

### 4. Detect Hardware
```bash
ssh user@host "~/macmlbench hardware --json"
```

### 5. Execute Benchmark
```bash
ssh user@host "~/macmlbench run matrix-multiply --output ~/results.json"
```

### 6. Download Results
```bash
scp user@host:~/results.json ./results/remote-machine.json
```

## Multi-Machine Execution

Parallel execution using Swift async/await:
```swift
let results = await withTaskGroup(of: MachineResult.self) { group in
    for machine in machines {
        group.addTask { await executeOn(machine) }
    }
    return await group.reduce(into: []) { $0.append($1) }
}
```
