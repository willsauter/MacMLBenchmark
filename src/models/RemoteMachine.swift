import Foundation

/// Represents a remote Mac machine for benchmark execution
struct RemoteMachine: Codable, Identifiable {
    let id: UUID
    var name: String
    var hostname: String
    var username: String
    var sshKeyPath: String
    var deploymentPath: String
    var deploymentStatus: DeploymentState
    var hardwareProfile: HardwareProfile?
    var lastDeployed: Date?
    var lastConnected: Date?

    init(
        name: String,
        hostname: String,
        username: String,
        sshKeyPath: String = "~/.ssh/id_ed25519",
        deploymentPath: String = "~/macmlbench"
    ) {
        self.id = UUID()
        self.name = name
        self.hostname = hostname
        self.username = username
        self.sshKeyPath = sshKeyPath
        self.deploymentPath = deploymentPath
        self.deploymentStatus = .notDeployed
        self.hardwareProfile = nil
        self.lastDeployed = nil
        self.lastConnected = nil
    }

    /// Validates machine configuration
    func validate() throws {
        guard !hostname.isEmpty else {
            throw RemoteMachineError.invalidHostname(hostname)
        }

        guard !username.isEmpty else {
            throw RemoteMachineError.invalidUsername(username)
        }

        // Expand tilde in SSH key path
        let expandedKeyPath = NSString(string: sshKeyPath).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedKeyPath) else {
            throw RemoteMachineError.sshKeyNotFound(sshKeyPath)
        }
    }
}

enum RemoteMachineError: Error, LocalizedError {
    case invalidHostname(String)
    case invalidUsername(String)
    case sshKeyNotFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidHostname(let host):
            return "Invalid hostname: '\(host)'"
        case .invalidUsername(let user):
            return "Invalid username: '\(user)'"
        case .sshKeyNotFound(let path):
            return "SSH key not found at: \(path)"
        }
    }
}
