import Foundation
import ArgumentParser

/// CLI command to run benchmarks
struct RunCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Execute one or more benchmark tasks"
    )

    @Argument(help: "Benchmark task name(s) to execute")
    var tasks: [String] = []

    @Flag(name: .long, help: "Run all available benchmarks")
    var all: Bool = false

    @Option(name: .long, help: "Benchmark duration in seconds (1-3600, default: 10)")
    var duration: Int = 10

    @Option(name: .long, help: "Batch size (1-1024, default: task-specific)")
    var batchSize: Int?

    @Option(name: .long, help: "Thread count (1-cores, default: system cores)")
    var threads: Int?

    @Option(name: .long, help: "Size parameter - matrix dimension, image size, or sequence length (128-8192, default: task-specific)")
    var size: Int?

    @Option(name: .long, help: "Export results to file (.json or .csv)")
    var output: String?

    mutating func validate() throws {
        if tasks.isEmpty && !all {
            throw ValidationError("Must specify either task name(s) or --all flag")
        }

        if !tasks.isEmpty && all {
            throw ValidationError("Cannot specify both task names and --all flag")
        }

        // Validate task names exist
        let registry = BenchmarkRegistry.shared
        let availableTasks = registry.allTaskNames()

        for taskName in tasks {
            if registry.getTask(taskName) == nil {
                throw ValidationError("Unknown task '\(taskName)'. Available: \(availableTasks.joined(separator: ", "))")
            }
        }

        // Validate parameter ranges (T040-T043, T044)
        if duration < 1 || duration > 3600 {
            throw ValidationError("Duration must be between 1 and 3600 seconds. Got: \(duration)")
        }

        if let bs = batchSize, (bs < 1 || bs > 1024) {
            throw ValidationError("Batch size must be between 1 and 1024. Got: \(bs)")
        }

        if let t = threads, (t < 1 || t > ProcessInfo.processInfo.processorCount) {
            throw ValidationError("Thread count must be between 1 and \(ProcessInfo.processInfo.processorCount). Got: \(t)")
        }

        if let s = size, (s < 128 || s > 8192) {
            throw ValidationError("Size must be between 128 and 8192. Got: \(s)")
        }
    }

    func run() throws {
        // Detect hardware
        print(ResultFormatter.formatBanner())
        print()

        let hardware = try HardwareDetector.detect()
        print(ResultFormatter.formatHardware(hardware))
        print()

        // Determine which tasks to run
        let registry = BenchmarkRegistry.shared
        let tasksToRun = all ? registry.allTaskNames() : tasks

        // Build parameter overrides (T046)
        var parameterOverrides: [String: [String: AnyCodable]] = [:]

        for taskName in tasksToRun {
            var taskParams: [String: AnyCodable] = [:]

            // Add duration
            taskParams["duration"] = AnyCodable(duration)

            // Add optional parameters if specified
            if let bs = batchSize {
                taskParams["batch_size"] = AnyCodable(bs)
            }
            if let t = threads {
                taskParams["threads"] = AnyCodable(t)
            }
            if let s = size {
                taskParams["size"] = AnyCodable(s)
            }

            if !taskParams.isEmpty {
                parameterOverrides[taskName] = taskParams
            }
        }

        // Create configuration
        let config = BenchmarkConfiguration(
            selectedTasks: tasksToRun,
            parameterOverrides: parameterOverrides,
            hardware: hardware
        )

        // Validate configuration (T045, T049)
        for taskName in tasksToRun {
            if let task = registry.getTask(taskName) {
                var params = extractDefaultParameters(from: task.defaultParameters)

                // Merge overrides
                if let overrides = parameterOverrides[taskName] {
                    for (key, value) in overrides {
                        params[key] = value.value
                    }
                }

                // Validate using ParameterValidator
                do {
                    try ParameterValidator.validate(parameters: params, against: task, hardware: hardware)
                } catch {
                    print(ParameterValidator.formatError(error, taskName: taskName))
                    throw error
                }
            }
        }

        // Create executor and run
        let executor = BenchmarkExecutor()
        let results = try executor.execute(configuration: config)

        // Export results if requested (T060-T061)
        if let outputPath = output {
            do {
                if outputPath.hasSuffix(".json") {
                    try JSONExporter.export(results: results, to: outputPath)
                    print("\n✓ Results exported to: \(outputPath)")
                } else if outputPath.hasSuffix(".csv") {
                    try CSVExporter.export(results: results, to: outputPath)
                    print("\n✓ Results exported to: \(outputPath)")
                } else {
                    print("\nWarning: Unknown file extension. Exporting as JSON.")
                    try JSONExporter.export(results: results, to: outputPath + ".json")
                    print("✓ Results exported to: \(outputPath).json")
                }
            } catch {
                print("\nError exporting results: \(error.localizedDescription)")
            }
        }
    }

    private func extractDefaultParameters(from codable: [String: AnyCodable]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in codable {
            result[key] = value.value
        }
        return result
    }
}

struct ValidationError: Error, LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        return message
    }
}
