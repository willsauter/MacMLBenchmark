import Foundation

/// System thermal state during benchmark execution
enum ThermalState: String, Codable {
    case nominal    // Normal operating temperature
    case fair       // Slightly elevated, no throttling
    case serious    // Elevated, possible throttling
    case critical   // Throttling active

    /// Maps from ProcessInfo.ThermalState
    init(from processInfoState: ProcessInfo.ThermalState) {
        switch processInfoState {
        case .nominal:
            self = .nominal
        case .fair:
            self = .fair
        case .serious:
            self = .serious
        case .critical:
            self = .critical
        @unknown default:
            self = .nominal
        }
    }
}
