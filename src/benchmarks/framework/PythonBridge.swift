import Foundation

class PythonBridge {
    func execute(script: String, arguments: [String]) throws -> String {
        let process = Process()

        // Try to use venv python if available, otherwise system python
        let venvPython = "/Users/willsauter/Development/MacMLBenchmark/.venv/bin/python3"
        let pythonPath = FileManager.default.fileExists(atPath: venvPython) ? venvPython : "/usr/bin/python3"

        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [script] + arguments

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

        guard process.terminationStatus == 0 else {
            // Try to extract JSON error from stdout if present
            if stdout.contains("\"error\"") {
                return stdout  // Return JSON with error for parsing
            }
            throw PythonError.executionFailed(script, stderr.isEmpty ? "Exit code: \(process.terminationStatus)" : stderr)
        }

        return stdout
    }
}

enum PythonError: Error, LocalizedError {
    case executionFailed(String, String)

    var errorDescription: String? {
        switch self {
        case .executionFailed(let script, let details):
            return "Python script failed (\(script)):\n\(details)"
        }
    }
}
