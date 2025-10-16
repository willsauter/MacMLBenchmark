import Foundation

struct ModelVariant: Codable {
    let modelName: String
    let sizeCategory: ModelSize
    let fileSizeMB: Int
    let downloadURL: String?
    let cachedPath: String
    let frameworks: [String]

    func isCached() -> Bool {
        return FileManager.default.fileExists(atPath: cachedPath)
    }
}
