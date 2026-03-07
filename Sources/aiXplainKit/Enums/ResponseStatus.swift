import Foundation

/// Response status for polling operations.
///
/// Mirrors Python v2 `ResponseStatus` enum from `enums.py`.
public enum ResponseStatus: String, Codable, Sendable {
    case inProgress = "IN_PROGRESS"
    case success = "SUCCESS"
    case failed = "FAILED"
}
