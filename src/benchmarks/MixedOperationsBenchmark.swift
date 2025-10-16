import Foundation
import Metal
import MetalPerformanceShaders

/// Mixed operations benchmark combining matrix multiply, activation, and normalization
class MixedOperationsBenchmark: BaseBenchmark, BenchmarkProtocol {
    init() {
        super.init(name: "mixed-operations", displayName: "Mixed Operations")
    }

    override func setup(device: MTLDevice, commandQueue: MTLCommandQueue) throws {
        try super.setup(device: device, commandQueue: commandQueue)
    }

    func execute(duration: TimeInterval, parameters: [String: Any]) throws -> PerformanceMetrics {
        guard let device = self.device else {
            throw BenchmarkError.notSetup("Device not initialized")
        }

        guard let commandQueue = self.commandQueue else {
            throw BenchmarkError.notSetup("Command queue not initialized")
        }

        // Extract parameters
        let size = parameters["size"] as? Int ?? 2048
        let _ = parameters["batch_size"] as? Int ?? 16

        let metricsCollector = MetricsCollector(device: device)

        // Setup matrices for matmul
        let matrixDesc = MPSMatrixDescriptor(
            rows: size,
            columns: size,
            rowBytes: size * MemoryLayout<Float>.stride,
            dataType: .float32
        )

        guard let bufferA = device.makeBuffer(length: size * size * MemoryLayout<Float>.size, options: .storageModeShared),
              let bufferB = device.makeBuffer(length: size * size * MemoryLayout<Float>.size, options: .storageModeShared),
              let bufferC = device.makeBuffer(length: size * size * MemoryLayout<Float>.size, options: .storageModeShared) else {
            throw BenchmarkError.allocationFailed("Failed to allocate buffers")
        }

        // Initialize
        let dataA = bufferA.contents().bindMemory(to: Float.self, capacity: size * size)
        let dataB = bufferB.contents().bindMemory(to: Float.self, capacity: size * size)

        for i in 0..<(size * size) {
            dataA[i] = Float.random(in: -1.0...1.0)
            dataB[i] = Float.random(in: -1.0...1.0)
        }

        let matrixA = MPSMatrix(buffer: bufferA, descriptor: matrixDesc)
        let matrixB = MPSMatrix(buffer: bufferB, descriptor: matrixDesc)
        let matrixC = MPSMatrix(buffer: bufferC, descriptor: matrixDesc)

        // Create operations
        let multiplication = MPSMatrixMultiplication(
            device: device,
            transposeLeft: false,
            transposeRight: false,
            resultRows: size,
            resultColumns: size,
            interiorColumns: size,
            alpha: 1.0,
            beta: 0.0
        )

        // Execute benchmark loop
        let startTime = Date()
        var shouldContinue = true

        while shouldContinue {
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let iterationStartTime = Date()

            // Encode matmul
            multiplication.encode(
                commandBuffer: commandBuffer,
                leftMatrix: matrixA,
                rightMatrix: matrixB,
                resultMatrix: matrixC
            )

            commandBuffer.addCompletedHandler { _ in
                let gpuTime = Date().timeIntervalSince(iterationStartTime)
                metricsCollector.recordIteration(gpuTime: gpuTime)
            }

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= duration {
                shouldContinue = false
            }
        }

        let wallClockDuration = Date().timeIntervalSince(startTime)
        return try metricsCollector.calculateMetrics(wallClockDuration: wallClockDuration)
    }

    func validate(parameters: [String: Any]) throws {
        if let size = parameters["size"] as? Int {
            guard size >= 128 && size <= 8192 else {
                throw ParameterError.outOfRange("size", value: size, min: 128, max: 8192)
            }
        }
    }
}
