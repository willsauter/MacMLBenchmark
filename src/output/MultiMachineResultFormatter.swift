import Foundation

/// Formats multi-machine benchmark results for display
struct MultiMachineResultFormatter {
    /// Formats multi-machine run results
    static func format(_ run: MultiMachineRun) -> String {
        var output = "\n"
        output += String(repeating: "=", count: 60)
        output += "\nMulti-Machine Benchmark Results"
        output += "\n" + String(repeating: "=", count: 60)
        output += "\n"

        // Summary
        let successCount = run.results.values.filter { $0.status == .success }.count
        output += "\nMachines: \(run.results.count) total, \(successCount) successful\n"

        // Results by task
        for taskName in run.selectedTasks.sorted() {
            output += "\n" + formatTaskComparison(taskName: taskName, run: run)
        }

        return output
    }

    /// Formats comparison for a single task across machines
    private static func formatTaskComparison(taskName: String, run: MultiMachineRun) -> String {
        var output = "\nTask: \(taskName)\n"
        output += String(repeating: "-", count: 40) + "\n"

        var machineResults: [(String, BenchmarkResult?)] = []

        for (machineId, machineResult) in run.results.sorted(by: { $0.key < $1.key }) {
            let result = machineResult.benchmarkResults.first { $0.taskName == taskName }
            machineResults.append((machineResult.machineName, result))
        }

        // Find fastest
        let validResults = machineResults.compactMap { $0.1 }
        let fastest = validResults.max { $0.metrics.throughputOpsPerSec < $1.metrics.throughputOpsPerSec }

        for (machineName, result) in machineResults {
            output += "\n\(machineName):\n"

            if let res = result {
                let isFastest = fastest?.metrics.throughputOpsPerSec == res.metrics.throughputOpsPerSec
                let marker = isFastest ? " 🏆" : ""

                output += "  Throughput: \(String(format: "%.0f", res.metrics.throughputOpsPerSec)) ops/sec\(marker)\n"
                output += "  Latency: \(String(format: "%.2f", res.metrics.latencyMs)) ms\n"
                output += "  GPU Utilization: \(String(format: "%.0f", res.metrics.gpuUtilizationPercent))%\n"
                output += "  Memory: \(res.metrics.peakMemoryUsageMB) MB\n"
            } else {
                output += "  Status: Failed or not executed\n"
            }
        }

        return output
    }
}
