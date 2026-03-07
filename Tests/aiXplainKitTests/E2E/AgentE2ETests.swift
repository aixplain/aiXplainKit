import XCTest
@testable import aiXplainKit

/// End-to-end tests for Agent against the real aiXplain API.
final class AgentE2ETests: XCTestCase {

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

    // MARK: - Search

    func test_agent_search() async throws {
        let page = try await Agent.search(pageSize: 5, context: aix)
        XCTAssertGreaterThanOrEqual(page.total, 0)
    }

    // MARK: - Get

    func test_agent_get_byId() async throws {
        let page = try await Agent.search(pageSize: 1, context: aix)
        guard let firstAgent = page.results.first, let agentId = firstAgent.id else {
            throw XCTSkip("No agents found to test get()")
        }

        let fetched = try await Agent.get(agentId, context: aix)
        XCTAssertEqual(fetched.id, agentId)
        XCTAssertNotNil(fetched.name)
        XCTAssertFalse(fetched.isModified)
        XCTAssertNotNil(fetched.context)
    }

    // MARK: - Run

    func test_agent_run_simpleQuery() async throws {
        let page = try await Agent.search(pageSize: 1, context: aix)
        guard let agent = page.results.first, agent.id != nil else {
            throw XCTSkip("No agents found to test run()")
        }

        let fetched = try await Agent.get(agent.id!, context: aix)
        guard fetched.status == .onboarded else {
            throw XCTSkip("Agent is not onboarded (status: \(fetched.status))")
        }

        let result = try await fetched.run("Say hello in one word")
        XCTAssertEqual(result.status, "SUCCESS")
        XCTAssertTrue(result.completed)
        XCTAssertNotNil(result.data?.output)
        XCTAssertFalse(result.data!.output!.isEmpty, "Agent should return non-empty output")
    }

    // MARK: - Session

    func test_agent_generateSessionId() async throws {
        let page = try await Agent.search(pageSize: 1, context: aix)
        guard let agent = page.results.first, let agentId = agent.id else {
            throw XCTSkip("No agents found")
        }

        let fetched = try await Agent.get(agentId, context: aix)
        let sessionId = try await fetched.generateSessionId()
        XCTAssertTrue(sessionId.contains(agentId), "Session ID should contain agent ID")
        XCTAssertTrue(sessionId.contains("_"), "Session ID should have timestamp separator")
    }

    // MARK: - Cross-RFC: Agent with Model as tool

    func test_agent_model_tool_serialization() async throws {
        let modelPage = try await Model.search(pageSize: 1, context: aix)
        guard let model = modelPage.results.first else {
            throw XCTSkip("No models found")
        }

        let agent = Agent(name: "Test Agent with Tool", instructions: "Use the tool", context: aix)
        agent.tools = [model]

        let payload = try agent.buildSavePayload()
        let toolsList = payload["tools"] as? [[String: Any]]
        XCTAssertNotNil(toolsList)
        XCTAssertEqual(toolsList?.count, 1)
        XCTAssertEqual(toolsList?.first?["type"] as? String, "model")
        XCTAssertEqual(toolsList?.first?["id"] as? String, model.id)
    }
}
