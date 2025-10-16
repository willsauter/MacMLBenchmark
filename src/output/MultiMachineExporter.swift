import Foundation

/// Exports multi-machine benchmark results
struct MultiMachineExporter {
    /// Exports multi-machine run to JSON
    static func export(run: MultiMachineRun, to filePath: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let exportData = MultiMachineRunExport(multiMachineRun: run)
        let jsonData = try encoder.encode(exportData)

        let url = URL(fileURLWithPath: filePath)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        try jsonData.write(to: url)
    }
}

private struct MultiMachineRunExport: Codable {
    let multiMachineRun: MultiMachineRun
}
