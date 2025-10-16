import XCTest
@testable import MacMLBench

final class ExporterTests: XCTestCase {
    func testJSONExportFormat() throws {
        // Create test result
        let hardware = HardwareProfile(
            modelName: "Test Mac",
            chipIdentifier: "M2 Max",
            gpuCoreCount: 38,
            totalMemoryGB: 32,
            gpuMemoryGB: 16,
            macOSVersion: "14.0",
            detectionTimestamp: Date()
        )

        let config = BenchmarkConfiguration(
            selectedTasks: ["test"],
            parameterOverrides: [:],
            hardware: hardware
        )

        let metrics = PerformanceMetrics(
            throughputOpsPerSec: 100.0,
            latencyMs: 10.0,
            gpuUtilizationPercent: 95.0,
            peakMemoryUsageMB: 2048,
            averageMemoryUsageMB: 1856,
            iterationsCompleted: 1000
        )

        let result = BenchmarkResult(
            configuration: config,
            taskName: "test",
            startTimestamp: Date(),
            endTimestamp: Date().addingTimeInterval(10),
            metrics: metrics,
            status: .success,
            errorMessage: nil,
            thermalState: .nominal
        )

        // Export to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let jsonPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).json").path

        try JSONExporter.export(results: [result], to: jsonPath)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsonPath))

        // Verify JSON is valid
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([String: AnyCodable].self, from: jsonData)

        XCTAssertNotNil(decoded)

        // Cleanup
        try? FileManager.default.removeItem(atPath: jsonPath)
    }

    func testCSVExportFormat() throws {
        // Create test result
        let hardware = HardwareProfile(
            modelName: "Test Mac",
            chipIdentifier: "M2 Max",
            gpuCoreCount: 38,
            totalMemoryGB: 32,
            gpuMemoryGB: 16,
            macOSVersion: "14.0",
            detectionTimestamp: Date()
        )

        let config = BenchmarkConfiguration(
            selectedTasks: ["test"],
            parameterOverrides: [:],
            hardware: hardware
        )

        let metrics = PerformanceMetrics(
            throughputOpsPerSec: 100.0,
            latencyMs: 10.0,
            gpuUtilizationPercent: 95.0,
            peakMemoryUsageMB: 2048,
            averageMemoryUsageMB: 1856,
            iterationsCompleted: 1000
        )

        let result = BenchmarkResult(
            configuration: config,
            taskName: "test",
            startTimestamp: Date(),
            endTimestamp: Date().addingTimeInterval(10),
            metrics: metrics,
            status: .success,
            errorMessage: nil,
            thermalState: .nominal
        )

        // Export to temporary CSV
        let tempDir = FileManager.default.temporaryDirectory
        let csvPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).csv").path

        try CSVExporter.export(results: [result], to: csvPath)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: csvPath))

        // Verify CSV has header and data
        let csvContent = try String(contentsOfFile: csvPath)
        let lines = csvContent.split(separator: "\n")
        XCTAssertGreaterThanOrEqual(lines.count, 2)  // Header + at least one data row
        XCTAssertTrue(lines[0].contains("timestamp"))
        XCTAssertTrue(lines[0].contains("throughput_ops_sec"))

        // Cleanup
        try? FileManager.default.removeItem(atPath: csvPath)
    }
}
