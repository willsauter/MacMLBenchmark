import Foundation

struct FrameworkMetrics: Codable {
    let frameworkName: String
    let modelName: String
    let modelSize: ModelSize
    let baseMetrics: PerformanceMetrics
    let frameworkOverhead: Double
    let initTime: TimeInterval
    let modelLoadTime: TimeInterval
    let prefillTokensPerSec: Double?
    let decodeTokensPerSec: Double?
}
