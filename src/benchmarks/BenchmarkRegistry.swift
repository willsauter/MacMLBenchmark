import Foundation

/// Registry of all available benchmark tasks
class BenchmarkRegistry {
    private var tasks: [String: BenchmarkTask] = [:]
    private var implementations: [String: BenchmarkProtocol] = [:]

    /// Singleton instance
    static let shared = BenchmarkRegistry()

    private init() {
        // Register built-in benchmarks
        registerBuiltInBenchmarks()
    }

    /// Registers all built-in benchmark tasks (T054)
    private func registerBuiltInBenchmarks() {
        // 1. Matrix Multiplication
        register(
            name: "matrix-multiply",
            displayName: "Matrix Multiplication",
            taskType: .inference,
            description: "Measures GPU throughput for large matrix operations (transformer layer simulation)",
            defaultParameters: ["duration": 10, "batch_size": 32, "size": 4096],
            parameterConstraints: [
                "duration": .range(min: 1, max: 3600),
                "batch_size": .range(min: 1, max: 1024),
                "size": .range(min: 128, max: 8192)
            ],
            resourceRequirements: ResourceRequirements(minMemoryGB: 2, minGPUCores: 8, minMacOSVersion: "12.0"),
            implementation: MatrixMultiplyBenchmark()
        )

        // 2. 2D Convolution
        register(
            name: "convolution-2d",
            displayName: "2D Convolution",
            taskType: .inference,
            description: "Measures convolution performance for CNN workloads",
            defaultParameters: ["duration": 10, "batch_size": 16, "image_size": 1024, "kernel_size": 3],
            parameterConstraints: [
                "duration": .range(min: 1, max: 3600),
                "batch_size": .range(min: 1, max: 1024),
                "image_size": .range(min: 256, max: 4096),
                "kernel_size": .range(min: 3, max: 11)
            ],
            resourceRequirements: ResourceRequirements(minMemoryGB: 4, minGPUCores: 8, minMacOSVersion: "12.0"),
            implementation: ConvolutionBenchmark()
        )

        // 3. Attention Mechanism
        register(
            name: "attention-mechanism",
            displayName: "Attention Mechanism",
            taskType: .inference,
            description: "Measures scaled dot-product attention performance (LLM representative)",
            defaultParameters: ["duration": 10, "batch_size": 8, "sequence_length": 2048, "head_count": 32],
            parameterConstraints: [
                "duration": .range(min: 1, max: 3600),
                "batch_size": .range(min: 1, max: 1024),
                "sequence_length": .range(min: 128, max: 8192),
                "head_count": .range(min: 8, max: 64)
            ],
            resourceRequirements: ResourceRequirements(minMemoryGB: 4, minGPUCores: 8, minMacOSVersion: "12.0"),
            implementation: AttentionBenchmark()
        )

        // 4. Activation Functions
        register(
            name: "activation-functions",
            displayName: "Activation Functions",
            taskType: .processing,
            description: "Measures activation function throughput (memory bandwidth test)",
            defaultParameters: ["duration": 10, "batch_size": 32, "size": 4096],
            parameterConstraints: [
                "duration": .range(min: 1, max: 3600),
                "batch_size": .range(min: 1, max: 1024),
                "size": .range(min: 128, max: 8192)
            ],
            resourceRequirements: ResourceRequirements(minMemoryGB: 2, minGPUCores: 8, minMacOSVersion: "12.0"),
            implementation: ActivationBenchmark()
        )

        // 5. Mixed Operations
        register(
            name: "mixed-operations",
            displayName: "Mixed Operations",
            taskType: .training,
            description: "Measures combined operation performance (training simulation)",
            defaultParameters: ["duration": 10, "batch_size": 16, "size": 2048],
            parameterConstraints: [
                "duration": .range(min: 1, max: 3600),
                "batch_size": .range(min: 1, max: 1024),
                "size": .range(min: 128, max: 8192)
            ],
            resourceRequirements: ResourceRequirements(minMemoryGB: 2, minGPUCores: 8, minMacOSVersion: "12.0"),
            implementation: MixedOperationsBenchmark()
        )
    }

    /// Registers a benchmark task
    func register(
        name: String,
        displayName: String,
        taskType: TaskType,
        description: String,
        defaultParameters: [String: Any],
        parameterConstraints: [String: ParameterConstraint],
        resourceRequirements: ResourceRequirements?,
        implementation: BenchmarkProtocol
    ) {
        // Convert default parameters to AnyCodable
        var codableParams: [String: AnyCodable] = [:]
        for (key, value) in defaultParameters {
            codableParams[key] = AnyCodable(value)
        }

        var task = BenchmarkTask(
            name: name,
            displayName: displayName,
            taskType: taskType,
            description: description,
            defaultParameters: codableParams
        )

        // Set runtime-only properties
        task.parameterConstraints = parameterConstraints
        task.resourceRequirements = resourceRequirements

        tasks[name] = task
        implementations[name] = implementation
    }

    /// Gets a benchmark task by name
    func getTask(_ name: String) -> BenchmarkTask? {
        return tasks[name]
    }

    /// Gets benchmark implementation by name
    func getImplementation(_ name: String) -> BenchmarkProtocol? {
        return implementations[name]
    }

    /// Gets all registered task names
    func allTaskNames() -> [String] {
        return Array(tasks.keys).sorted()
    }

    /// Gets all registered tasks
    func allTasks() -> [BenchmarkTask] {
        return tasks.values.sorted { $0.name < $1.name }
    }
}
