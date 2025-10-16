import Foundation

/// SSH client for remote command execution
class SSHClient {
    let machine: RemoteMachine

    init(machine: RemoteMachine) {
        self.machine = machine
    }

    /// Tests SSH connection
    func testConnection(timeout: TimeInterval = 10) throws {
        let result = try executeCommand("echo 'connected'", timeout: timeout)
        guard result.exitCode == 0 else {
            throw SSHError.connectionFailed(machine.hostname, result.stderr)
        }
    }

    /// Executes command on remote machine
    func executeCommand(_ command: String, timeout: TimeInterval = 60) throws -> SSHResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")

        // SSH options
        var args = [
            "-o", "ConnectTimeout=\(Int(timeout))",
            "-o", "StrictHostKeyChecking=no",
            "-i", NSString(string: machine.sshKeyPath).expandingTildeInPath,
            "\(machine.username)@\(machine.hostname)",
            command
        ]

        process.arguments = args

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let stdout = String(data: outputData, encoding: .utf8) ?? ""
        let stderr = String(data: errorData, encoding: .utf8) ?? ""

        return SSHResult(
            exitCode: Int(process.terminationStatus),
            stdout: stdout,
            stderr: stderr
        )
    }

    /// Transfers file to remote machine
    func transferFile(localPath: String, remotePath: String, timeout: TimeInterval = 60) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/scp")

        let expandedRemotePath = remotePath.replacingOccurrences(of: "~", with: "/Users/\(machine.username)")

        process.arguments = [
            "-o", "ConnectTimeout=\(Int(timeout))",
            "-o", "StrictHostKeyChecking=no",
            "-i", NSString(string: machine.sshKeyPath).expandingTildeInPath,
            localPath,
            "\(machine.username)@\(machine.hostname):\(expandedRemotePath)"
        ]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw SSHError.transferFailed(localPath, stderr)
        }
    }

    /// Downloads file from remote machine
    func downloadFile(remotePath: String, localPath: String, timeout: TimeInterval = 60) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/scp")

        let expandedRemotePath = remotePath.replacingOccurrences(of: "~", with: "/Users/\(machine.username)")

        process.arguments = [
            "-o", "ConnectTimeout=\(Int(timeout))",
            "-o", "StrictHostKeyChecking=no",
            "-i", NSString(string: machine.sshKeyPath).expandingTildeInPath,
            "\(machine.username)@\(machine.hostname):\(expandedRemotePath)",
            localPath
        ]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw SSHError.downloadFailed(remotePath, stderr)
        }
    }
}

/// Result of SSH command execution
struct SSHResult {
    let exitCode: Int
    let stdout: String
    let stderr: String

    var isSuccess: Bool {
        return exitCode == 0
    }
}

enum SSHError: Error, LocalizedError {
    case connectionFailed(String, String)
    case transferFailed(String, String)
    case downloadFailed(String, String)
    case executionFailed(String, String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let host, let details):
            return "SSH connection failed to \(host): \(details)"
        case .transferFailed(let file, let details):
            return "File transfer failed for \(file): \(details)"
        case .downloadFailed(let file, let details):
            return "File download failed for \(file): \(details)"
        case .executionFailed(let command, let details):
            return "Command execution failed '\(command)': \(details)"
        }
    }
}
