import Foundation

/// Represents the Mac hardware being benchmarked
struct HardwareProfile: Codable {
    let modelName: String
    let chipIdentifier: String
    let gpuCoreCount: Int
    let totalMemoryGB: Int
    let gpuMemoryGB: Int
    let macOSVersion: String
    let detectionTimestamp: Date

    /// Validates hardware profile meets minimum requirements
    func validate() throws {
        guard chipIdentifier.range(of: "M[1-9]", options: .regularExpression) != nil else {
            throw HardwareError.unsupportedChip(chipIdentifier)
        }

        guard gpuCoreCount > 0 else {
            throw HardwareError.invalidGPUCoreCount(gpuCoreCount)
        }

        guard totalMemoryGB >= 8 else {
            throw HardwareError.insufficientMemory(totalMemoryGB)
        }

        // Parse macOS version
        let versionComponents = macOSVersion.split(separator: ".").compactMap { Int($0) }
        guard let major = versionComponents.first, major >= 12 else {
            throw HardwareError.unsupportedMacOSVersion(macOSVersion)
        }
    }
}

enum HardwareError: Error, LocalizedError {
    case unsupportedChip(String)
    case invalidGPUCoreCount(Int)
    case insufficientMemory(Int)
    case unsupportedMacOSVersion(String)
    case detectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedChip(let chip):
            return "Unsupported hardware: \(chip). This tool requires Apple Silicon (M1/M2/M3 or later)."
        case .invalidGPUCoreCount(let count):
            return "Invalid GPU core count: \(count). Expected > 0."
        case .insufficientMemory(let gb):
            return "Insufficient memory: \(gb) GB. Minimum 8 GB required for Metal Performance Shaders."
        case .unsupportedMacOSVersion(let version):
            return "Unsupported macOS version: \(version). Minimum macOS 12.0 (Monterey) required."
        case .detectionFailed(let reason):
            return "Hardware detection failed: \(reason)"
        }
    }
}
