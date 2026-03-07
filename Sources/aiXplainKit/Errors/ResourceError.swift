import Foundation

/// Resource-level operation failure (not found, invalid state, context missing).
///
/// Mirrors Python v2 `ResourceError`.
public struct ResourceError: Error, Sendable, LocalizedError, Equatable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }
}
