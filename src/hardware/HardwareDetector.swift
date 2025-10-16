import Foundation
import Metal

/// Detects Mac hardware information for benchmarking
struct HardwareDetector {
    /// Detects current hardware profile
    static func detect() throws -> HardwareProfile {
        let modelName = try detectModelName()
        let chipIdentifier = try detectChipIdentifier()
        let gpuCoreCount = try detectGPUCoreCount()
        let totalMemoryGB = detectTotalMemory()
        let gpuMemoryGB = try detectGPUMemory()
        let macOSVersion = detectMacOSVersion()

        let profile = HardwareProfile(
            modelName: modelName,
            chipIdentifier: chipIdentifier,
            gpuCoreCount: gpuCoreCount,
            totalMemoryGB: totalMemoryGB,
            gpuMemoryGB: gpuMemoryGB,
            macOSVersion: macOSVersion,
            detectionTimestamp: Date()
        )

        // Validate detected hardware
        try profile.validate()

        return profile
    }

    private static func detectModelName() throws -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let modelIdentifier = String(cString: model)

        // Try to get marketing name
        if let marketingName = getMarketingName(for: modelIdentifier) {
            return marketingName
        }

        return modelIdentifier
    }

    private static func detectChipIdentifier() throws -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var brandString = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &brandString, &size, nil, 0)
        let cpuBrand = String(cString: brandString)

        // Extract M1/M2/M3 variant
        if let range = cpuBrand.range(of: "Apple M[1-9]\\s*(Pro|Max|Ultra)?", options: .regularExpression) {
            var chip = String(cpuBrand[range]).trimmingCharacters(in: .whitespaces)
            // Normalize spacing
            chip = chip.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            return chip
        }

        // Fallback: check architecture
        var arch = 0
        size = MemoryLayout<Int>.size
        sysctlbyname("hw.cputype", &arch, &size, nil, 0)

        // ARM64 constant
        if arch == 16777228 {  // CPU_TYPE_ARM64
            return "Apple Silicon (Unknown Variant)"
        }

        // Not Apple Silicon - provide helpful error message
        let helpfulMessage = """

        Error: Unsupported Hardware

        This benchmark suite requires Apple Silicon (M1/M2/M3 or later).
        Detected: \(cpuBrand)

        The Mac ML Benchmark Suite is designed exclusively for Mac Silicon GPUs
        and cannot run on Intel-based Macs or other hardware.
        """

        print(helpfulMessage)
        throw HardwareError.unsupportedChip(cpuBrand)
    }

    private static func detectGPUCoreCount() throws -> Int {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw HardwareError.detectionFailed("Metal device not available")
        }

        // Metal doesn't directly expose GPU core count, estimate from registry ID and family
        // This is a best-effort approximation based on known Mac Silicon variants
        let deviceName = device.name

        // Pattern matching for known variants
        if deviceName.contains("M1") {
            if deviceName.contains("Ultra") { return 64 }
            if deviceName.contains("Max") { return 32 }
            if deviceName.contains("Pro") { return 16 }
            return 8  // M1 base
        } else if deviceName.contains("M2") {
            if deviceName.contains("Ultra") { return 76 }
            if deviceName.contains("Max") { return 38 }
            if deviceName.contains("Pro") { return 19 }
            return 10  // M2 base
        } else if deviceName.contains("M3") {
            if deviceName.contains("Max") { return 40 }
            if deviceName.contains("Pro") { return 18 }
            return 10  // M3 base
        } else if deviceName.contains("M4") {
            if deviceName.contains("Max") { return 40 }
            if deviceName.contains("Pro") { return 20 }
            return 10  // M4 base
        }

        // Fallback: newer Apple Silicon variant
        return 10  // Conservative estimate for unknown variants
    }

    private static func detectTotalMemory() -> Int {
        let memoryBytes = ProcessInfo.processInfo.physicalMemory
        return Int(memoryBytes / (1024 * 1024 * 1024))  // Convert to GB
    }

    private static func detectGPUMemory() throws -> Int {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw HardwareError.detectionFailed("Metal device not available")
        }

        // GPU memory is unified memory on Apple Silicon
        // Recommended max working set is typically 75% of available memory
        let recommendedBytes = device.recommendedMaxWorkingSetSize
        return Int(recommendedBytes / (1024 * 1024 * 1024))  // Convert to GB
    }

    private static func detectMacOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private static func getMarketingName(for identifier: String) -> String? {
        // Map hardware identifiers to marketing names (partial list)
        let marketingNames: [String: String] = [
            "Mac14,2": "MacBook Pro (13-inch, M2, 2022)",
            "Mac14,5": "MacBook Pro (14-inch, 2023)",
            "Mac14,6": "MacBook Pro (16-inch, 2023)",
            "Mac14,13": "Mac Studio (2023)",
            "Mac14,14": "Mac Studio (M2 Ultra, 2023)",
            "Mac13,1": "Mac Studio (M1 Max, 2022)",
            "Mac13,2": "Mac Studio (M1 Ultra, 2022)"
        ]

        return marketingNames[identifier]
    }
}
