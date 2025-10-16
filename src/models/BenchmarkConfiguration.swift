import Foundation

/// Represents the settings for a specific benchmark run
struct BenchmarkConfiguration: Codable {
    let id: UUID
    let selectedTasks: [String]
    let parameterOverrides: [String: [String: AnyCodable]]
    let hardware: HardwareProfile
    let createdAt: Date

    init(selectedTasks: [String], parameterOverrides: [String: [String: AnyCodable]] = [:], hardware: HardwareProfile) {
        self.id = UUID()
        self.selectedTasks = selectedTasks
        self.parameterOverrides = parameterOverrides
        self.hardware = hardware
        self.createdAt = Date()
    }

    /// Validates configuration against available tasks
    func validate(availableTasks: [String]) throws {
        for taskName in selectedTasks {
            guard availableTasks.contains(taskName) else {
                throw ConfigurationError.unknownTask(taskName, available: availableTasks)
            }
        }
    }
}

enum ConfigurationError: Error, LocalizedError {
    case unknownTask(String, available: [String])
    case invalidParameterOverride(String, reason: String)

    var errorDescription: String? {
        switch self {
        case .unknownTask(let name, let available):
            return "Unknown task '\(name)'. Available: \(available.joined(separator: ", "))"
        case .invalidParameterOverride(let task, let reason):
            return "Invalid parameter override for task '\(task)': \(reason)"
        }
    }
}
