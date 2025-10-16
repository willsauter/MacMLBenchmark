import Foundation

/// Manages loading and saving SSH machine profiles
class MachineProfileStore {
    private let profilePath: String
    private var machines: [RemoteMachine] = []

    init(profilePath: String = "config/machines.json") {
        self.profilePath = profilePath
        loadProfiles()
    }

    /// Loads machine profiles from JSON file
    func loadProfiles() {
        let url = URL(fileURLWithPath: profilePath)

        guard FileManager.default.fileExists(atPath: profilePath) else {
            // No profiles yet
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let wrapper = try decoder.decode(MachineProfileWrapper.self, from: data)
            self.machines = wrapper.machines
        } catch {
            print("Warning: Failed to load machine profiles: \(error.localizedDescription)")
        }
    }

    /// Saves machine profiles to JSON file
    func saveProfiles() throws {
        let url = URL(fileURLWithPath: profilePath)

        // Create directory if needed
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let wrapper = MachineProfileWrapper(machines: machines)
        let data = try encoder.encode(wrapper)

        try data.write(to: url)
    }

    /// Adds or updates a machine profile
    func save(machine: RemoteMachine) throws {
        if let index = machines.firstIndex(where: { $0.id == machine.id }) {
            machines[index] = machine
        } else {
            machines.append(machine)
        }

        try saveProfiles()
    }

    /// Gets all configured machines
    func getAllMachines() -> [RemoteMachine] {
        return machines
    }

    /// Gets a machine by ID
    func getMachine(id: UUID) -> RemoteMachine? {
        return machines.first { $0.id == id }
    }

    /// Removes a machine
    func remove(machineId: UUID) throws {
        machines.removeAll { $0.id == machineId }
        try saveProfiles()
    }
}

private struct MachineProfileWrapper: Codable {
    let machines: [RemoteMachine]
}
