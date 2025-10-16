import Foundation

/// Constraint on parameter values
enum ParameterConstraint {
    case range(min: Int, max: Int)
    case options([Any])
    case conditional(constraint: (Any) -> Bool, message: String)

    /// Validates a value against this constraint
    func validate(_ value: Any, parameterName: String) throws {
        switch self {
        case .range(let min, let max):
            guard let intValue = value as? Int else {
                throw ParameterError.typeMismatch(parameterName, expected: "Int", got: type(of: value))
            }
            guard intValue >= min && intValue <= max else {
                throw ParameterError.outOfRange(parameterName, value: intValue, min: min, max: max)
            }

        case .options(let validOptions):
            // Check if value matches any valid option
            let matches = validOptions.contains { option in
                if let intOption = option as? Int, let intValue = value as? Int {
                    return intOption == intValue
                }
                if let stringOption = option as? String, let stringValue = value as? String {
                    return stringOption == stringValue
                }
                return false
            }
            guard matches else {
                throw ParameterError.invalidOption(parameterName, value: value, options: validOptions)
            }

        case .conditional(let constraint, let message):
            guard constraint(value) else {
                throw ParameterError.constraintViolation(parameterName, message: message)
            }
        }
    }
}

enum ParameterError: Error, LocalizedError {
    case typeMismatch(String, expected: String, got: Any.Type)
    case outOfRange(String, value: Int, min: Int, max: Int)
    case invalidOption(String, value: Any, options: [Any])
    case constraintViolation(String, message: String)
    case missingRequired(String)

    var errorDescription: String? {
        switch self {
        case .typeMismatch(let name, let expected, let got):
            return "Parameter '\(name)': expected \(expected), got \(got)"
        case .outOfRange(let name, let value, let min, let max):
            return "Parameter '\(name)': value \(value) out of range [\(min), \(max)]"
        case .invalidOption(let name, let value, _):
            return "Parameter '\(name)': invalid value '\(value)'"
        case .constraintViolation(let name, let message):
            return "Parameter '\(name)': \(message)"
        case .missingRequired(let name):
            return "Required parameter '\(name)' is missing"
        }
    }
}
