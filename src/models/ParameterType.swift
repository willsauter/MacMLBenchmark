import Foundation

/// Type of parameter for benchmark configuration
enum ParameterType: String, Codable {
    case duration    // Time in seconds
    case size        // Dimension, resolution, length
    case count       // Thread count, batch size, iterations
}
