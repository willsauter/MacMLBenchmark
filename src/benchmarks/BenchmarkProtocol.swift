import Foundation
import Metal

/// Protocol that all benchmark tasks must implement
protocol BenchmarkProtocol {
    /// The name identifier for this benchmark
    var name: String { get }

    /// Human-readable display name
    var displayName: String { get }

    /// Setup GPU resources before execution
    func setup(device: MTLDevice, commandQueue: MTLCommandQueue) throws

    /// Execute the benchmark for specified duration with given parameters
    /// Returns performance metrics collected during execution
    func execute(duration: TimeInterval, parameters: [String: Any]) throws -> PerformanceMetrics

    /// Validate that parameters are acceptable for this benchmark
    func validate(parameters: [String: Any]) throws

    /// Cleanup GPU resources after execution
    func cleanup()
}

/// Base implementation with common functionality
class BaseBenchmark {
    let name: String
    let displayName: String
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?

    init(name: String, displayName: String) {
        self.name = name
        self.displayName = displayName
    }

    func setup(device: MTLDevice, commandQueue: MTLCommandQueue) throws {
        self.device = device
        self.commandQueue = commandQueue
    }

    func cleanup() {
        self.device = nil
        self.commandQueue = nil
    }
}
