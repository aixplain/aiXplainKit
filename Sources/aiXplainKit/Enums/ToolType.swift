import Foundation

/// Tool type categories for agent tool serialization.
///
/// Mirrors Python v2 `ToolDict["type"]` literal values.
public enum ToolType: String, Codable, Sendable {
    case model
    case pipeline
    case utility
    case tool
}
