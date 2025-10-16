import Foundation

/// Monitors system thermal state during benchmark execution
struct ThermalMonitor {
    /// Gets current thermal state
    static func currentState() -> ThermalState {
        let processInfoState = ProcessInfo.processInfo.thermalState
        return ThermalState(from: processInfoState)
    }

    /// Checks if thermal state warrants warning before execution
    static func shouldWarnBeforeExecution() -> Bool {
        let state = currentState()
        return state == .serious || state == .critical
    }

    /// Returns warning message for current thermal state
    static func warningMessage() -> String? {
        let state = currentState()

        switch state {
        case .serious:
            return """
            Warning: Thermal Throttling Possible

            Your Mac is running warm and GPU performance may be reduced.
            Results may not represent maximum performance.

            Suggestions:
              - Wait for system to cool down (check again in 5 minutes)
              - Ensure adequate ventilation
              - Close other GPU-intensive applications
              - Reduce --duration for shorter benchmarks

            Continue anyway? [y/N]:
            """

        case .critical:
            return """
            Warning: Thermal Throttling Active

            Your Mac is running hot and GPU performance is being actively reduced.
            Results will NOT be representative of maximum performance.

            Suggestions:
              - Wait for system to cool down (recommended)
              - Ensure adequate ventilation
              - Close ALL other applications
              - Consider running benchmarks during cooler times

            Continue anyway? [y/N]:
            """

        default:
            return nil
        }
    }

    /// Monitors thermal state during execution and returns final state
    static func monitorDuringExecution(duration: TimeInterval, callback: @escaping (ThermalState) -> Void) -> ThermalState {
        var peakState: ThermalState = .nominal
        let startTime = Date()

        // Sample thermal state every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= duration {
                timer.invalidate()
                return
            }

            let currentState = self.currentState()
            callback(currentState)

            // Track peak thermal state
            if currentState.rawValue > peakState.rawValue {
                peakState = currentState
            }
        }

        return peakState
    }
}

// Extension for thermal state comparison
extension ThermalState: Comparable {
    static func < (lhs: ThermalState, rhs: ThermalState) -> Bool {
        let order: [ThermalState] = [.nominal, .fair, .serious, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
