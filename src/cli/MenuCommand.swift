import Foundation
import ArgumentParser

/// Interactive menu command
struct MenuCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "menu",
        abstract: "Launch interactive menu for benchmark selection"
    )

    func run() throws {
        let state = MenuState()
        let registry = BenchmarkRegistry.shared

        var exitMenu = false

        while !exitMenu {
            TerminalUI.clearScreen()
            TerminalUI.displayHeader("Mac ML Benchmark Suite - Interactive Menu")

            // Main menu
            let mainOptions = [
                "Run Benchmarks",
                "Manage Remote Machines",
                "View Results",
                "Exit"
            ]

            TerminalUI.displayMenu(options: mainOptions)
            let choice = TerminalUI.readInput(prompt: "Select option (1-4):")

            switch choice {
            case "1":
                try runBenchmarksFlow(state: state, registry: registry)
            case "2":
                try manageMachinesFlow()

            case "3":
                print("\nResult viewing coming soon")
                TerminalUI.pause()
            case "4", "exit", "quit", "q":
                exitMenu = true
            default:
                print("Invalid choice. Please select 1-4.")
                TerminalUI.pause()
            }
        }

        print("\nGoodbye!")
    }

    /// Benchmark selection and execution flow
    private func runBenchmarksFlow(state: MenuState, registry: BenchmarkRegistry) throws {
        // Step 1: Select benchmarks
        TerminalUI.clearScreen()
        TerminalUI.displayHeader("Select Benchmarks to Run")

        let tasks = registry.allTasks()
        print("Available benchmarks:")
        for (index, task) in tasks.enumerated() {
            let marker = state.selectedTasks.contains(task.name) ? "[x]" : "[ ]"
            print("\(index + 1). \(marker) \(task.displayName)")
        }

        print("\nEnter numbers to toggle (e.g., 1,3,5), 'all' for all, or 'done' to continue:")

        var selectingTasks = true
        while selectingTasks {
            let input = TerminalUI.readInput(prompt: ">")

            if input.lowercased() == "done" || input.isEmpty {
                if state.selectedTasks.isEmpty {
                    print("Please select at least one benchmark")
                    continue
                }
                selectingTasks = false
            } else if input.lowercased() == "all" {
                state.selectAllTasks(tasks.map { $0.name })
                print("✓ All benchmarks selected")
            } else {
                // Parse comma-separated numbers
                let numbers = input.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

                for num in numbers {
                    if num >= 1 && num <= tasks.count {
                        state.toggleTask(tasks[num - 1].name)
                    }
                }

                // Redisplay
                print("\nSelected: \(state.selectedTasks.sorted().joined(separator: ", "))")
                print("Enter more numbers, 'all', or 'done':")
            }
        }

        // Step 2: Configure parameters
        try configureParameters(state: state)

        // Step 3: Confirm and execute
        try confirmAndExecute(state: state)
    }

    /// Parameter configuration
    private func configureParameters(state: MenuState) throws {
        TerminalUI.clearScreen()
        TerminalUI.displayHeader("Configure Parameters")

        print("Current configuration:")
        print("  Duration: \(state.duration) seconds")
        print("  Size: \(state.size ?? 4096)")
        print("  Batch Size: \(state.batchSize ?? 32)")
        print("  Threads: \(state.threads ?? ProcessInfo.processInfo.processorCount)")
        print()

        if TerminalUI.confirm(message: "Customize parameters?") {
            if let dur = TerminalUI.readInt(prompt: "Duration (1-3600 seconds)", min: 1, max: 3600, defaultValue: state.duration) {
                state.duration = dur
            }

            if let s = TerminalUI.readInt(prompt: "Size (128-8192)", min: 128, max: 8192, defaultValue: state.size ?? 4096) {
                state.size = s
            }

            if let bs = TerminalUI.readInt(prompt: "Batch Size (1-1024)", min: 1, max: 1024, defaultValue: state.batchSize ?? 32) {
                state.batchSize = bs
            }

            if let t = TerminalUI.readInt(prompt: "Threads (1-\(ProcessInfo.processInfo.processorCount))", min: 1, max: ProcessInfo.processInfo.processorCount, defaultValue: state.threads ?? ProcessInfo.processInfo.processorCount) {
                state.threads = t
            }
        }
    }

    /// Confirmation and execution
    private func confirmAndExecute(state: MenuState) throws {
        // Check if remote machines configured
        let profileStore = MachineProfileStore()
        let allMachines = profileStore.getAllMachines()

        // Offer multi-machine execution if machines available
        if !allMachines.isEmpty {
            try selectMachinesForExecution(state: state, availableMachines: allMachines)
        }

        TerminalUI.clearScreen()
        TerminalUI.displayHeader("Confirm Execution")

        print(state.configurationSummary())
        print()

        if !TerminalUI.confirm(message: "Execute benchmarks?") {
            print("Execution cancelled")
            TerminalUI.pause()
            return
        }

        // Build parameter overrides
        var parameterOverrides: [String: [String: AnyCodable]] = [:]

        for taskName in state.selectedTasks {
            var taskParams: [String: AnyCodable] = [:]
            taskParams["duration"] = AnyCodable(state.duration)

            if let bs = state.batchSize {
                taskParams["batch_size"] = AnyCodable(bs)
            }
            if let s = state.size {
                taskParams["size"] = AnyCodable(s)
            }
            if let t = state.threads {
                taskParams["threads"] = AnyCodable(t)
            }

            parameterOverrides[taskName] = taskParams
        }

        // Check if multi-machine execution
        let selectedRemotes = allMachines.filter { state.selectedMachines.contains($0.id) }

        if selectedRemotes.isEmpty {
            // Local only execution
            print("\n")
            let hardware = try HardwareDetector.detect()

            let config = BenchmarkConfiguration(
                selectedTasks: Array(state.selectedTasks),
                parameterOverrides: parameterOverrides,
                hardware: hardware
            )

            let executor = BenchmarkExecutor()
            _ = try executor.execute(configuration: config)

        } else {
            // Multi-machine execution
            print("\nExecuting across \(state.includeLocal ? 1 + selectedRemotes.count : selectedRemotes.count) machines...\n")

            let multiExecutor = MultiMachineExecutor()

            Task {
                do {
                    let run = try await multiExecutor.execute(
                        localIncluded: state.includeLocal,
                        remoteMachines: selectedRemotes,
                        tasks: Array(state.selectedTasks),
                        parameterOverrides: parameterOverrides
                    )

                    // Display comparison
                    print(MultiMachineResultFormatter.format(run))

                    // Offer to export
                    if TerminalUI.confirm(message: "\nExport multi-machine results?") {
                        let filename = "results/multi-machine-\(Date().timeIntervalSince1970).json"
                        try MultiMachineExporter.export(run: run, to: filename)
                        print("✓ Results exported to: \(filename)")
                    }

                } catch {
                    print("\n✗ Multi-machine execution failed: \(error.localizedDescription)")
                }
            }

            // Wait for async execution to complete
            sleep(UInt32(state.duration * (state.includeLocal ? 1 + selectedRemotes.count : selectedRemotes.count) + 10))
        }

        TerminalUI.pause(message: "\nBenchmarks complete. Press Enter to return to menu...")
    }

    /// Machine selection for multi-machine execution
    private func selectMachinesForExecution(state: MenuState, availableMachines: [RemoteMachine]) throws {
        if !TerminalUI.confirm(message: "\nRun on remote machines?") {
            return
        }

        TerminalUI.clearScreen()
        TerminalUI.displayHeader("Select Machines")

        print("Local Machine:")
        print("  1. [\(state.includeLocal ? "x" : " ")] Local (\(try HardwareDetector.detect().chipIdentifier))")

        print("\nRemote Machines:")
        if availableMachines.isEmpty {
            print("  (none configured)")
        } else {
            for (index, machine) in availableMachines.enumerated() {
                let marker = state.selectedMachines.contains(machine.id) ? "x" : " "
                let hardwareInfo = machine.hardwareProfile?.chipIdentifier ?? "Unknown"
                let deployStatus = machine.deploymentStatus == .deployed ? "Deployed" : "Not Deployed"
                print("  \(index + 2). [\(marker)] \(machine.name) (\(hardwareInfo)) - [\(deployStatus)]")
            }
        }

        print("\nEnter numbers to toggle, or 'done' to continue:")

        var selecting = true
        while selecting {
            let input = TerminalUI.readInput(prompt: ">")

            if input.lowercased() == "done" || input.isEmpty {
                selecting = false
            } else {
                let numbers = input.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

                for num in numbers {
                    if num == 1 {
                        state.includeLocal.toggle()
                    } else if num >= 2 && num <= availableMachines.count + 1 {
                        state.toggleMachine(availableMachines[num - 2].id)
                    }
                }

                print("Selected: \(state.includeLocal ? "local" : "") \(state.selectedMachines.count) remote")
                print("Enter more numbers or 'done':")
            }
        }
    }

    /// Remote machine management flow
    private func manageMachinesFlow() throws {
        let profileStore = MachineProfileStore()

        var exitFlow = false

        while !exitFlow {
            TerminalUI.clearScreen()
            TerminalUI.displayHeader("Manage Remote Machines")

            let machines = profileStore.getAllMachines()

            print("Configured machines:")
            if machines.isEmpty {
                print("  (none)")
            } else {
                for (index, machine) in machines.enumerated() {
                    let statusIcon = machine.deploymentStatus == .deployed ? "✓" : "○"
                    print("  \(index + 1). \(statusIcon) \(machine.name) - \(machine.hostname)")
                }
            }

            print("\nOptions:")
            print("1. Add New Machine")
            print("2. Deploy to Machine")
            print("3. Remove Machine")
            print("4. Back to Main Menu")
            print()

            let choice = TerminalUI.readInput(prompt: "Select option (1-4):")

            switch choice {
            case "1":
                try addMachineFlow(profileStore: profileStore)
            case "2":
                try deployToMachineFlow(profileStore: profileStore)
            case "3":
                try removeMachineFlow(profileStore: profileStore)
            case "4", "back", "exit":
                exitFlow = true
            default:
                print("Invalid choice")
                TerminalUI.pause()
            }
        }
    }

    /// Add new remote machine
    private func addMachineFlow(profileStore: MachineProfileStore) throws {
        TerminalUI.clearScreen()
        TerminalUI.displayHeader("Add Remote Machine")

        let name = TerminalUI.readInput(prompt: "Machine name (e.g., 'Mac Studio'):")
        guard !name.isEmpty else {
            print("Name cannot be empty")
            TerminalUI.pause()
            return
        }

        let hostname = TerminalUI.readInput(prompt: "Hostname or IP address:")
        guard !hostname.isEmpty else {
            print("Hostname cannot be empty")
            TerminalUI.pause()
            return
        }

        let username = TerminalUI.readInput(prompt: "Username:")
        guard !username.isEmpty else {
            print("Username cannot be empty")
            TerminalUI.pause()
            return
        }

        let sshKey = TerminalUI.readInput(prompt: "SSH key path [~/.ssh/id_ed25519]:")
        let keyPath = sshKey.isEmpty ? "~/.ssh/id_ed25519" : sshKey

        var machine = RemoteMachine(name: name, hostname: hostname, username: username, sshKeyPath: keyPath)

        // Validate
        do {
            try machine.validate()
        } catch {
            print("Error: \(error.localizedDescription)")
            TerminalUI.pause()
            return
        }

        // Test connection
        print("\nTesting connection...")
        let client = SSHClient(machine: machine)

        do {
            try client.testConnection(timeout: 10)
            print("✓ Connection successful")

            // Save profile
            try profileStore.save(machine: machine)
            print("✓ Machine profile saved")

        } catch {
            print("✗ Connection failed: \(error.localizedDescription)")
            if TerminalUI.confirm(message: "Save anyway?") {
                try profileStore.save(machine: machine)
                print("✓ Machine profile saved (not deployed)")
            }
        }

        TerminalUI.pause()
    }

    /// Deploy to selected machine
    private func deployToMachineFlow(profileStore: MachineProfileStore) throws {
        let machines = profileStore.getAllMachines()

        guard !machines.isEmpty else {
            print("\nNo machines configured. Add a machine first.")
            TerminalUI.pause()
            return
        }

        TerminalUI.clearScreen()
        TerminalUI.displayHeader("Deploy to Machine")

        print("Select machine to deploy to:")
        for (index, machine) in machines.enumerated() {
            print("\(index + 1). \(machine.name) - \(machine.hostname)")
        }

        let choice = TerminalUI.readInput(prompt: "\nSelect machine (1-\(machines.count)):")

        guard let index = Int(choice), index >= 1, index <= machines.count else {
            print("Invalid selection")
            TerminalUI.pause()
            return
        }

        var machine = machines[index - 1]

        // Check deployment status
        print("\nChecking deployment status...")
        let deploymentManager = DeploymentManager(machine: machine)

        do {
            let status = try deploymentManager.checkVersion()

            switch status {
            case .deployed:
                print("✓ Already deployed (up to date)")
                if !TerminalUI.confirm(message: "Redeploy anyway?") {
                    TerminalUI.pause()
                    return
                }
            case .updateAvailable:
                print("○ Update available")
                if !TerminalUI.confirm(message: "Deploy update?") {
                    TerminalUI.pause()
                    return
                }
            case .notDeployed:
                print("○ Not deployed")
            default:
                break
            }

            // Deploy
            try deploymentManager.deploy()

            // Update machine status
            machine.deploymentStatus = .deployed
            machine.lastDeployed = Date()

            // Detect hardware
            print("\nDetecting remote hardware...")
            let client = SSHClient(machine: machine)
            let hardwareResult = try client.executeCommand("\(machine.deploymentPath) hardware --json")

            if hardwareResult.isSuccess {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                if let data = hardwareResult.stdout.data(using: .utf8),
                   let hardwareWrapper = try? decoder.decode(HardwareWrapper.self, from: data) {
                    machine.hardwareProfile = hardwareWrapper.hardwareProfile.toHardwareProfile()
                    print("✓ Detected: \(machine.hardwareProfile?.chipIdentifier ?? "Unknown")")
                }
            }

            machine.lastConnected = Date()
            try profileStore.save(machine: machine)

            print("\n✓ Deployment complete!")

        } catch {
            print("\n✗ Deployment failed: \(error.localizedDescription)")
        }

        TerminalUI.pause()
    }

    /// Remove machine
    private func removeMachineFlow(profileStore: MachineProfileStore) throws {
        let machines = profileStore.getAllMachines()

        guard !machines.isEmpty else {
            print("\nNo machines configured.")
            TerminalUI.pause()
            return
        }

        TerminalUI.clearScreen()
        TerminalUI.displayHeader("Remove Machine")

        print("Select machine to remove:")
        for (index, machine) in machines.enumerated() {
            print("\(index + 1). \(machine.name) - \(machine.hostname)")
        }

        let choice = TerminalUI.readInput(prompt: "\nSelect machine (1-\(machines.count)):")

        guard let index = Int(choice), index >= 1, index <= machines.count else {
            print("Invalid selection")
            TerminalUI.pause()
            return
        }

        let machine = machines[index - 1]

        if TerminalUI.confirm(message: "Remove '\(machine.name)'?") {
            try profileStore.remove(machineId: machine.id)
            print("✓ Machine removed")
        }

        TerminalUI.pause()
    }
}

// Hardware wrapper for JSON parsing
private struct HardwareWrapper: Codable {
    let hardwareProfile: HardwareProfileData
}

private struct HardwareProfileData: Codable {
    let modelName: String
    let chipIdentifier: String
    let gpuCoreCount: Int
    let totalMemoryGB: Int
    let macOSVersion: String

    func toHardwareProfile() -> HardwareProfile {
        return HardwareProfile(
            modelName: modelName,
            chipIdentifier: chipIdentifier,
            gpuCoreCount: gpuCoreCount,
            totalMemoryGB: totalMemoryGB,
            gpuMemoryGB: totalMemoryGB,  // Approximation
            macOSVersion: macOSVersion,
            detectionTimestamp: Date()
        )
    }
}

