import Foundation
import ArgumentParser

/// CLI command to list available benchmarks
struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available benchmark tasks"
    )

    @Flag(name: .long, help: "Show detailed parameter information")
    var verbose: Bool = false

    func run() throws {
        let registry = BenchmarkRegistry.shared
        let tasks = registry.allTasks()

        print("Available Benchmark Tasks:")
        print(String(repeating: "=", count: 26))
        print()

        for (index, task) in tasks.enumerated() {
            print("\(index + 1). \(task.name)")
            print("   Type: \(task.taskType.rawValue.capitalized)")
            print("   Description: \(task.description)")

            if verbose {
                print("   Default Parameters:")
                for (key, value) in task.defaultParameters.sorted(by: { $0.key < $1.key }) {
                    print("     - \(key): \(value.value)")
                }

                if !task.parameterConstraints.isEmpty {
                    print("   Parameter Constraints:")
                    for (key, constraint) in task.parameterConstraints.sorted(by: { $0.key < $1.key }) {
                        switch constraint {
                        case .range(let min, let max):
                            print("     - \(key): \(min)-\(max)")
                        case .options(let opts):
                            print("     - \(key): \(opts)")
                        case .conditional(_, let message):
                            print("     - \(key): \(message)")
                        }
                    }
                }

                if let reqs = task.resourceRequirements {
                    print("   Resource Requirements:")
                    print("     - Memory: \(reqs.minMemoryGB) GB minimum")
                    print("     - GPU Cores: \(reqs.minGPUCores) minimum")
                    print("     - macOS: \(reqs.minMacOSVersion) minimum")
                }
            }

            print()
        }

        if !verbose {
            print("Run with --verbose for full parameter details.")
        }
    }
}
