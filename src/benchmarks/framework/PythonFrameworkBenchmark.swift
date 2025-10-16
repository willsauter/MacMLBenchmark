import Foundation

class PythonFrameworkBenchmark: BaseBenchmark, BenchmarkProtocol {
    let scriptPath: String
    let frameworkName: String

    init(name: String, displayName: String, scriptPath: String, frameworkName: String) {
        self.scriptPath = scriptPath
        self.frameworkName = frameworkName
        super.init(name: name, displayName: displayName)
    }

    func execute(duration: TimeInterval, parameters: [String: Any]) throws -> PerformanceMetrics {
        let size = parameters["size"] as? Int ?? 4096
        let bridge = PythonBridge()

        let output = try bridge.execute(
            script: scriptPath,
            arguments: [String(Int(duration)), String(size)]
        )

        // Parse JSON output
        guard let data = output.data(using: .utf8) else {
            throw BenchmarkError.executionFailed("Failed to get output data")
        }

        let json = try JSONDecoder().decode(PythonBenchmarkResult.self, from: data)

        if let error = json.error {
            throw BenchmarkError.executionFailed(error)
        }

        guard let metrics = json.metrics else {
            throw BenchmarkError.executionFailed("No metrics in output")
        }

        return PerformanceMetrics(
            throughputOpsPerSec: metrics.throughputOpsPerSec,
            latencyMs: metrics.latencyMs,
            gpuUtilizationPercent: metrics.gpuUtilizationPercent,
            peakMemoryUsageMB: metrics.peakMemoryUsageMB,
            averageMemoryUsageMB: metrics.averageMemoryUsageMB,
            iterationsCompleted: metrics.iterationsCompleted
        )
    }

    func validate(parameters: [String: Any]) throws {
        // Basic validation
    }
}

struct PythonBenchmarkResult: Codable {
    let framework: String?
    let error: String?
    let metrics: PythonMetrics?
    let initTimeMs: Double?
}

struct PythonMetrics: Codable {
    let throughputOpsPerSec: Double
    let latencyMs: Double
    let gpuUtilizationPercent: Double
    let peakMemoryUsageMB: Int
    let averageMemoryUsageMB: Int
    let iterationsCompleted: Int
}
