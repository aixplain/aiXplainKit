import Foundation

/// How the SDK authenticates against the aiXplain platform.
///
/// Matches Python v2 contract: exactly one key type per client instance.
/// - `aixplainKey`: Platform-scoped key → header `x-aixplain-key`
/// - `teamKey`: Team-scoped key → header `x-api-key`
public enum AuthenticationScheme: Sendable, Codable, Equatable {
    case aixplainKey(String)
    case teamKey(String)

    var key: String {
        switch self {
        case .aixplainKey(let k), .teamKey(let k):
            return k
        }
    }
}
