import Foundation

/// Polling exceeded its retry/time budget.
///
/// Mirrors Python v2 `TimeoutError`.
public struct TimeoutError: Error, Sendable, LocalizedError {
    public let message: String
    public let pollingURL: String?
    public let timeout: TimeInterval?

    public init(_ message: String, pollingURL: String? = nil, timeout: TimeInterval? = nil) {
        self.message = message
        self.pollingURL = pollingURL
        self.timeout = timeout
    }

    public var errorDescription: String? { message }
}
