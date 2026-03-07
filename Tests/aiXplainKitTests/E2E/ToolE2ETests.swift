import XCTest
@testable import aiXplainKit

/// End-to-end tests for Tool and Integration against the real API.
final class ToolE2ETests: XCTestCase {

    private var aix: Aixplain!

    override func setUp() async throws {
        guard ProcessInfo.processInfo.environment["TEAM_API_KEY"] != nil else {
            throw XCTSkip("TEAM_API_KEY not set -- skipping E2E tests")
        }
        let backendURL = ProcessInfo.processInfo.environment["BACKEND_URL"]
            .flatMap { URL(string: $0) }
        let modelURL = ProcessInfo.processInfo.environment["MODELS_RUN_URL"]
            .flatMap { URL(string: $0) }
        aix = try Aixplain(backendURL: backendURL, modelURL: modelURL)
    }

    // MARK: - Tool Search

    func test_tool_search_returnsResults() async throws {
        let page = try await Tool.searchTools(pageSize: 5, context: aix)
        XCTAssertGreaterThanOrEqual(page.total, 0, "Tool search should return a total count")
    }

    // MARK: - Tool Get

    func test_tool_get_byId() async throws {
        let page = try await Tool.searchTools(pageSize: 1, context: aix)
        guard let firstTool = page.results.first, let toolId = firstTool.id else {
            throw XCTSkip("No tools found to test get()")
        }

        let fetched = try await Tool.getTool(toolId, context: aix)
        XCTAssertEqual(fetched.id, toolId)
        XCTAssertNotNil(fetched.name)
        XCTAssertFalse(fetched.isModified)
    }

    // MARK: - Tool asAgentTool

    func test_tool_asAgentTool_realTool() async throws {
        let page = try await Tool.searchTools(pageSize: 1, context: aix)
        guard let tool = page.results.first else {
            throw XCTSkip("No tools found")
        }

        let agentTool = tool.asAgentTool()
        XCTAssertEqual(agentTool.id, tool.id)
        XCTAssertEqual(agentTool.type, .tool)
    }

    // MARK: - Model as tool (cross-RFC: Model → AgentToolDict for agent use)

    func test_model_asAgentTool_forAgentUse() async throws {
        let page = try await Model.search(pageSize: 1, context: aix)
        guard let model = page.results.first else {
            throw XCTSkip("No models found")
        }

        let tool = model.asAgentTool()
        XCTAssertEqual(tool.type, .model)
        XCTAssertEqual(tool.id, model.id)

        let encoded = try JSONEncoder().encode(tool)
        let decoded = try JSONDecoder().decode(AgentToolDict.self, from: encoded)
        XCTAssertEqual(decoded.id, model.id)
    }
}
