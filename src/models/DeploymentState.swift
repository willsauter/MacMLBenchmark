import Foundation

/// State of tool deployment on a remote machine
enum DeploymentState: String, Codable {
    case notDeployed
    case deploying
    case deployed
    case updateAvailable
}
