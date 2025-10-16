import Foundation

/// Results from a single machine in multi-machine run
struct MachineResult: Codable {
    let machineId: String
    let machineName: String
    let hardware: HardwareProfile
    let benchmarkResults: [BenchmarkResult]
    let status: ExecutionStatus
    let errorMessage: String?

    init(
        machineId: String,
        machineName: String,
        hardware: HardwareProfile,
        benchmarkResults: [BenchmarkResult],
        status: ExecutionStatus,
        errorMessage: String? = nil
    ) {
        self.machineId = machineId
        self.machineName = machineName
        self.hardware = hardware
        self.benchmarkResults = benchmarkResults
        self.status = status
        self.errorMessage = errorMessage
    }
}
