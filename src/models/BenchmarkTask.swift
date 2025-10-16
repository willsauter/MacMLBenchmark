import Foundation

/// Represents a specific ML/AI workload to be benchmarked
struct BenchmarkTask: Codable {
    let name: String
    let displayName: String
    let taskType: TaskType
    let description: String
    let defaultParameters: [String: AnyCodable]

    // Runtime-only properties (not encoded)
    var parameterConstraints: [String: ParameterConstraint] = [:]
    var resourceRequirements: ResourceRequirements?

    enum CodingKeys: String, CodingKey {
        case name, displayName, taskType, description, defaultParameters
    }

    /// Validates task parameters against constraints
    func validateParameters(_ parameters: [String: Any]) throws {
        for (key, value) in parameters {
            if let constraint = parameterConstraints[key] {
                try constraint.validate(value, parameterName: key)
            }
        }

        // Validate resource requirements if set
        if let requirements = resourceRequirements {
            try requirements.validate()
        }
    }
}

/// Resource requirements for a benchmark task
struct ResourceRequirements {
    let minMemoryGB: Int
    let minGPUCores: Int
    let minMacOSVersion: String

    func validate() throws {
        // Will be checked against HardwareProfile at runtime
    }
}
