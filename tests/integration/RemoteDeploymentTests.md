# Remote Deployment Integration Tests

**Feature**: Remote Deployment and Interactive Menu
**Date**: 2025-10-16

## Prerequisites

- Two remote Mac machines with SSH enabled
- SSH keys configured (ssh-copy-id completed)
- Feature 001 (Mac ML Benchmark Suite) built

## User Story 2: Remote Deployment

### Test 1: Add Remote Machine

**Steps**:
1. Run: `macmlbench menu`
2. Select "Manage Remote Machines"
3. Select "Add New Machine"
4. Enter: Name "Mac Studio", Hostname "10.20.1.64", Username "willsauter"
5. Accept default SSH key path

**Expected**:
- Connection test succeeds
- Machine profile saved to config/machines.json
- Returns to machine management menu

### Test 2: Deploy to Remote

**Steps**:
1. In machine management, select "Deploy to Machine"
2. Select the configured machine
3. Confirm deployment

**Expected**:
- Binary transfers via SCP
- Deployment verification succeeds
- Remote hardware detected and displayed
- Machine marked as deployed

### Test 3: Remote Execution

**Steps**:
1. From main menu, select "Run Benchmarks"
2. Select matrix-multiply
3. When prompted "Run on remote machines?", answer yes
4. Select the deployed remote machine
5. Confirm execution

**Expected**:
- Benchmark executes on remote machine
- Results downloaded and displayed
- Matches format of local execution

## User Story 3: Multi-Machine

### Test 4: Multi-Machine Execution

**Steps**:
1. Configure 2 remote machines (10.20.1.64, 10.20.1.89)
2. Deploy to both
3. Run benchmarks selecting local + both remotes
4. Select 2-3 benchmark tasks

**Expected**:
- Parallel execution on all 3 machines
- Progress shown for each
- Results aggregated and compared
- Fastest machine highlighted per task

### Test 5: Partial Failure

**Steps**:
1. Configure one valid and one invalid machine (bad hostname)
2. Run multi-machine benchmark

**Expected**:
- Valid machines complete successfully
- Invalid machine marked as failed
- Results show which succeeded/failed
- No crash or hang

## Test Results

- [ ] Test 1: Add Remote Machine
- [ ] Test 2: Deploy to Remote
- [ ] Test 3: Remote Execution
- [ ] Test 4: Multi-Machine Execution
- [ ] Test 5: Partial Failure Handling
