import Foundation
import OSLog

/// Integration resource for connecting external services.
///
/// Mirrors Python v2 `Integration(Model, ActionMixin)` from `integration.py`.
/// Integrations create Tools via `connect()`.
public final class Integration: Model {
    private static let integrationLogger = Logger(subsystem: "aiXplainKit", category: "Integration")
    public override class var resourcePath: String { "v2/integrations" }

    public var actionsAvailable: Bool?

    // MARK: - Init

    public required init(id: String? = nil, name: String? = nil, description: String? = nil, context: Aixplain? = nil) {
        super.init(id: id, name: name, description: description, context: context)
    }

    public required convenience init() {
        self.init(id: nil, name: nil, description: nil, context: nil)
    }

    // MARK: - Get

    public class func getIntegration(_ id: String, context: Aixplain) async throws -> Integration {
        try await performGet(id, context: context, type: Integration.self)
    }

    // MARK: - Connect

    /// Connect the integration, creating a Tool.
    /// Mirrors Python v2 `integration.connect()`:
    ///   response = self.run(**kwargs)
    ///   tool_id = response.data.id
    ///   return self.context.Tool.get(tool_id)
    public func connect(
        name: String? = nil,
        description: String? = nil,
        config: [String: Any]? = nil
    ) async throws -> Tool {
        try ensureValidState()
        let ctx = try ensureContext()

        var payload: [String: Any] = [:]
        if let name { payload["name"] = name }
        if let description { payload["description"] = description }
        if let config {
            var data = config
            if let code = data.removeValue(forKey: "code") {
                data["code"] = code
            }
            payload["data"] = data
        }

        let runURL = try buildRunURL()
        let response = try await ctx.client.post(runURL, json: payload)

        let toolId: String
        if let dataDict = response["data"] as? [String: Any], let id = dataDict["id"] as? String {
            toolId = id
        } else if let dataStr = response["data"] as? String {
            toolId = dataStr
        } else {
            throw AixplainError.resource(ResourceError("Integration connect did not return a tool ID"))
        }

        return try await Tool.getTool(toolId, context: ctx)
    }

    // MARK: - Actions

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

    // MARK: - Deserialization

    public override class func from(dict: [String: Any], context: Aixplain) throws -> Self {
        let instance = try super.from(dict: dict, context: context)
        instance.actionsAvailable = dict["actionsAvailable"] as? Bool
        return instance
    }
}
