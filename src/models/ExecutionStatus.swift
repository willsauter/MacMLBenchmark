import Foundation

/// Status of benchmark execution on a machine
enum ExecutionStatus: String, Codable {
    case success
    case failed
    case timeout
    case cancelled
}
