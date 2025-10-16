import Foundation
import ArgumentParser

/// CLI command to display hardware information
struct HardwareCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hardware",
        abstract: "Display detected hardware information"
    )

    @Flag(name: .long, help: "Output in JSON format")
    var json: Bool = false

    func run() throws {
        let hardware = try HardwareDetector.detect()

        if json {
            // JSON output (T070)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let jsonData = HardwareExport(hardwareProfile: hardware)
            let data = try encoder.encode(jsonData)

            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            // Human-readable output
            print("Mac ML Benchmark Suite - Hardware Profile")
            print(String(repeating: "=", count: 42))
            print()
            print("Model: \(hardware.modelName)")
            print("Chip: \(hardware.chipIdentifier)")
            print("GPU Cores: \(hardware.gpuCoreCount)")
            print("CPU Cores: \(ProcessInfo.processInfo.processorCount)")
            print("Total Memory: \(hardware.totalMemoryGB) GB")
            print("GPU Memory: \(hardware.gpuMemoryGB) GB")
            print("macOS Version: \(hardware.macOSVersion)")
            print()
            print("Status: Compatible ✓")
        }
    }
}

private struct HardwareExport: Codable {
    let hardwareProfile: HardwareInfo

    init(hardwareProfile: HardwareProfile) {
        self.hardwareProfile = HardwareInfo(from: hardwareProfile)
    }
}

private struct HardwareInfo: Codable {
    let modelName: String
    let chipIdentifier: String
    let gpuCoreCount: Int
    let cpuCoreCount: Int
    let totalMemoryGB: Int
    let gpuMemoryGB: Int
    let macOSVersion: String
    let isCompatible: Bool
    let detectionTimestamp: Date

    init(from profile: HardwareProfile) {
        self.modelName = profile.modelName
        self.chipIdentifier = profile.chipIdentifier
        self.gpuCoreCount = profile.gpuCoreCount
        self.cpuCoreCount = ProcessInfo.processInfo.processorCount
        self.totalMemoryGB = profile.totalMemoryGB
        self.gpuMemoryGB = profile.gpuMemoryGB
        self.macOSVersion = profile.macOSVersion
        self.isCompatible = true  // If we got here, it's compatible
        self.detectionTimestamp = profile.detectionTimestamp
    }
}
