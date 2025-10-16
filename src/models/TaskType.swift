import Foundation

/// Category of benchmark task
enum TaskType: String, Codable {
    case inference      // LLM inference, image classification
    case training       // Training simulation, gradient computation
    case processing     // Matrix ops, activations, memory bandwidth
}
