import Foundation
import Metal

/// Collects GPU performance metrics during benchmark execution
class MetricsCollector {
    private var iterationCount: Int = 0
    private var totalGPUTime: TimeInterval = 0
    private var peakMemoryUsage: Int = 0
    private var memoryUsageSamples: [Int] = []
    private let device: MTLDevice

    init(device: MTLDevice) {
        self.device = device
    }

    /// Records completion of one benchmark iteration
    func recordIteration(gpuTime: TimeInterval) {
        iterationCount += 1
        totalGPUTime += gpuTime

        // Sample memory usage
        if #available(macOS 13.0, *) {
            let currentMemory = Int(device.currentAllocatedSize / (1024 * 1024))  // MB
            memoryUsageSamples.append(currentMemory)
            peakMemoryUsage = max(peakMemoryUsage, currentMemory)
        }
    }

    /// Calculates final performance metrics
    func calculateMetrics(wallClockDuration: TimeInterval) throws -> PerformanceMetrics {
        guard iterationCount > 0 else {
            throw MetricsError.calculationFailed("No iterations completed")
        }

        let throughputOpsPerSec = Double(iterationCount) / wallClockDuration
        let latencyMs = (totalGPUTime / Double(iterationCount)) * 1000.0  // Convert to ms
        let gpuUtilizationPercent = (totalGPUTime / wallClockDuration) * 100.0

        let averageMemoryUsageMB: Int
        if memoryUsageSamples.isEmpty {
            // Fallback if memory sampling not available
            averageMemoryUsageMB = 0
            peakMemoryUsage = 0
        } else {
            averageMemoryUsageMB = memoryUsageSamples.reduce(0, +) / memoryUsageSamples.count
        }

        let metrics = PerformanceMetrics(
            throughputOpsPerSec: throughputOpsPerSec,
            latencyMs: latencyMs,
            gpuUtilizationPercent: min(gpuUtilizationPercent, 100.0),  // Cap at 100%
            peakMemoryUsageMB: peakMemoryUsage,
            averageMemoryUsageMB: averageMemoryUsageMB,
            iterationsCompleted: iterationCount
        )

        try metrics.validate()
        return metrics
    }

    /// Resets all collected metrics
    func reset() {
        iterationCount = 0
        totalGPUTime = 0
        peakMemoryUsage = 0
        memoryUsageSamples.removeAll()
    }
}
