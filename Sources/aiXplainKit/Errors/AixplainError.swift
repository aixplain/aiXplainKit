import Foundation

/// Root error for all aiXplain SDK v2 operations.
///
/// Mirrors Python v2 `AixplainV2Error` hierarchy with Swift enum exhaustive matching.
public enum AixplainError: Error, Sendable, LocalizedError {
    case auth(AuthError)
    case api(APIError)
    case validation(ValidationError)
    case timeout(TimeoutError)
    case fileUpload(FileUploadError)
    case resource(ResourceError)

    public var errorDescription: String? { userMessage }

    /// User-facing message for display in UI, distinct from developer-facing `localizedDescription`.
    public var userMessage: String {
        switch self {
        case .auth(let e):
            return e.errorDescription ?? "Authentication failed"
        case .api(let e):
            return e.userMessage
        case .validation(let e):
            return e.message
        case .timeout(let e):
            return e.message
        case .fileUpload(let e):
            return e.message
        case .resource(let e):
            return e.message
        }
    }
}
