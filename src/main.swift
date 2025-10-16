import Foundation
import ArgumentParser

struct MacMLBench: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "macmlbench",
        abstract: "Mac ML Benchmark Suite - GPU performance benchmarking for Apple Silicon",
        version: "1.0.0",
        subcommands: [RunCommand.self, MenuCommand.self, ListCommand.self, CompareCommand.self, HardwareCommand.self, VersionCommand.self],
        defaultSubcommand: MenuCommand.self
    )
}

// Entry point
MacMLBench.main()
