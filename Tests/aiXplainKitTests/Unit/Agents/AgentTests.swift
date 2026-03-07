import XCTest
@testable import aiXplainKit

final class AgentTests: XCTestCase {

    func test_agent_resourcePath() {
        XCTAssertEqual(Agent.resourcePath, "v2/agents")
    }

    func test_agent_from_dict() throws {
        let aix = try Aixplain(apiKey: "test-key")
        let dict: [String: Any] = [
            "id": "agent-123",
            "name": "My Agent",
            "description": "A helpful agent",
            "status": "onboarded",
            "instructions": "You are a helpful assistant",
            "teamId": 42,
            "model": ["id": "llm-abc"],
            "outputFormat": "text",
            "maxIterations": 10,
            "maxTokens": 4096
        ]

        let agent = try Agent.from(dict: dict, context: aix)
        XCTAssertEqual(agent.id, "agent-123")
        XCTAssertEqual(agent.name, "My Agent")
        XCTAssertEqual(agent.status, .onboarded)
        XCTAssertEqual(agent.instructions, "You are a helpful assistant")
        XCTAssertEqual(agent.llmId, "llm-abc")
        XCTAssertEqual(agent.outputFormat, .text)
        XCTAssertEqual(agent.maxIterations, 10)
        XCTAssertEqual(agent.maxTokens, 4096)
        XCTAssertEqual(agent.teamId, 42)
    }

    func test_agent_isTeamAgent() {
        let agent = Agent(name: "Solo")
        XCTAssertFalse(agent.isTeamAgent)

        let subAgent = Agent(id: "sub1", name: "Sub")
        let teamAgent = Agent(name: "Team")
        teamAgent.subagents = [subAgent]
        XCTAssertTrue(teamAgent.isTeamAgent)
    }

    func test_teamAgent_typealias() {
        let agent: TeamAgent = Agent(name: "Team via alias")
        XCTAssertTrue(agent is Agent)
    }

    func test_agent_buildSavePayload() throws {
        let agent = Agent(name: "Test", instructions: "Be helpful", llmId: "llm-1")
        let payload = try agent.buildSavePayload()

        XCTAssertEqual(payload["name"] as? String, "Test")
        XCTAssertEqual(payload["instructions"] as? String, "Be helpful")
        XCTAssertEqual((payload["model"] as? [String: Any])?["id"] as? String, "llm-1")
        XCTAssertEqual(payload["status"] as? String, "draft")
        XCTAssertNotNil(payload["tools"])
    }

    func test_agent_buildRunPayload() throws {
        let agent = Agent(id: "agent-1", name: "Test")
        agent.outputFormat = .json

        let payload = try agent.buildRunPayload(query: "Hello", sessionId: "sess-1")
        XCTAssertEqual(payload["id"] as? String, "agent-1")
        XCTAssertEqual(payload["sessionId"] as? String, "sess-1")
        XCTAssertTrue(payload["runResponseGeneration"] as? Bool ?? false)

        let execParams = payload["executionParams"] as? [String: Any]
        XCTAssertEqual(execParams?["outputFormat"] as? String, "json")
    }

    func test_agent_clone() throws {
        let aix = try Aixplain(apiKey: "test-key")
        let agent = Agent(id: "original", name: "Original", context: aix)
        agent.instructions = "Original instructions"
        agent.llmId = "llm-custom"

        let cloned = agent.clone(name: "Cloned")
        XCTAssertNil(cloned.id)
        XCTAssertEqual(cloned.name, "Cloned")
        XCTAssertEqual(cloned.instructions, "Original instructions")
        XCTAssertEqual(cloned.llmId, "llm-custom")
        XCTAssertEqual(cloned.status, .draft)
        XCTAssertNotNil(cloned.context)
    }
}

final class ConversationMessageTests: XCTestCase {

    func test_validateHistory_valid() throws {
        let history = [
            ConversationMessage(role: .user, content: "Hello"),
            ConversationMessage(role: .assistant, content: "Hi there!")
        ]
        XCTAssertNoThrow(try ConversationMessage.validateHistory(history))
    }

    func test_validateHistory_emptyContent_throws() {
        let history = [
            ConversationMessage(role: .user, content: "")
        ]
        XCTAssertThrowsError(try ConversationMessage.validateHistory(history))
    }

    func test_validateHistory_emptyList_passes() throws {
        XCTAssertNoThrow(try ConversationMessage.validateHistory([]))
    }

    func test_message_codable() throws {
        let msg = ConversationMessage(role: .user, content: "test")
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(ConversationMessage.self, from: data)
        XCTAssertEqual(decoded.role, .user)
        XCTAssertEqual(decoded.content, "test")
    }
}

final class AgentRunResultTests: XCTestCase {

    func test_from_completed() {
        let dict: [String: Any] = [
            "status": "SUCCESS",
            "completed": true,
            "data": [
                "input": "Hello",
                "output": "Hi there!",
                "steps": [] as [Any],
                "sessionId": "sess-abc"
            ] as [String: Any],
            "sessionId": "sess-abc",
            "usedCredits": 0.002,
            "runTime": 2.5,
            "requestId": "req-xyz"
        ]
        let result = AgentRunResult.from(dict)
        XCTAssertEqual(result.status, "SUCCESS")
        XCTAssertTrue(result.completed)
        XCTAssertEqual(result.data?.output, "Hi there!")
        XCTAssertEqual(result.data?.sessionId, "sess-abc")
        XCTAssertEqual(result.sessionId, "sess-abc")
        XCTAssertEqual(result.usedCredits, 0.002)
        XCTAssertEqual(result.runTime, 2.5)
        XCTAssertEqual(result.requestId, "req-xyz")
    }

    func test_from_inProgress() {
        let dict: [String: Any] = [
            "status": "IN_PROGRESS",
            "completed": false,
            "data": "https://polling-url.com/123"
        ]
        let result = AgentRunResult.from(dict)
        XCTAssertFalse(result.completed)
        XCTAssertEqual(result.url, "https://polling-url.com/123")
    }
}

final class AgentTaskTests: XCTestCase {

    func test_task_codable() throws {
        let task = AgentTask(
            name: "research",
            instructions: "Find information",
            expectedOutput: "A summary",
            dependencies: ["planning"]
        )
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(AgentTask.self, from: data)
        XCTAssertEqual(decoded.name, "research")
        XCTAssertEqual(decoded.instructions, "Find information")
        XCTAssertEqual(decoded.dependencies, ["planning"])
    }

    func test_task_codingKeys_maps_description() throws {
        let json = #"{"name": "task1", "description": "Do something", "expectedOutput": "result", "dependencies": []}"#
        let data = json.data(using: .utf8)!
        let task = try JSONDecoder().decode(AgentTask.self, from: data)
        XCTAssertEqual(task.instructions, "Do something")
    }
}

final class OutputFormatTests: XCTestCase {

    func test_allFormats() {
        XCTAssertEqual(OutputFormat.markdown.rawValue, "markdown")
        XCTAssertEqual(OutputFormat.text.rawValue, "text")
        XCTAssertEqual(OutputFormat.json.rawValue, "json")
    }
}
