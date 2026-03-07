import Foundation

/// Client-side validation error thrown before a request is sent.
///
/// Mirrors Python v2 `ValidationError`.
public struct ValidationError: Error, Sendable, LocalizedError, Equatable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }
}
