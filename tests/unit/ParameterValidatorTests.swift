import XCTest
@testable import MacMLBench

final class ParameterValidatorTests: XCTestCase {
    func testRangeValidation() throws {
        // Test valid range
        let constraint = ParameterConstraint.range(min: 1, max: 100)
        XCTAssertNoThrow(try constraint.validate(50, parameterName: "test"))

        // Test out of range - below minimum
        XCTAssertThrowsError(try constraint.validate(0, parameterName: "test")) { error in
            XCTAssertTrue(error is ParameterError)
        }

        // Test out of range - above maximum
        XCTAssertThrowsError(try constraint.validate(101, parameterName: "test")) { error in
            XCTAssertTrue(error is ParameterError)
        }
    }

    func testTypeMismatch() throws {
        let constraint = ParameterConstraint.range(min: 1, max: 100)

        // Test type mismatch (String instead of Int)
        XCTAssertThrowsError(try constraint.validate("not_a_number", parameterName: "test")) { error in
            XCTAssertTrue(error is ParameterError)
        }
    }

    func testCrossParameterValidation() throws {
        // Create mock task and hardware
        var task = BenchmarkTask(
            name: "test",
            displayName: "Test",
            taskType: .processing,
            description: "Test benchmark",
            defaultParameters: ["batch_size": AnyCodable(32), "size": AnyCodable(4096)]
        )

        task.parameterConstraints = [
            "batch_size": .range(min: 1, max: 1024),
            "size": .range(min: 128, max: 8192)
        ]

        let hardware = HardwareProfile(
            modelName: "Test Mac",
            chipIdentifier: "M2 Max",
            gpuCoreCount: 38,
            totalMemoryGB: 32,
            gpuMemoryGB: 16,
            macOSVersion: "14.0",
            detectionTimestamp: Date()
        )

        // Test valid parameters
        let validParams: [String: Any] = ["batch_size": 32, "size": 2048]
        XCTAssertNoThrow(try ParameterValidator.validate(parameters: validParams, against: task, hardware: hardware))

        // Test excessive memory usage
        let excessiveParams: [String: Any] = ["batch_size": 1024, "size": 8192]
        XCTAssertThrowsError(try ParameterValidator.validate(parameters: excessiveParams, against: task, hardware: hardware))
    }
}
