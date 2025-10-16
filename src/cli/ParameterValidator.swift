import Foundation

/// Validates benchmark parameters before execution
struct ParameterValidator {
    /// Validates all parameters for a benchmark task
    static func validate(
        parameters: [String: Any],
        against task: BenchmarkTask,
        hardware: HardwareProfile
    ) throws {
        // Validate each parameter against constraints
        for (key, value) in parameters {
            if let constraint = task.parameterConstraints[key] {
                try constraint.validate(value, parameterName: key)
            }
        }

        // Validate cross-parameter constraints
        try validateCrossParameters(parameters, task: task, hardware: hardware)

        // Validate resource requirements
        if let requirements = task.resourceRequirements {
            try validateResourceRequirements(requirements, against: hardware)
        }
    }

    /// Validates cross-parameter constraints
    private static func validateCrossParameters(
        _ parameters: [String: Any],
        task: BenchmarkTask,
        hardware: HardwareProfile
    ) throws {
        // Check batch size * element size doesn't exceed available memory
        if let batchSize = parameters["batch_size"] as? Int,
           let size = parameters["size"] as? Int {
            // Rough estimate: 4 bytes per element (Float32)
            let estimatedMemoryMB = (batchSize * size * size * 4) / (1024 * 1024)
            let availableMemoryMB = hardware.gpuMemoryGB * 1024

            if estimatedMemoryMB > availableMemoryMB {
                throw ParameterError.constraintViolation(
                    "memory",
                    message: "Estimated memory usage (\(estimatedMemoryMB) MB) exceeds available GPU memory (\(availableMemoryMB) MB). Try reducing --batch-size or --size."
                )
            }
        }

        // Validate thread count doesn't exceed CPU cores
        if let threads = parameters["threads"] as? Int {
            let cpuCores = ProcessInfo.processInfo.processorCount
            if threads > cpuCores {
                throw ParameterError.constraintViolation(
                    "threads",
                    message: "Thread count (\(threads)) exceeds available CPU cores (\(cpuCores)). Maximum: \(cpuCores)."
                )
            }
        }
    }

    /// Validates resource requirements against hardware
    private static func validateResourceRequirements(
        _ requirements: ResourceRequirements,
        against hardware: HardwareProfile
    ) throws {
        guard hardware.totalMemoryGB >= requirements.minMemoryGB else {
            throw ParameterError.constraintViolation(
                "memory",
                message: "Task requires minimum \(requirements.minMemoryGB) GB memory, but only \(hardware.totalMemoryGB) GB available."
            )
        }

        guard hardware.gpuCoreCount >= requirements.minGPUCores else {
            throw ParameterError.constraintViolation(
                "gpu_cores",
                message: "Task requires minimum \(requirements.minGPUCores) GPU cores, but only \(hardware.gpuCoreCount) cores available."
            )
        }

        // Parse version strings and compare
        let hardwareVersion = parseVersion(hardware.macOSVersion)
        let requiredVersion = parseVersion(requirements.minMacOSVersion)

        if compareVersions(hardwareVersion, requiredVersion) == .orderedAscending {
            throw ParameterError.constraintViolation(
                "macos_version",
                message: "Task requires macOS \(requirements.minMacOSVersion) or later, but running \(hardware.macOSVersion)."
            )
        }
    }

    private static func parseVersion(_ version: String) -> [Int] {
        return version.split(separator: ".").compactMap { Int($0) }
    }

    private static func compareVersions(_ v1: [Int], _ v2: [Int]) -> ComparisonResult {
        for i in 0..<max(v1.count, v2.count) {
            let n1 = i < v1.count ? v1[i] : 0
            let n2 = i < v2.count ? v2[i] : 0

            if n1 < n2 { return .orderedAscending }
            if n1 > n2 { return .orderedDescending }
        }
        return .orderedSame
    }

    /// Formats helpful error message for parameter validation failures
    static func formatError(_ error: Error, taskName: String) -> String {
        if let paramError = error as? ParameterError {
            var message = "Error: \(paramError.localizedDescription)\n\n"

            // Add helpful suggestions based on error type
            switch paramError {
            case .outOfRange(let name, _, let min, let max):
                message += "The --\(name) parameter must be between \(min) and \(max).\n\n"
                message += "Example:\n"
                message += "  macmlbench run \(taskName) --\(name) \((min + max) / 2)\n"

            case .constraintViolation(let name, _):
                if name.contains("memory") {
                    message += "\nSuggestions:\n"
                    message += "  - Reduce --batch-size (try half the current value)\n"
                    message += "  - Reduce --size (try 2048 or 4096)\n"
                    message += "  - Close other GPU-intensive applications\n"
                } else if name == "threads" {
                    message += "\nSuggestion:\n"
                    message += "  - Use --threads \(ProcessInfo.processInfo.processorCount) or less\n"
                }

            default:
                break
            }

            return message
        }

        return "Validation error: \(error.localizedDescription)"
    }
}
