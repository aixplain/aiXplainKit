import Foundation

/// AI model suppliers.
///
/// Mirrors Python v2 `Supplier` enum from `enums.py`.
public enum Supplier: String, Codable, Sendable {
    case openai = "OPENAI"
    case anthropic = "ANTHROPIC"
    case google = "GOOGLE"
    case meta = "META"
    case huggingface = "HUGGINGFACE"
    case cohere = "COHERE"
    case aixplain = "AIXPLAIN"
}
