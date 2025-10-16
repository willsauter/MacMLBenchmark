import XCTest
@testable import MacMLBench

final class MenuStateTests: XCTestCase {
    func testTaskSelection() {
        let state = MenuState()

        // Initially empty
        XCTAssertTrue(state.selectedTasks.isEmpty)

        // Toggle task
        state.toggleTask("matrix-multiply")
        XCTAssertTrue(state.selectedTasks.contains("matrix-multiply"))

        // Toggle again to remove
        state.toggleTask("matrix-multiply")
        XCTAssertFalse(state.selectedTasks.contains("matrix-multiply"))

        // Select all
        state.selectAllTasks(["task1", "task2", "task3"])
        XCTAssertEqual(state.selectedTasks.count, 3)

        // Reset
        state.reset()
        XCTAssertTrue(state.selectedTasks.isEmpty)
    }

    func testMachineSelection() {
        let state = MenuState()
        let machineId = UUID()

        // Initially include local
        XCTAssertTrue(state.includeLocal)
        XCTAssertTrue(state.selectedMachines.isEmpty)

        // Toggle remote machine
        state.toggleMachine(machineId)
        XCTAssertTrue(state.selectedMachines.contains(machineId))

        // Toggle again
        state.toggleMachine(machineId)
        XCTAssertFalse(state.selectedMachines.contains(machineId))
    }

    func testConfigurationSummary() {
        let state = MenuState()
        state.toggleTask("matrix-multiply")
        state.duration = 30

        let summary = state.configurationSummary()

        XCTAssertTrue(summary.contains("matrix-multiply"))
        XCTAssertTrue(summary.contains("30s"))
    }
}
