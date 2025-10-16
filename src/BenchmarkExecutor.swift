import Foundation
import Metal
import Dispatch

/// Executes benchmark tasks and manages execution flow
class BenchmarkExecutor {
    private var benchmarkRun: BenchmarkRun?
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?

    /// Sets up SIGINT handler for graceful cancellation (T073)
    private func setupCancellationHandler() -> DispatchSourceSignal? {
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)

        signalSource.setEventHandler { [weak self] in
            print("\n\nReceived interrupt signal. Cleaning up...")
            self?.benchmarkRun?.cancel()

            // Cleanup GPU resources
            self?.device = nil
            self?.commandQueue = nil

            exit(130)  // Standard exit code for SIGINT
        }

        signal(SIGINT, SIG_IGN)  // Ignore default SIGINT handler
        signalSource.resume()

        return signalSource
    }

    /// Executes benchmarks according to configuration
    /// Returns all benchmark results for potential export
    func execute(configuration: BenchmarkConfiguration) throws -> [BenchmarkResult] {
        // Setup SIGINT handler for graceful cancellation (T073)
        let signalSource = setupCancellationHandler()

        defer {
            signalSource?.cancel()
        }

        // Initialize Metal
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw BenchmarkError.notSetup("No Metal-capable GPU found")
        }

        guard let commandQueue = device.makeCommandQueue() else {
            throw BenchmarkError.notSetup("Failed to create Metal command queue")
        }

        self.device = device
        self.commandQueue = commandQueue

        // Create benchmark run
        let run = BenchmarkRun(configuration: configuration)
        self.benchmarkRun = run

        let registry = BenchmarkRegistry.shared

        // Execute each task
        for taskName in configuration.selectedTasks {
            guard !run.isCancelled else {
                print("\nBenchmark cancelled by user")
                break
            }

            guard let task = registry.getTask(taskName),
                  let implementation = registry.getImplementation(taskName) else {
                run.failTask(taskName, error: "Task not found in registry")
                continue
            }

            run.startTask(taskName)

            do {
                // Print task header
                print(ResultFormatter.formatHeader(task.displayName))

                // Merge default parameters with overrides
                var parameters = extractParameters(from: task.defaultParameters)
                if let overrides = configuration.parameterOverrides[taskName] {
                    for (key, value) in overrides {
                        parameters[key] = value.value
                    }
                }

                // Display configuration
                print("Configuration:")
                print(ResultFormatter.formatConfiguration(parameters))
                print()

                // Validate parameters
                try implementation.validate(parameters: parameters)
                try task.validateParameters(parameters)

                // Check for thermal throttling warning (T075)
                if ThermalMonitor.shouldWarnBeforeExecution() {
                    if let warning = ThermalMonitor.warningMessage() {
                        print(warning)
                        // In non-interactive mode, continue anyway
                        // In interactive mode, could prompt user
                    }
                }

                // Setup benchmark with resource error handling (T074)
                do {
                    try implementation.setup(device: device, commandQueue: commandQueue)
                } catch {
                    throw BenchmarkError.allocationFailed("GPU resource allocation failed: \(error.localizedDescription). Try reducing --batch-size or --size parameters."
                    )
                }

                // Get duration
                let duration = parameters["duration"] as? Int ?? 10

                // Execute with progress tracking
                let result = try executeWithProgress(
                    implementation: implementation,
                    duration: TimeInterval(duration),
                    parameters: parameters,
                    taskName: taskName,
                    configuration: configuration
                )

                // Display result
                print(ResultFormatter.format(result))

                // Cleanup
                implementation.cleanup()

                // Mark complete
                run.completeTask(taskName, result: result)

            } catch {
                let errorMsg = error.localizedDescription
                print("\nError: \(errorMsg)\n")
                run.failTask(taskName, error: errorMsg)
                implementation.cleanup()
            }
        }

        // Display summary if multiple tasks (T059)
        if configuration.selectedTasks.count > 1 {
            printSummary(run: run)
        }

        return run.partialResults
    }

    /// Executes benchmark with real-time progress indication
    private func executeWithProgress(
        implementation: BenchmarkProtocol,
        duration: TimeInterval,
        parameters: [String: Any],
        taskName: String,
        configuration: BenchmarkConfiguration
    ) throws -> BenchmarkResult {
        let startTime = Date()

        // Start progress display in background
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let elapsed = Date().timeIntervalSince(startTime)
            let percent = min((elapsed / duration) * 100.0, 100.0)

            // Clear line and print progress
            print("\r\(ResultFormatter.formatProgress(percent: percent, elapsed: elapsed))", terminator: "")
            fflush(stdout)
        }

        // Execute benchmark
        let metrics: PerformanceMetrics
        do {
            metrics = try implementation.execute(duration: duration, parameters: parameters)
        } catch {
            progressTimer.invalidate()
            print()  // New line after progress
            throw error
        }

        progressTimer.invalidate()
        print()  // New line after progress

        let endTime = Date()

        // Get thermal state
        let thermalState = ThermalMonitor.currentState()

        // Determine status
        let status: ResultStatus
        if thermalState == .serious || thermalState == .critical {
            status = .throttled
        } else {
            status = .success
        }

        // Create result
        return BenchmarkResult(
            configuration: configuration,
            taskName: taskName,
            startTimestamp: startTime,
            endTimestamp: endTime,
            metrics: metrics,
            status: status,
            errorMessage: nil,
            thermalState: thermalState
        )
    }

    /// Prints summary of benchmark run
    private func printSummary(run: BenchmarkRun) {
        let separator = String(repeating: "=", count: 40)
        print()
        print(separator)
        print("Summary")
        print(separator)
        print("Status: \(run.status())")
        print("Completed: \(run.completedTasks.joined(separator: ", "))")

        if !run.failedTasks.isEmpty {
            print("Failed:")
            for (task, error) in run.failedTasks {
                print("  - \(task): \(error)")
            }
        }
    }

    /// Extracts plain dictionary from AnyCodable dictionary
    private func extractParameters(from codable: [String: AnyCodable]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in codable {
            result[key] = value.value
        }
        return result
    }
}
