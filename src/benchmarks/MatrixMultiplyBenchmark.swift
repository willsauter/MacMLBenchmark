import Foundation
import Metal
import MetalPerformanceShaders

/// Matrix multiplication benchmark using Metal Performance Shaders
class MatrixMultiplyBenchmark: BaseBenchmark, BenchmarkProtocol {
    private var matrixA: MPSMatrix?
    private var matrixB: MPSMatrix?
    private var matrixC: MPSMatrix?
    private var multiplication: MPSMatrixMultiplication?

    init() {
        super.init(name: "matrix-multiply", displayName: "Matrix Multiplication")
    }

    override func setup(device: MTLDevice, commandQueue: MTLCommandQueue) throws {
        try super.setup(device: device, commandQueue: commandQueue)
        // GPU resources will be allocated per execution with specific size
    }

    func execute(duration: TimeInterval, parameters: [String: Any]) throws -> PerformanceMetrics {
        guard let device = self.device else {
            throw BenchmarkError.notSetup("Device not initialized")
        }

        guard let commandQueue = self.commandQueue else {
            throw BenchmarkError.notSetup("Command queue not initialized")
        }

        // Extract parameters
        let size = parameters["size"] as? Int ?? 4096
        let _ = parameters["batch_size"] as? Int ?? 32  // Reserved for future batching support

        // Create metrics collector
        let metricsCollector = MetricsCollector(device: device)

        // Setup matrices
        let rowsA = size
        let columnsA = size
        let columnsB = size

        let matrixDesc = MPSMatrixDescriptor(
            rows: rowsA,
            columns: columnsA,
            rowBytes: columnsA * MemoryLayout<Float>.stride,
            dataType: .float32
        )

        // Allocate buffers
        guard let bufferA = device.makeBuffer(length: rowsA * columnsA * MemoryLayout<Float>.size, options: .storageModeShared),
              let bufferB = device.makeBuffer(length: columnsA * columnsB * MemoryLayout<Float>.size, options: .storageModeShared),
              let bufferC = device.makeBuffer(length: rowsA * columnsB * MemoryLayout<Float>.size, options: .storageModeShared) else {
            throw BenchmarkError.allocationFailed("Failed to allocate matrix buffers")
        }

        // Initialize with random data
        let dataA = bufferA.contents().bindMemory(to: Float.self, capacity: rowsA * columnsA)
        let dataB = bufferB.contents().bindMemory(to: Float.self, capacity: columnsA * columnsB)

        for i in 0..<(rowsA * columnsA) {
            dataA[i] = Float.random(in: -1.0...1.0)
        }
        for i in 0..<(columnsA * columnsB) {
            dataB[i] = Float.random(in: -1.0...1.0)
        }

        // Create MPS matrices
        let matrixA = MPSMatrix(buffer: bufferA, descriptor: matrixDesc)
        let matrixB = MPSMatrix(buffer: bufferB, descriptor: matrixDesc)
        let matrixC = MPSMatrix(buffer: bufferC, descriptor: matrixDesc)

        // Create matrix multiplication kernel
        let multiplication = MPSMatrixMultiplication(
            device: device,
            transposeLeft: false,
            transposeRight: false,
            resultRows: rowsA,
            resultColumns: columnsB,
            interiorColumns: columnsA,
            alpha: 1.0,
            beta: 0.0
        )

        // Execute benchmark loop for specified duration
        let startTime = Date()
        var shouldContinue = true

        while shouldContinue {
            let commandBuffer = commandQueue.makeCommandBuffer()!

            let iterationStartTime = Date()

            // Encode matrix multiplication
            multiplication.encode(
                commandBuffer: commandBuffer,
                leftMatrix: matrixA,
                rightMatrix: matrixB,
                resultMatrix: matrixC
            )

            // Add completion handler to measure GPU time
            commandBuffer.addCompletedHandler { _ in
                let gpuTime = Date().timeIntervalSince(iterationStartTime)
                metricsCollector.recordIteration(gpuTime: gpuTime)
            }

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

            // Check if duration elapsed
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= duration {
                shouldContinue = false
            }
        }

        // Calculate final metrics
        let wallClockDuration = Date().timeIntervalSince(startTime)
        return try metricsCollector.calculateMetrics(wallClockDuration: wallClockDuration)
    }

    func validate(parameters: [String: Any]) throws {
        // Validate size parameter
        if let size = parameters["size"] as? Int {
            guard size >= 128 && size <= 8192 else {
                throw ParameterError.outOfRange("size", value: size, min: 128, max: 8192)
            }
        }

        // Validate batch size
        if let batchSize = parameters["batch_size"] as? Int {
            guard batchSize >= 1 && batchSize <= 1024 else {
                throw ParameterError.outOfRange("batch_size", value: batchSize, min: 1, max: 1024)
            }
        }
    }

    override func cleanup() {
        matrixA = nil
        matrixB = nil
        matrixC = nil
        multiplication = nil
        super.cleanup()
    }
}

enum BenchmarkError: Error, LocalizedError {
    case notSetup(String)
    case allocationFailed(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notSetup(let reason):
            return "Benchmark not setup: \(reason)"
        case .allocationFailed(let reason):
            return "GPU allocation failed: \(reason)"
        case .executionFailed(let reason):
            return "Benchmark execution failed: \(reason)"
        }
    }
}
