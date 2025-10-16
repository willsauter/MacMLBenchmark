import Foundation

/// Represents an SSH connection to a remote machine
class SSHConnection {
    let machine: RemoteMachine
    var connectionState: ConnectionState
    var process: Process?
    var errorMessage: String?

    init(machine: RemoteMachine) {
        self.machine = machine
        self.connectionState = .disconnected
        self.process = nil
        self.errorMessage = nil
    }

    /// Marks connection as active
    func connect(process: Process) {
        self.process = process
        self.connectionState = .connected
    }

    /// Marks connection as failed
    func fail(error: String) {
        self.errorMessage = error
        self.connectionState = .failed
        self.process = nil
    }

    /// Disconnects
    func disconnect() {
        self.process?.terminate()
        self.process = nil
        self.connectionState = .disconnected
    }
}
