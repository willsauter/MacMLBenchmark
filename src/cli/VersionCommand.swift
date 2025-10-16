import Foundation
import ArgumentParser

/// CLI command to display version information
struct VersionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Show version information"
    )

    func run() throws {
        print("Mac ML Benchmark Suite")
        print("Version: 1.0.0")
        print("Build: 2025-10-16")
        print("Swift: 5.9+")
        print("Metal API: 3.x")
    }
}
