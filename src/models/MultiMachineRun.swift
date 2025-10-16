import Foundation

/// Represents a benchmark run across multiple machines
struct MultiMachineRun: Codable {
    let id: UUID
    let machines: [String]  // Machine IDs
    let selectedTasks: [String]
    let sharedConfiguration: BenchmarkConfiguration
    var results: [String: MachineResult]  // machineId -> result
    let startTime: Date
    var endTime: Date?

    init(machines: [String], selectedTasks: [String], sharedConfiguration: BenchmarkConfiguration) {
        self.id = UUID()
        self.machines = machines
        self.selectedTasks = selectedTasks
        self.sharedConfiguration = sharedConfiguration
        self.results = [:]
        self.startTime = Date()
        self.endTime = nil
    }

    mutating func addResult(_ result: MachineResult, for machineId: String) {
        results[machineId] = result
    }

    mutating func complete() {
        endTime = Date()
    }

    func isComplete() -> Bool {
        return results.count == machines.count
    }
}
