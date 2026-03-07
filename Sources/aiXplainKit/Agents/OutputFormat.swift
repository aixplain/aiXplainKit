import Foundation

/// Output format options for agent responses.
///
/// Mirrors Python v2 `OutputFormat` from `agent.py`.
public enum OutputFormat: String, Codable, Sendable {
    case markdown
    case text
    case json
}
