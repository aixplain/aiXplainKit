//
//  ParrotLogger
//

import Foundation

extension ParrotLogger {

    /// The LogSeverity enumeration represents the severity level of log entries in ParrotLogger. It has seven cases for different levels of severity, from trace being the lowest to critical being the highest.
    public enum LogSeverity: String, Codable {
        case trace
        case debug
        case info
        case notice
        case warning
        case error
        case critical
    }
}

extension ParrotLogger.LogSeverity: Equatable, Comparable {

    /// This function is an implementation of the Comparable protocol's < operator for ParrotLogger.LogSeverity enum.
    /// - It returns a boolean value indicating whether the severity level represented by the left-hand side operand (lhs) is less than the severity level represented by the right-hand side operand (rhs). It compares the severity levels by converting them to integers using the asInt computed property and then comparing the integer values.
    public static func < (lhs: ParrotLogger.LogSeverity, rhs: ParrotLogger.LogSeverity) -> Bool {
        lhs.asInt < rhs.asInt
    }

    private var asInt: Int {
        switch self {
        case .trace:    return 0
        case .debug:    return 1
        case .info:     return 2
        case .notice:   return 3
        case .warning:  return 4
        case .error:    return 5
        case .critical: return 6
        }
    }
}
