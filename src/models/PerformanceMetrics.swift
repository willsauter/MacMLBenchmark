import Foundation

/// Performance metrics collected during benchmark execution
struct PerformanceMetrics: Codable {
    let throughputOpsPerSec: Double      // Operations completed per second
    let latencyMs: Double                 // Milliseconds per operation
    let gpuUtilizationPercent: Double     // GPU busy percentage (0-100)
    let peakMemoryUsageMB: Int            // Peak GPU memory used (MB)
    let averageMemoryUsageMB: Int         // Average GPU memory during run (MB)
    let iterationsCompleted: Int          // Total operations completed

    /// Validates that all metrics are within reasonable ranges
    func validate() throws {
        guard throughputOpsPerSec >= 0 else {
            throw MetricsError.negativeValue("throughputOpsPerSec", throughputOpsPerSec)
        }
        guard latencyMs >= 0 else {
            throw MetricsError.negativeValue("latencyMs", latencyMs)
        }
        guard gpuUtilizationPercent >= 0 && gpuUtilizationPercent <= 100 else {
            throw MetricsError.outOfRange("gpuUtilizationPercent", gpuUtilizationPercent, min: 0, max: 100)
        }
        guard peakMemoryUsageMB >= 0 else {
            throw MetricsError.negativeValue("peakMemoryUsageMB", Double(peakMemoryUsageMB))
        }
        guard averageMemoryUsageMB >= 0 else {
            throw MetricsError.negativeValue("averageMemoryUsageMB", Double(averageMemoryUsageMB))
        }
        guard iterationsCompleted >= 0 else {
            throw MetricsError.negativeValue("iterationsCompleted", Double(iterationsCompleted))
        }
    }
}

enum MetricsError: Error, LocalizedError {
    case negativeValue(String, Double)
    case outOfRange(String, Double, min: Double, max: Double)
    case calculationFailed(String)

    var errorDescription: String? {
        switch self {
        case .negativeValue(let metric, let value):
            return "Invalid metric '\(metric)': negative value \(value)"
        case .outOfRange(let metric, let value, let min, let max):
            return "Invalid metric '\(metric)': value \(value) out of range [\(min), \(max)]"
        case .calculationFailed(let reason):
            return "Metrics calculation failed: \(reason)"
        }
    }
}
