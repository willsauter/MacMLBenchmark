import Foundation

/// Executes benchmarks on remote machines via SSH
class RemoteExecutor {
    let sshClient: SSHClient

    init(machine: RemoteMachine) {
        self.sshClient = SSHClient(machine: machine)
    }

    /// Executes benchmark on remote machine and returns results
    func execute(tasks: [String], parameterOverrides: [String: [String: AnyCodable]]) async throws -> [BenchmarkResult] {
        // Build command
        let taskNames = tasks.joined(separator: " ")
        let remotePath = sshClient.machine.deploymentPath
        let resultsPath = "~/remote-results-\(UUID().uuidString).json"

        // Build parameter string
        var paramString = ""
        if let firstTask = tasks.first, let params = parameterOverrides[firstTask] {
            if let duration = params["duration"]?.value as? Int {
                paramString += " --duration \(duration)"
            }
            if let size = params["size"]?.value as? Int {
                paramString += " --size \(size)"
            }
            if let batchSize = params["batch_size"]?.value as? Int {
                paramString += " --batch-size \(batchSize)"
            }
            if let threads = params["threads"]?.value as? Int {
                paramString += " --threads \(threads)"
            }
        }

        let command = "\(remotePath) run \(taskNames)\(paramString) --output \(resultsPath)"

        print("Executing on \(sshClient.machine.name): \(taskNames)")

        // Execute remotely
        let result = try sshClient.executeCommand(command, timeout: 600)  // 10 min max

        guard result.isSuccess else {
            throw SSHError.executionFailed(command, result.stderr)
        }

        // Download results
        let localPath = "results/remote-\(sshClient.machine.hostname)-\(UUID().uuidString).json"
        try sshClient.downloadFile(remotePath: resultsPath, localPath: localPath, timeout: 30)

        // Clean up remote file
        _ = try? sshClient.executeCommand("rm \(resultsPath)")

        // Parse results
        let url = URL(fileURLWithPath: localPath)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Parse matching export format
        let exportData = try decoder.decode(BenchmarkRunExportWrapper.self, from: data)
        let results = exportData.benchmarkRun.results.map { resultInfo in
            // Convert to BenchmarkResult
            // Note: This is a simplified conversion
            return convertToBenchmarkResult(resultInfo, hardware: sshClient.machine.hardwareProfile ?? HardwareProfile(
                modelName: "Remote",
                chipIdentifier: "Unknown",
                gpuCoreCount: 0,
                totalMemoryGB: 0,
                gpuMemoryGB: 0,
                macOSVersion: "0.0",
                detectionTimestamp: Date()
            ))
        }

        return results
    }

    private func convertToBenchmarkResult(_ info: ResultInfo, hardware: HardwareProfile) -> BenchmarkResult {
        let config = BenchmarkConfiguration(selectedTasks: [info.taskName], hardware: hardware)

        let metrics = PerformanceMetrics(
            throughputOpsPerSec: info.metrics.throughputOpsPerSec,
            latencyMs: info.metrics.latencyMs,
            gpuUtilizationPercent: info.metrics.gpuUtilizationPercent,
            peakMemoryUsageMB: info.metrics.peakMemoryUsageMB,
            averageMemoryUsageMB: info.metrics.averageMemoryUsageMB,
            iterationsCompleted: info.metrics.iterationsCompleted
        )

        let status = ResultStatus(rawValue: info.status) ?? .success
        let thermalState = ThermalState(rawValue: info.thermalState) ?? .nominal

        return BenchmarkResult(
            configuration: config,
            taskName: info.taskName,
            startTimestamp: info.startTimestamp,
            endTimestamp: info.endTimestamp,
            metrics: metrics,
            status: status,
            errorMessage: info.errorMessage,
            thermalState: thermalState
        )
    }
}

// JSON import structures (reused from CompareCommand)
private struct BenchmarkRunExportWrapper: Codable {
    let benchmarkRun: BenchmarkRunDataImport
}

private struct BenchmarkRunDataImport: Codable {
    let results: [ResultInfo]
}

private struct ResultInfo: Codable {
    let taskName: String
    let startTimestamp: Date
    let endTimestamp: Date
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
