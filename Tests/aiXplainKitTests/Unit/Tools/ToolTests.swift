import XCTest
@testable import aiXplainKit

final class ToolTests: XCTestCase {

    func test_tool_resourcePath() {
        XCTAssertEqual(Tool.resourcePath, "v2/tools")
    }

    func test_tool_isSubclassOfModel() {
        let tool = Tool(id: "t1", name: "Test Tool")
        XCTAssertTrue(tool is Model)
    }

    func test_tool_from_dict() throws {
        let aix = try Aixplain(apiKey: "test-key")
        let dict: [String: Any] = [
            "id": "tool-123",
            "name": "Slack Tool",
            "description": "Send messages to Slack",
            "allowedActions": ["send_message", "upload_file"],
            "actionsAvailable": true,
            "vendor": ["code": "aixplain"],
            "function": ["id": "utilities"],
            "version": ["id": "1.0"]
        ]

        let tool = try Tool.from(dict: dict, context: aix)
        XCTAssertEqual(tool.id, "tool-123")
        XCTAssertEqual(tool.name, "Slack Tool")
        XCTAssertEqual(tool.allowedActions, ["send_message", "upload_file"])
        XCTAssertEqual(tool.actionsAvailable, true)
    }

    func test_tool_asAgentTool_includesActions() throws {
        let aix = try Aixplain(apiKey: "test-key")
        let dict: [String: Any] = [
            "id": "tool-abc",
            "name": "My Tool",
            "allowedActions": ["action1", "action2"],
            "vendor": ["code": "aixplain"],
            "function": ["id": "utilities"],
            "version": ["id": "v1"]
        ]
        let tool = try Tool.from(dict: dict, context: aix)
        let agentTool = tool.asAgentTool()

        XCTAssertEqual(agentTool.type, .tool)
        XCTAssertEqual(agentTool.actions, ["action1", "action2"])
        XCTAssertEqual(agentTool.id, "tool-abc")
    }

    func test_tool_asAgentTool_noActions() throws {
        let tool = Tool(id: "t1", name: "Simple")
        let agentTool = tool.asAgentTool()
        XCTAssertEqual(agentTool.type, .tool)
        XCTAssertNil(agentTool.actions)
    }
}

final class IntegrationTests: XCTestCase {

    func test_integration_resourcePath() {
        XCTAssertEqual(Integration.resourcePath, "v2/integrations")
    }

    func test_integration_isSubclassOfModel() {
        let integration = Integration(id: "i1")
        XCTAssertTrue(integration is Model)
    }

    func test_integration_from_dict() throws {
        let aix = try Aixplain(apiKey: "test-key")
        let dict: [String: Any] = [
            "id": "int-123",
            "name": "Slack Integration",
            "actionsAvailable": true
        ]
        let integration = try Integration.from(dict: dict, context: aix)
        XCTAssertEqual(integration.id, "int-123")
        XCTAssertEqual(integration.actionsAvailable, true)
    }
}

final class ActionTests: XCTestCase {

    func test_action_from_dict() {
        let dict: [String: Any] = [
            "name": "send_message",
            "description": "Send a message",
            "slug": "send_msg",
            "inputs": [
                ["name": "channel", "datatype": "string", "required": true],
                ["name": "text", "datatype": "string", "required": true]
            ]
        ]
        let action = Action.from(dict)
        XCTAssertEqual(action.name, "send_message")
        XCTAssertEqual(action.slug, "send_msg")
        XCTAssertEqual(action.inputs?.count, 2)
        XCTAssertEqual(action.inputs?.first?.name, "channel")
        XCTAssertEqual(action.inputs?.first?.required, true)
    }

    func test_actionInput_from_dict() {
        let dict: [String: Any] = [
            "name": "temperature",
            "code": "temp",
            "datatype": "number",
            "required": false,
            "fixed": false,
            "description": "Sampling temperature"
        ]
        let input = ActionInput.from(dict)
        XCTAssertEqual(input.name, "temperature")
        XCTAssertEqual(input.code, "temp")
        XCTAssertEqual(input.datatype, "number")
        XCTAssertFalse(input.required)
    }
}
