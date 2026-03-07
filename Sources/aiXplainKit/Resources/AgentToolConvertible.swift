import Foundation

/// Any resource that can be serialized as an agent tool.
///
/// Mirrors Python v2 `ToolableMixin` ABC from `mixins.py`.
/// Conforming types: `Model` (RFC-0007), `Tool` (RFC-0008).
public protocol AgentToolConvertible {
    func asAgentTool() -> AgentToolDict
}
