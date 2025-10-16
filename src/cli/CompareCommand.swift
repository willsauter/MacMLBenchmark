import Foundation
import ArgumentParser

/// CLI command to compare benchmark results
struct CompareCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "compare",
        abstract: "Compare results from multiple benchmark runs"
    )

    @Argument(help: "Paths to result files (JSON format, minimum 2 files)")
    var files: [String]

    @Option(name: .long, help: "Export comparison to file")
    var output: String?

    mutating func validate() throws {
        guard files.count >= 2 else {
            throw ValidationError("Must provide at least 2 result files to compare")
        }

        // Validate files exist and are readable
        for file in files {
            guard FileManager.default.fileExists(atPath: file) else {
                throw ValidationError("File not found: \(file)")
            }
        }
    }

    func run() throws {
        print("Benchmark Comparison")
        print(String(repeating: "=", count: 20))
        print()

        // Load all result files (T065)
        var allResults: [[ResultInfo]] = []
        var hardwareInfos: [String] = []

        for (index, filePath) in files.enumerated() {
            do {
                let url = URL(fileURLWithPath: filePath)
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                // Parse JSON structure matching export format
                let exportData = try decoder.decode(BenchmarkRunExportWrapper.self, from: data)
                allResults.append(exportData.benchmarkRun.results)

                // Display file info
                let formatter = ISO8601DateFormatter()
                let timestamp = formatter.string(from: exportData.benchmarkRun.timestamp)
                let hw = exportData.benchmarkRun.hardware
                let info = "\(filePath) (\(timestamp), \(hw.chipIdentifier), \(hw.gpuCoreCount) GPU cores)"
                hardwareInfos.append(info)
                print("  Run \(index + 1): \(info)")
            } catch {
                throw ValidationError("Failed to load \(filePath): \(error.localizedDescription)")
            }
        }

        print()

        // Match tasks by name across files (T066)
        var taskNames = Set<String>()
        for results in allResults {
            for result in results {
                taskNames.insert(result.taskName)
            }
        }

        // Compare each task (T067-T068)
        for taskName in taskNames.sorted() {
            var taskResults: [ResultInfo] = []

            for results in allResults {
                if let result = results.first(where: { $0.taskName == taskName }) {
                    taskResults.append(result)
                }
            }

            if taskResults.count >= 2 {
                printTaskComparison(taskName: taskName, results: taskResults)
            }
        }

        // Summary
        print()
        print("Summary:")
        print("  Tasks compared: \(taskNames.count)")
    }

    /// Prints comparison for a single task across multiple runs
    private func printTaskComparison(taskName: String, results: [ResultInfo]) {
        guard results.count >= 2 else { return }

        print("Task: \(taskName)")
        print(String(repeating: "-", count: 21))

        let baseline = results[0]
        let current = results[1]

        // Compare throughput
        let throughputDelta = ((current.metrics.throughputOpsPerSec - baseline.metrics.throughputOpsPerSec) / baseline.metrics.throughputOpsPerSec) * 100
        let throughputArrow = throughputDelta > 10 ? " ↑" : (throughputDelta < -10 ? " ↓" : "")
        print(String(format: "  Throughput:     %.0f ops/sec → %.0f ops/sec  (%+.1f%%)%@",
                     baseline.metrics.throughputOpsPerSec,
                     current.metrics.throughputOpsPerSec,
                     throughputDelta,
                     throughputArrow))

        // Compare latency
        let latencyDelta = ((current.metrics.latencyMs - baseline.metrics.latencyMs) / baseline.metrics.latencyMs) * 100
        let latencyArrow = latencyDelta < -10 ? " ↓" : (latencyDelta > 10 ? " ↑" : "")
        print(String(format: "  Latency:        %.2f ms → %.2f ms                (%+.1f%%)%@",
                     baseline.metrics.latencyMs,
                     current.metrics.latencyMs,
                     latencyDelta,
                     latencyArrow))

        // Compare GPU utilization
        let gpuUtilDelta = current.metrics.gpuUtilizationPercent - baseline.metrics.gpuUtilizationPercent
        print(String(format: "  GPU Util:       %.0f%% → %.0f%%                        (%+.1f%%)",
                     baseline.metrics.gpuUtilizationPercent,
                     current.metrics.gpuUtilizationPercent,
                     gpuUtilDelta))

        // Compare memory
        let memoryChange = current.metrics.peakMemoryUsageMB == baseline.metrics.peakMemoryUsageMB ? "(no change)" : ""
        print(String(format: "  Peak Memory:    %d MB → %d MB              %@",
                     baseline.metrics.peakMemoryUsageMB,
                     current.metrics.peakMemoryUsageMB,
                     memoryChange))

        print()
    }
}

// JSON import structures
private struct BenchmarkRunExportWrapper: Codable {
    let benchmarkRun: BenchmarkRunDataImport
}

private struct BenchmarkRunDataImport: Codable {
    let id: UUID
    let timestamp: Date
    let hardware: HardwareInfoImport
    let results: [ResultInfo]
}

private struct HardwareInfoImport: Codable {
    let modelName: String
    let chipIdentifier: String
    let gpuCoreCount: Int
    let totalMemoryGB: Int
    let macOSVersion: String
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
}

private struct MetricsInfo: Codable {
    let throughputOpsPerSec: Double
    let latencyMs: Double
    let gpuUtilizationPercent: Double
    let peakMemoryUsageMB: Int
    let averageMemoryUsageMB: Int
    let iterationsCompleted: Int
}

