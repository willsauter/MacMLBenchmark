import Foundation

/// State of SSH connection to remote machine
enum ConnectionState: String, Codable {
    case connecting
    case connected
    case disconnected
    case failed
}
