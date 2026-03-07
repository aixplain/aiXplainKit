import Foundation

/// Serialization format for agent tools.
///
/// Mirrors Python v2 `ToolDict` TypedDict from `mixins.py`.
/// Used by `Agent.buildSavePayload()` to serialize tools into the agent creation/update payload.
public struct AgentToolDict: Codable, Sendable {
    public var id: String
    public var name: String
    public var description: String
    public var supplier: String
    public var parameters: [[String: AnyCodable]]?
    public var function: String
    public var type: ToolType
    public var version: String
    public var assetId: String
    public var actions: [String]?

    public init(
        id: String,
        name: String,
        description: String,
        supplier: String,
        parameters: [[String: AnyCodable]]? = nil,
        function: String,
        type: ToolType,
        version: String,
        assetId: String,
        actions: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.supplier = supplier
        self.parameters = parameters
        self.function = function
        self.type = type
        self.version = version
        self.assetId = assetId
        self.actions = actions
    }
}
