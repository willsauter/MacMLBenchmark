import XCTest
import Metal
@testable import MacMLBench

final class MetricsCollectorTests: XCTestCase {
    func testThroughputCalculation() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal not available on this system")
        }

        let collector = MetricsCollector(device: device)

        // Simulate 100 iterations over 10 seconds
        for _ in 0..<100 {
            collector.recordIteration(gpuTime: 0.05)  // 50ms per iteration
        }

        let metrics = try collector.calculateMetrics(wallClockDuration: 10.0)

        // Verify throughput
        XCTAssertEqual(metrics.iterationsCompleted, 100)
        XCTAssertEqual(metrics.throughputOpsPerSec, 10.0, accuracy: 0.1)  // 100 ops / 10 sec = 10 ops/sec

        // Verify latency
        XCTAssertEqual(metrics.latencyMs, 50.0, accuracy: 0.1)  // 50ms average

        // Verify GPU utilization
        let expectedUtil = (5.0 / 10.0) * 100.0  // 5 seconds GPU time / 10 seconds wall time
        XCTAssertEqual(metrics.gpuUtilizationPercent, expectedUtil, accuracy: 1.0)
    }

    func testNoIterations() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal not available on this system")
        }

        let collector = MetricsCollector(device: device)

        // Try to calculate metrics without any iterations
        XCTAssertThrowsError(try collector.calculateMetrics(wallClockDuration: 10.0)) { error in
            XCTAssertTrue(error is MetricsError)
        }
    }
}
