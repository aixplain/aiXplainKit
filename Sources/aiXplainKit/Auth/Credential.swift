import Foundation

/// Resolved, validated credential ready for use in HTTP requests.
///
/// Immutable once created -- matches Python v2 pattern where session headers
/// are set once during `__init__` and reused for all requests.
///
/// Resolution order (mirrors Python v2 `core.py`):
/// 1. Explicit `apiKey` parameter → `.teamKey`
/// 2. `TEAM_API_KEY` environment variable → `.teamKey`
/// 3. `AIXPLAIN_API_KEY` environment variable → `.aixplainKey`
/// 4. Throw `AuthError.noCredentialFound`
public struct Credential: Sendable, Equatable, Codable {
    public let scheme: AuthenticationScheme

    /// Validates and creates a credential.
    ///
    /// - Throws: `AuthError.emptyKey` if the key string is empty or whitespace-only.
    public init(scheme: AuthenticationScheme) throws {
        guard !scheme.key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthError.emptyKey
        }
        self.scheme = scheme
    }

    /// Builds the HTTP headers for this credential.
    ///
    /// Returns a dictionary containing the auth header and `Content-Type`.
    /// Matches the Python v2 header contract:
    /// - `aixplainKey` → `x-aixplain-key: <key>`
    /// - `teamKey` → `x-api-key: <key>`
    public func authHeaders() -> [String: String] {
        var headers = ["Content-Type": "application/json"]
        switch scheme {
        case .aixplainKey(let key):
            headers["x-aixplain-key"] = key
        case .teamKey(let key):
            headers["x-api-key"] = key
        }
        return headers
    }

    /// Resolves a credential from an explicit value or environment variables.
    ///
    /// - Parameters:
    ///   - apiKey: Explicit API key (takes priority). Resolved as `.teamKey`.
    ///   - environment: Environment dictionary (defaults to `ProcessInfo`).
    /// - Throws: `AuthError.noCredentialFound` if no key can be resolved.
    public static func resolve(
        apiKey: String? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> Credential {
        if let key = apiKey, !key.isEmpty {
            return try Credential(scheme: .teamKey(key))
        }
        if let envKey = environment["TEAM_API_KEY"], !envKey.isEmpty {
            return try Credential(scheme: .teamKey(envKey))
        }
        if let envKey = environment["AIXPLAIN_API_KEY"], !envKey.isEmpty {
            return try Credential(scheme: .aixplainKey(envKey))
        }
        throw AuthError.noCredentialFound
    }
}
