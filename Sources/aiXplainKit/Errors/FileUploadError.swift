import Foundation

/// File upload operation failure.
///
/// Mirrors Python v2 `FileUploadError`.
public struct FileUploadError: Error, Sendable, LocalizedError, Equatable {
    public let message: String
    public let fileName: String?

    public init(_ message: String, fileName: String? = nil) {
        self.message = message
        self.fileName = fileName
    }

    public var errorDescription: String? { message }
}
