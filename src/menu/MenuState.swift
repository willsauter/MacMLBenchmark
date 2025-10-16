import Foundation

/// Tracks current state of interactive menu
class MenuState {
    var selectedTasks: Set<String> = []
    var duration: Int = 10
    var batchSize: Int?
    var threads: Int?
    var size: Int?
    var selectedMachines: Set<UUID> = []  // Remote machine IDs
    var includeLocal: Bool = true

    /// Resets all selections
    func reset() {
        selectedTasks.removeAll()
        duration = 10
        batchSize = nil
        threads = nil
        size = nil
        selectedMachines.removeAll()
        includeLocal = true
    }

    /// Toggles task selection
    func toggleTask(_ taskName: String) {
        if selectedTasks.contains(taskName) {
            selectedTasks.remove(taskName)
        } else {
            selectedTasks.insert(taskName)
        }
    }

    /// Selects all available tasks
    func selectAllTasks(_ taskNames: [String]) {
        selectedTasks = Set(taskNames)
    }

    /// Toggles machine selection
    func toggleMachine(_ machineId: UUID) {
        if selectedMachines.contains(machineId) {
            selectedMachines.remove(machineId)
        } else {
            selectedMachines.insert(machineId)
        }
    }

    /// Gets configuration summary
    func configurationSummary() -> String {
        var summary = "Selected Benchmarks: \(selectedTasks.sorted().joined(separator: ", "))\n"
        summary += "Duration: \(duration)s"

        if let bs = batchSize {
            summary += ", Batch: \(bs)"
        }
        if let s = size {
            summary += ", Size: \(s)"
        }
        if let t = threads {
            summary += ", Threads: \(t)"
        }

        let machineCount = (includeLocal ? 1 : 0) + selectedMachines.count
        summary += "\nMachines: \(machineCount) (\(includeLocal ? "local" : "remote only"))"

        return summary
    }
}
