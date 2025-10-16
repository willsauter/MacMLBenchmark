import XCTest
@testable import MacMLBench

final class SSHClientTests: XCTestCase {
    func testMachineValidation() throws {
        // Valid machine
        let validMachine = RemoteMachine(
            name: "Test Mac",
            hostname: "10.20.1.64",
            username: "testuser",
            sshKeyPath: "~/.ssh/id_ed25519"
        )

        // Should not throw if SSH key exists
        // Note: Actual validation depends on file system state

        // Invalid hostname
        var invalidMachine = validMachine
        invalidMachine.hostname = ""

        XCTAssertThrowsError(try invalidMachine.validate())
    }

    func testConnectionStateTransitions() {
        let machine = RemoteMachine(name: "Test", hostname: "test.local", username: "user")
        let connection = SSHConnection(machine: machine)

        // Initial state
        XCTAssertEqual(connection.connectionState, .disconnected)

        // Mark as failed
        connection.fail(error: "Test error")
        XCTAssertEqual(connection.connectionState, .failed)
        XCTAssertEqual(connection.errorMessage, "Test error")

        // Disconnect
        connection.disconnect()
        XCTAssertEqual(connection.connectionState, .disconnected)
    }
}
