import Foundation

/// Manages deployment of benchmark tool to remote machines
class DeploymentManager {
    let sshClient: SSHClient
    let localBinaryPath: String
    let localVersion: String = "1.0.0"

    init(machine: RemoteMachine, localBinaryPath: String = ".build/release/macmlbench") {
        self.sshClient = SSHClient(machine: machine)
        self.localBinaryPath = localBinaryPath
    }

    /// Deploys benchmark tool to remote machine
    func deploy() throws {
        print("Deploying to \(sshClient.machine.hostname)...")

        // Transfer binary
        try sshClient.transferFile(
            localPath: localBinaryPath,
            remotePath: sshClient.machine.deploymentPath,
            timeout: 60
        )

        // Make executable
        _ = try sshClient.executeCommand("chmod +x \(sshClient.machine.deploymentPath)")

        // Verify deployment
        try verifyDeployment()

        print("✓ Deployment successful")
    }

    /// Verifies deployment by checking version
    func verifyDeployment() throws {
        let result = try sshClient.executeCommand("\(sshClient.machine.deploymentPath) version | head -2 | tail -1")

        guard result.isSuccess else {
            throw SSHError.executionFailed("version", result.stderr)
        }

        // Extract version from output (format: "Version: 1.0.0")
        if result.stdout.contains("Version") {
            print("✓ Remote tool verified")
        } else {
            throw SSHError.executionFailed("version", "Unexpected output format")
        }
    }

    /// Checks if update is needed
    func checkVersion() throws -> DeploymentState {
        // Check if binary exists
        let checkResult = try sshClient.executeCommand("[ -f \(sshClient.machine.deploymentPath) ] && echo 'exists' || echo 'missing'")

        if checkResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "missing" {
            return .notDeployed
        }

        // Get remote version
        let versionResult = try sshClient.executeCommand("\(sshClient.machine.deploymentPath) version | head -2 | tail -1")

        guard versionResult.isSuccess else {
            return .notDeployed  // Binary exists but not functional
        }

        // Compare versions (simplified - exact match check)
        if versionResult.stdout.contains(localVersion) {
            return .deployed
        } else {
            return .updateAvailable
        }
    }
}
