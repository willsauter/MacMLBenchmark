import Foundation

enum LLMPhase: String, Codable {
    case loading
    case prefill
    case decode
}
