import Foundation

/// Authentication errors thrown during credential resolution and validation.
public enum AuthError: Error, Sendable, LocalizedError, Equatable {
    case noCredentialFound
    case emptyKey
    case bothKeysProvided

    public var errorDescription: String? {
        switch self {
        case .noCredentialFound:
            return "API key is required. Pass it as an argument or set the TEAM_API_KEY environment variable."
        case .emptyKey:
            return "API key must not be empty."
        case .bothKeysProvided:
            return "Either `aixplainKey` or `teamKey` should be set, not both."
        }
    }
}
