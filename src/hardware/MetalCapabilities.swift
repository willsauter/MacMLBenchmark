import Foundation
import Metal

/// Provides Metal GPU capability information
struct MetalCapabilities {
    let device: MTLDevice
    let gpuCoreCount: Int
    let maxWorkingSetSize: UInt64
    let supportsFamily: [MTLGPUFamily: Bool]

    /// Detects Metal capabilities for the system default device
    static func detect() throws -> MetalCapabilities {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw HardwareError.detectionFailed("No Metal-capable GPU found")
        }

        let gpuCoreCount = estimateGPUCoreCount(from: device)
        let maxWorkingSetSize = device.recommendedMaxWorkingSetSize

        // Check supported GPU families
        var familySupport: [MTLGPUFamily: Bool] = [:]
        if #available(macOS 13.0, *) {
            familySupport[.apple7] = device.supportsFamily(.apple7)
            familySupport[.apple8] = device.supportsFamily(.apple8)
        }
        familySupport[.apple6] = device.supportsFamily(.apple6)

        return MetalCapabilities(
            device: device,
            gpuCoreCount: gpuCoreCount,
            maxWorkingSetSize: maxWorkingSetSize,
            supportsFamily: familySupport
        )
    }

    private static func estimateGPUCoreCount(from device: MTLDevice) -> Int {
        let deviceName = device.name

        // Pattern matching for known Apple Silicon variants
        if deviceName.contains("M1") {
            if deviceName.contains("Ultra") { return 64 }
            if deviceName.contains("Max") { return 32 }
            if deviceName.contains("Pro") { return 16 }
            return 8
        } else if deviceName.contains("M2") {
            if deviceName.contains("Ultra") { return 76 }
            if deviceName.contains("Max") { return 38 }
            if deviceName.contains("Pro") { return 19 }
            return 10
        } else if deviceName.contains("M3") {
            if deviceName.contains("Ultra") { return 60 }
            if deviceName.contains("Max") { return 40 }
            if deviceName.contains("Pro") { return 18 }
            return 10
        } else if deviceName.contains("M4") {
            if deviceName.contains("Max") { return 40 }
            if deviceName.contains("Pro") { return 20 }
            return 10
        }

        // Conservative estimate for newer variants
        return 10
    }

    /// Returns human-readable capability summary
    func summary() -> String {
        """
        GPU Device: \(device.name)
        Core Count: \(gpuCoreCount) cores
        Max Working Set: \(maxWorkingSetSize / (1024 * 1024 * 1024)) GB
        Metal Support: \(supportsFamily.filter { $0.value }.map { "\($0.key)" }.joined(separator: ", "))
        """
    }
}
