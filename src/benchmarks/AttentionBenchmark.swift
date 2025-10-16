import Foundation
import Metal
import MetalPerformanceShaders

/// Attention mechanism benchmark using custom Metal compute kernel
class AttentionBenchmark: BaseBenchmark, BenchmarkProtocol {
    private var computePipeline: MTLComputePipelineState?

    init() {
        super.init(name: "attention-mechanism", displayName: "Attention Mechanism")
    }

    override func setup(device: MTLDevice, commandQueue: MTLCommandQueue) throws {
        try super.setup(device: device, commandQueue: commandQueue)

        // Create compute pipeline for scaled dot-product attention
        // For MVP, we'll use matrix operations to simulate attention
        // A full Metal kernel would be more representative but requires shader compilation
    }

    func execute(duration: TimeInterval, parameters: [String: Any]) throws -> PerformanceMetrics {
        guard let device = self.device else {
            throw BenchmarkError.notSetup("Device not initialized")
        }

        guard let commandQueue = self.commandQueue else {
            throw BenchmarkError.notSetup("Command queue not initialized")
        }

        // Extract parameters
        let seqLength = parameters["sequence_length"] as? Int ?? 2048
        let headCount = parameters["head_count"] as? Int ?? 32
        let headDim = 64

        let metricsCollector = MetricsCollector(device: device)

        // Create matrices for Q, K, V (sequence_length x embedding_dim)
        let embeddingDim = headCount * headDim
        let qkvSize = seqLength * embeddingDim

        guard let bufferQ = device.makeBuffer(length: qkvSize * MemoryLayout<Float>.size, options: .storageModeShared),
              let bufferK = device.makeBuffer(length: qkvSize * MemoryLayout<Float>.size, options: .storageModeShared),
              let bufferOut = device.makeBuffer(length: qkvSize * MemoryLayout<Float>.size, options: .storageModeShared) else {
            throw BenchmarkError.allocationFailed("Failed to allocate attention buffers")
        }

        // Initialize Q, K with random data
        let dataQ = bufferQ.contents().bindMemory(to: Float.self, capacity: qkvSize)
        let dataK = bufferK.contents().bindMemory(to: Float.self, capacity: qkvSize)

        for i in 0..<qkvSize {
            dataQ[i] = Float.random(in: -1.0...1.0)
            dataK[i] = Float.random(in: -1.0...1.0)
        }

        // Create MPS matrix descriptors
        let matrixDesc = MPSMatrixDescriptor(
            rows: seqLength,
            columns: embeddingDim,
            rowBytes: embeddingDim * MemoryLayout<Float>.stride,
            dataType: .float32
        )

        let matrixQ = MPSMatrix(buffer: bufferQ, descriptor: matrixDesc)
        let matrixK = MPSMatrix(buffer: bufferK, descriptor: matrixDesc)
        let matrixOut = MPSMatrix(buffer: bufferOut, descriptor: matrixDesc)

        // Simulate attention: Q @ K^T (simplified, actual attention includes scaling and softmax)
        let multiplication = MPSMatrixMultiplication(
            device: device,
            transposeLeft: false,
            transposeRight: true,
            resultRows: seqLength,
            resultColumns: seqLength,
            interiorColumns: embeddingDim,
            alpha: 1.0 / sqrt(Double(headDim)),  // Scaling factor
            beta: 0.0
        )

        // Execute benchmark loop
        let startTime = Date()
        var shouldContinue = true

        while shouldContinue {
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let iterationStartTime = Date()

            // Encode attention computation (simplified as matmul)
            multiplication.encode(
                commandBuffer: commandBuffer,
                leftMatrix: matrixQ,
                rightMatrix: matrixK,
                resultMatrix: matrixOut
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
        if let seqLength = parameters["sequence_length"] as? Int {
            guard seqLength >= 128 && seqLength <= 8192 else {
                throw ParameterError.outOfRange("sequence_length", value: seqLength, min: 128, max: 8192)
            }
        }

        if let headCount = parameters["head_count"] as? Int {
            guard headCount >= 8 && headCount <= 64 else {
                throw ParameterError.outOfRange("head_count", value: headCount, min: 8, max: 64)
            }
        }
    }
}
