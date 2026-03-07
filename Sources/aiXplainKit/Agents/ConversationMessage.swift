import Foundation

/// Message role in a conversation.
public enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
}

/// A single message in a conversation history.
///
/// Mirrors Python v2 `ConversationMessage` TypedDict from `agent.py`.
public struct ConversationMessage: Codable, Sendable {
    public let role: MessageRole
    public let content: String

    public init(role: MessageRole, content: String) {
        self.role = role
        self.content = content
    }

    /// Validate a list of conversation messages.
    /// Mirrors Python v2 `validate_history()`.
    public static func validateHistory(_ history: [ConversationMessage]) throws {
        for (index, message) in history.enumerated() {
            guard !message.content.isEmpty else {
                throw AixplainError.validation(ValidationError(
                    "'content' at index \(index) must not be empty."
                ))
            }
        }
    }
}
