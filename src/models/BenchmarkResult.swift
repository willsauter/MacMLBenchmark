import Foundation

/// Represents the outcome of a benchmark execution
struct BenchmarkResult: Codable {
    let id: UUID
    let configuration: BenchmarkConfiguration
    let taskName: String
    let startTimestamp: Date
    let endTimestamp: Date
    let duration: TimeInterval
    let metrics: PerformanceMetrics
    let status: ResultStatus
    let errorMessage: String?
    let thermalState: ThermalState

    init(
        configuration: BenchmarkConfiguration,
        taskName: String,
        startTimestamp: Date,
        endTimestamp: Date,
        metrics: PerformanceMetrics,
        status: ResultStatus,
        errorMessage: String? = nil,
        thermalState: ThermalState
    ) {
        self.id = UUID()
        self.configuration = configuration
        self.taskName = taskName
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.duration = endTimestamp.timeIntervalSince(startTimestamp)
        self.metrics = metrics
        self.status = status
        self.errorMessage = errorMessage
        self.thermalState = thermalState
    }

    /// Validates result consistency
    func validate() throws {
        // Validate duration matches timestamps
        let calculatedDuration = endTimestamp.timeIntervalSince(startTimestamp)
        let tolerance = 0.001 // 1ms tolerance
        guard abs(duration - calculatedDuration) < tolerance else {
            throw ResultError.durationMismatch(stored: duration, calculated: calculatedDuration)
        }

        // Validate metrics
        try metrics.validate()

        // Validate thermal state consistency
        if thermalState == .serious || thermalState == .critical {
            guard status == .throttled || status == .partiallyCompleted else {
                throw ResultError.thermalStateInconsistent(thermalState, status)
            }
        }
    }
}

enum ResultError: Error, LocalizedError {
    case durationMismatch(stored: TimeInterval, calculated: TimeInterval)
    case thermalStateInconsistent(ThermalState, ResultStatus)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .durationMismatch(let stored, let calculated):
            return "Duration mismatch: stored \(stored)s, calculated \(calculated)s"
        case .thermalStateInconsistent(let thermal, let status):
            return "Thermal state \(thermal) inconsistent with status \(status)"
        case .validationFailed(let reason):
            return "Result validation failed: \(reason)"
        }
    }
}
