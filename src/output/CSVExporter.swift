import Foundation

/// Exports benchmark results to CSV format
struct CSVExporter {
    /// Exports results to CSV file
    static func export(results: [BenchmarkResult], to filePath: String) throws {
        var lines: [String] = []

        // Header
        lines.append("timestamp,hardware_model,chip,gpu_cores,task_name,duration_sec,throughput_ops_sec,latency_ms,gpu_util_%,peak_memory_mb,avg_memory_mb,iterations,status,thermal_state")

        // Data rows
        for result in results {
            let row = [
                ISO8601DateFormatter().string(from: result.startTimestamp),
                escapeCSV(result.configuration.hardware.modelName),
                escapeCSV(result.configuration.hardware.chipIdentifier),
                String(result.configuration.hardware.gpuCoreCount),
                escapeCSV(result.taskName),
                String(format: "%.2f", result.duration),
                String(format: "%.1f", result.metrics.throughputOpsPerSec),
                String(format: "%.2f", result.metrics.latencyMs),
                String(format: "%.1f", result.metrics.gpuUtilizationPercent),
                String(result.metrics.peakMemoryUsageMB),
                String(result.metrics.averageMemoryUsageMB),
                String(result.metrics.iterationsCompleted),
                escapeCSV(result.status.rawValue),
                escapeCSV(result.thermalState.rawValue)
            ]
            lines.append(row.joined(separator: ","))
        }

        let csvContent = lines.joined(separator: "\n")

        // Write to file
        let url = URL(fileURLWithPath: filePath)

        // Create directory if needed
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        try csvContent.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Escapes CSV field value
    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
