import Foundation
import OSLog

/// Tool resource -- subclass of Model (matches Python v2 `class Tool(Model, ...)`).
///
/// Tools are the primary mechanism for extending agent capabilities.
/// They can be created from integrations, run with action-based execution,
/// and serialized for agent tool lists via `asAgentTool()`.
public final class Tool: Model {
    private static let toolLogger = Logger(subsystem: "aiXplainKit", category: "Tool")
    public override class var resourcePath: String { "v2/tools" }
    public static let defaultIntegrationId = "686432941223092cb4294d3f"

    // MARK: - Tool-specific fields

    public var assetId: String?
    public var allowedActions: [String] = []
    public var actionsAvailable: Bool?
    public var code: String?

    // MARK: - Init

    public required init(id: String? = nil, name: String? = nil, description: String? = nil, context: Aixplain? = nil) {
        super.init(id: id, name: name, description: description, context: context)
    }

    public required convenience init() {
        self.init(id: nil, name: nil, description: nil, context: nil)
    }

    // MARK: - Get

    public class func getTool(_ id: String, context: Aixplain) async throws -> Tool {
        try await performGet(id, context: context, type: Tool.self)
    }

    // MARK: - Search

    public class func searchTools(
        query: String? = nil,
        pageNumber: Int = 0,
        pageSize: Int = 20,
        context: Aixplain
    ) async throws -> Page<Tool> {
        var filters: [String: Any] = [
            "pageNumber": pageNumber,
            "pageSize": pageSize,
            "sort": [[:] as [String: Any]]
        ]
        if let q = query { filters["q"] = q }
        return try await performSearch(filters: filters, context: context, type: Tool.self)
    }

    // MARK: - Run (action-based)

    /// Run the tool with an action. Falls back to single allowed action.
    /// Mirrors Python v2 `Tool.run()`.
    public func runTool(action: String? = nil, data: Any? = nil) async throws -> ModelResult {
        try ensureValidState()

        var resolvedAction = action
        if resolvedAction == nil {
            if allowedActions.count == 1 {
                resolvedAction = allowedActions.first
            } else {
                let available = try await listActions()
                if available.count == 1 {
                    resolvedAction = available.first?.name
                }
            }
        }

        guard let finalAction = resolvedAction else {
            throw AixplainError.validation(ValidationError("No action provided and tool has multiple actions"))
        }

        var payload: [String: Any] = ["action": finalAction]
        if let data { payload["data"] = data }

        return try await run(parameters: payload)
    }

    // MARK: - Actions

    /// List available actions for this tool.
    /// Mirrors Python v2 `ActionMixin.list_actions()`.
    public func listActions() async throws -> [Action] {
        guard actionsAvailable == true else { return [] }
        let runURL = try buildRunURL()
        let ctx = try ensureContext()
        let response = try await ctx.client.post(runURL, json: [
            "action": "LIST_ACTIONS",
            "data": [String: Any]()
        ] as [String: Any])

        guard let dataList = response["data"] as? [[String: Any]] else { return [] }
        return dataList.compactMap { Action.from($0) }
    }

    /// List inputs for specified actions.
    /// Mirrors Python v2 `ActionMixin.list_inputs()`.
    public func listInputs(_ actionNames: [String]) async throws -> [Action] {
        let runURL = try buildRunURL()
        let ctx = try ensureContext()
        let response = try await ctx.client.post(runURL, json: [
            "action": "LIST_INPUTS",
            "data": ["actions": actionNames]
        ] as [String: Any])

        guard let dataList = response["data"] as? [[String: Any]] else { return [] }
        return dataList.compactMap { Action.from($0) }
    }

    // MARK: - AgentToolConvertible (override)

    /// Override to include `actions` list for agent serialization.
    public override func asAgentTool() -> AgentToolDict {
        var dict = super.asAgentTool()
        dict.type = .tool
        if !allowedActions.isEmpty {
            dict.actions = allowedActions
        }
        return dict
    }

    // MARK: - Deserialization

    public override class func from(dict: [String: Any], context: Aixplain) throws -> Self {
        let instance = try super.from(dict: dict, context: context)
        instance.assetId = dict["assetId"] as? String
        instance.allowedActions = dict["allowedActions"] as? [String] ?? []
        instance.actionsAvailable = dict["actionsAvailable"] as? Bool
        instance.code = dict["code"] as? String
        return instance
    }
}
