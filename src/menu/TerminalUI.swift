import Foundation

/// Terminal UI utilities for interactive menu
class TerminalUI {
    /// Clears the terminal screen
    static func clearScreen() {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
        fflush(stdout)
    }

    /// Displays a header with separator
    static func displayHeader(_ title: String) {
        print("\n\(title)")
        print(String(repeating: "=", count: title.count))
        print()
    }

    /// Displays a numbered menu
    static func displayMenu(options: [String]) {
        for (index, option) in options.enumerated() {
            print("\(index + 1). \(option)")
        }
        print()
    }

    /// Reads user input with prompt
    static func readInput(prompt: String) -> String {
        print(prompt, terminator: " ")
        fflush(stdout)
        return readLine() ?? ""
    }

    /// Reads integer input with validation
    static func readInt(prompt: String, min: Int? = nil, max: Int? = nil, defaultValue: Int? = nil) -> Int? {
        var defaultText = ""
        if let def = defaultValue {
            defaultText = " [default: \(def)]"
        }

        let input = readInput(prompt: "\(prompt)\(defaultText):")

        // Use default if empty
        if input.isEmpty, let def = defaultValue {
            return def
        }

        guard let value = Int(input) else {
            print("Error: Invalid number")
            return nil
        }

        if let minimum = min, value < minimum {
            print("Error: Value must be at least \(minimum)")
            return nil
        }

        if let maximum = max, value > maximum {
            print("Error: Value must be at most \(maximum)")
            return nil
        }

        return value
    }

    /// Displays a message and waits for key press
    static func pause(message: String = "\nPress Enter to continue...") {
        print(message, terminator: "")
        fflush(stdout)
        _ = readLine()
    }

    /// Confirms an action
    static func confirm(message: String) -> Bool {
        let input = readInput(prompt: "\(message) (y/n):")
        return input.lowercased().hasPrefix("y")
    }
}
