import Foundation

/// Coordinates benchmark execution across multiple machines
class MultiMachineExecutor {
    /// Executes benchmarks across local and remote machines
    func execute(
        localIncluded: Bool,
        remoteMachines: [RemoteMachine],
        tasks: [String],
        parameterOverrides: [String: [String: AnyCodable]]
    ) async throws -> MultiMachineRun {
        let hardware = try HardwareDetector.detect()

        let config = BenchmarkConfiguration(
            selectedTasks: tasks,
            parameterOverrides: parameterOverrides,
            hardware: hardware
        )

        var machineIds: [String] = []
        if localIncluded {
            machineIds.append("local")
        }
        for machine in remoteMachines {
            machineIds.append(machine.id.uuidString)
        }

        var run = MultiMachineRun(machines: machineIds, selectedTasks: tasks, sharedConfiguration: config)

        // Execute on local if included
        if localIncluded {
            print("\n[Local] Executing benchmarks...")
            do {
                let executor = BenchmarkExecutor()
                let results = try executor.execute(configuration: config)

                let machineResult = MachineResult(
                    machineId: "local",
                    machineName: "Local Machine",
                    hardware: hardware,
                    benchmarkResults: results,
                    status: .success
                )

                run.addResult(machineResult, for: "local")
            } catch {
                let machineResult = MachineResult(
                    machineId: "local",
                    machineName: "Local Machine",
                    hardware: hardware,
                    benchmarkResults: [],
                    status: .failed,
                    errorMessage: error.localizedDescription
                )
                run.addResult(machineResult, for: "local")
                print("[Local] ✗ Failed: \(error.localizedDescription)")
            }
        }

        // Execute on remote machines in parallel
        await withTaskGroup(of: (String, MachineResult).self) { group in
            for machine in remoteMachines {
                group.addTask {
                    let result = await self.executeOnRemote(machine: machine, tasks: tasks, parameterOverrides: parameterOverrides)
                    return (machine.id.uuidString, result)
                }
            }

            for await (machineId, result) in group {
                run.addResult(result, for: machineId)
                print("[\(result.machineName)] Complete - Status: \(result.status.rawValue)")
            }
        }

        run.complete()
        return run
    }

    /// Executes on a single remote machine
    private func executeOnRemote(
        machine: RemoteMachine,
        tasks: [String],
        parameterOverrides: [String: [String: AnyCodable]]
    ) async -> MachineResult {
        print("[\(machine.name)] Starting execution...")

        do {
            let executor = RemoteExecutor(machine: machine)
            let results = try await executor.execute(tasks: tasks, parameterOverrides: parameterOverrides)

            return MachineResult(
                machineId: machine.id.uuidString,
                machineName: machine.name,
                hardware: machine.hardwareProfile ?? HardwareProfile(
                    modelName: machine.hostname,
                    chipIdentifier: "Unknown",
                    gpuCoreCount: 0,
                    totalMemoryGB: 0,
                    gpuMemoryGB: 0,
                    macOSVersion: "0.0",
                    detectionTimestamp: Date()
                ),
                benchmarkResults: results,
                status: .success
            )

        } catch {
            return MachineResult(
                machineId: machine.id.uuidString,
                machineName: machine.name,
                hardware: machine.hardwareProfile ?? HardwareProfile(
                    modelName: machine.hostname,
                    chipIdentifier: "Unknown",
                    gpuCoreCount: 0,
                    totalMemoryGB: 0,
                    gpuMemoryGB: 0,
                    macOSVersion: "0.0",
                    detectionTimestamp: Date()
                ),
                benchmarkResults: [],
                status: .failed,
                errorMessage: error.localizedDescription
            )
        }
    }
}
