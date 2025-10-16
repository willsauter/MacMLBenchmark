import Foundation

/// Exports benchmark results to JSON format
struct JSONExporter {
    /// Exports results to JSON file
    static func export(results: [BenchmarkResult], to filePath: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        // Create export structure
        let exportData = BenchmarkRunExport(
            benchmarkRun: BenchmarkRunData(results: results)
        )

        let jsonData = try encoder.encode(exportData)

        // Write to file
        let url = URL(fileURLWithPath: filePath)

        // Create directory if it doesn't exist
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        try jsonData.write(to: url)
    }
}

/// Export data structure for JSON
private struct BenchmarkRunExport: Codable {
    let benchmarkRun: BenchmarkRunData
}

private struct BenchmarkRunData: Codable {
    let id: UUID
    let timestamp: Date
    let hardware: HardwareInfo
    let configuration: ConfigurationInfo
    let results: [ResultInfo]

    init(results: [BenchmarkResult]) {
        self.id = UUID()
        self.timestamp = Date()

        // Extract hardware from first result
        if let first = results.first {
            self.hardware = HardwareInfo(from: first.configuration.hardware)
            self.configuration = ConfigurationInfo(from: first.configuration)
        } else {
            self.hardware = HardwareInfo(modelName: "Unknown", chipIdentifier: "Unknown", gpuCoreCount: 0, totalMemoryGB: 0, macOSVersion: "Unknown")
            self.configuration = ConfigurationInfo(duration: 0, customParameters: [:])
        }

        self.results = results.map { ResultInfo(from: $0) }
    }
}

private struct HardwareInfo: Codable {
    let modelName: String
    let chipIdentifier: String
    let gpuCoreCount: Int
    let totalMemoryGB: Int
    let macOSVersion: String

    init(from profile: HardwareProfile) {
        self.modelName = profile.modelName
        self.chipIdentifier = profile.chipIdentifier
        self.gpuCoreCount = profile.gpuCoreCount
        self.totalMemoryGB = profile.totalMemoryGB
        self.macOSVersion = profile.macOSVersion
    }

    init(modelName: String, chipIdentifier: String, gpuCoreCount: Int, totalMemoryGB: Int, macOSVersion: String) {
        self.modelName = modelName
        self.chipIdentifier = chipIdentifier
        self.gpuCoreCount = gpuCoreCount
        self.totalMemoryGB = totalMemoryGB
        self.macOSVersion = macOSVersion
    }
}

private struct ConfigurationInfo: Codable {
    let duration: Int
    let customParameters: [String: [String: AnyCodable]]

    init(from config: BenchmarkConfiguration) {
        // Extract common duration if present
        self.duration = 10  // Default, will be overridden by actual params
        self.customParameters = config.parameterOverrides
    }

    init(duration: Int, customParameters: [String: [String: AnyCodable]]) {
        self.duration = duration
        self.customParameters = customParameters
    }
}

private struct ResultInfo: Codable {
    let id: UUID
    let taskName: String
    let startTimestamp: Date
    let endTimestamp: Date
    let durationSeconds: TimeInterval
    let metrics: MetricsInfo
    let status: String
    let thermalState: String
    let errorMessage: String?

    init(from result: BenchmarkResult) {
        self.id = result.id
        self.taskName = result.taskName
        self.startTimestamp = result.startTimestamp
        self.endTimestamp = result.endTimestamp
        self.durationSeconds = result.duration
        self.metrics = MetricsInfo(from: result.metrics)
        self.status = result.status.rawValue
        self.thermalState = result.thermalState.rawValue
        self.errorMessage = result.errorMessage
    }
}

private struct MetricsInfo: Codable {
    let throughputOpsPerSec: Double
    let latencyMs: Double
    let gpuUtilizationPercent: Double
    let peakMemoryUsageMB: Int
    let averageMemoryUsageMB: Int
    let iterationsCompleted: Int

    init(from metrics: PerformanceMetrics) {
        self.throughputOpsPerSec = metrics.throughputOpsPerSec
        self.latencyMs = metrics.latencyMs
        self.gpuUtilizationPercent = metrics.gpuUtilizationPercent
        self.peakMemoryUsageMB = metrics.peakMemoryUsageMB
        self.averageMemoryUsageMB = metrics.averageMemoryUsageMB
        self.iterationsCompleted = metrics.iterationsCompleted
    }
}
