import Foundation

/// Status of benchmark execution result
enum ResultStatus: String, Codable {
    case success             // Completed without errors
    case failed              // Execution failed
    case throttled           // Completed but thermal throttling detected
    case partiallyCompleted  // Interrupted but saved partial results
}
