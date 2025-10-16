import Foundation

/// Deployment status on a remote machine
struct DeploymentStatus: Codable {
    var state: DeploymentState
    var deployedVersion: String?
    var deploymentTimestamp: Date?

    init(state: DeploymentState = .notDeployed) {
        self.state = state
        self.deployedVersion = nil
        self.deploymentTimestamp = nil
    }

    mutating func markDeployed(version: String) {
        self.state = .deployed
        self.deployedVersion = version
        self.deploymentTimestamp = Date()
    }

    mutating func markUpdateAvailable() {
        self.state = .updateAvailable
    }
}
