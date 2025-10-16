import Foundation

/// Represents an active benchmark execution (runtime state)
class BenchmarkRun {
    let configuration: BenchmarkConfiguration
    let startTime: Date
    var currentTask: String?
    var completedTasks: [String]
    var failedTasks: [String: String]  // task name -> error message
    var partialResults: [BenchmarkResult]
    var isCancelled: Bool

    init(configuration: BenchmarkConfiguration) {
        self.configuration = configuration
        self.startTime = Date()
        self.currentTask = nil
        self.completedTasks = []
        self.failedTasks = [:]
        self.partialResults = []
        self.isCancelled = false
    }

    /// Marks a task as started
    func startTask(_ taskName: String) {
        currentTask = taskName
    }

    /// Marks a task as completed successfully
    func completeTask(_ taskName: String, result: BenchmarkResult) {
        completedTasks.append(taskName)
        partialResults.append(result)
        currentTask = nil
    }

    /// Marks a task as failed
    func failTask(_ taskName: String, error: String) {
        failedTasks[taskName] = error
        currentTask = nil
    }

    /// Requests cancellation
    func cancel() {
        isCancelled = true
    }

    /// Returns overall status
    func status() -> String {
        if isCancelled {
            return "Cancelled"
        }
        let total = configuration.selectedTasks.count
        let completed = completedTasks.count
        let failed = failedTasks.count
        return "\(completed)/\(total) completed, \(failed) failed"
    }
}
