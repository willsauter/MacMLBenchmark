import Foundation

/// Formats benchmark results for human-readable display
struct ResultFormatter {
    /// Formats a single benchmark result for stdout display
    static func format(_ result: BenchmarkResult) -> String {
        var output = """

        Results:
          Throughput: \(formatNumber(result.metrics.throughputOpsPerSec)) ops/sec
          Latency: \(String(format: "%.2f", result.metrics.latencyMs)) ms/op
          GPU Utilization: \(String(format: "%.0f", result.metrics.gpuUtilizationPercent))%
          Peak Memory: \(formatNumber(Double(result.metrics.peakMemoryUsageMB))) MB
          Iterations: \(formatNumber(Double(result.metrics.iterationsCompleted)))
          Status: \(result.status.rawValue.capitalized)
          Thermal State: \(result.thermalState.rawValue.capitalized)

        Time: \(String(format: "%.2f", result.duration)) seconds
        """

        if let errorMessage = result.errorMessage {
            output += "\nError: \(errorMessage)"
        }

        return output
    }

    /// Formats hardware profile for display
    static func formatHardware(_ profile: HardwareProfile) -> String {
        """
        Hardware Profile:
          Model: \(profile.modelName)
          Chip: \(profile.chipIdentifier)
          GPU Cores: \(profile.gpuCoreCount)
          Memory: \(profile.totalMemoryGB) GB
          macOS: \(profile.macOSVersion)
        """
    }

    /// Formats benchmark configuration for display
    static func formatConfiguration(_ config: [String: Any]) -> String {
        var lines: [String] = []

        if let duration = config["duration"] as? Int {
            lines.append("  Duration: \(duration) seconds")
        }
        if let batchSize = config["batch_size"] as? Int {
            lines.append("  Batch Size: \(batchSize)")
        }
        if let size = config["size"] as? Int {
            lines.append("  Matrix Size: \(size)x\(size)")
        }
        if let threads = config["threads"] as? Int {
            lines.append("  Threads: \(threads)")
        }

        return lines.isEmpty ? "  Default configuration" : lines.joined(separator: "\n")
    }

    /// Formats a progress indicator
    static func formatProgress(percent: Double, elapsed: TimeInterval) -> String {
        let barLength = 20
        let filled = Int(percent / 100.0 * Double(barLength))
        let bar = String(repeating: "#", count: filled) + String(repeating: "-", count: barLength - filled)
        return String(format: "Progress: [%@] %.0f%% (%.1fs elapsed)", bar, percent, elapsed)
    }

    /// Formats a benchmark header
    static func formatHeader(_ taskDisplayName: String) -> String {
        let separator = String(repeating: "-", count: 40)
        return """

        Running Benchmark: \(taskDisplayName)
        \(separator)
        """
    }

    /// Formats application banner
    static func formatBanner() -> String {
        let separator = String(repeating: "=", count: 22)
        return """
        Mac ML Benchmark Suite
        \(separator)
        """
    }

    /// Formats a number with comma separators
    private static func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }
}
