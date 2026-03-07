/// # Working with Agents
///
/// Search, fetch, run agents, manage sessions, and use tools with agents.

import aiXplainKit

@main
struct AgentsExample {
    static func main() async throws {
        let aix = try Aixplain()

        // --- Search agents ---
        let page = try await Agent.search(pageSize: 5, context: aix)
        print("Found \(page.total) agents")

        // --- Get a specific agent ---
        guard let agentId = page.results.first?.id else {
            print("No agents found")
            return
        }
        let agent = try await Agent.get(agentId, context: aix)
        print("Agent: \(agent.name ?? "?")")
        print("  Status: \(agent.status)")
        print("  LLM: \(agent.llmId)")
        print("  Instructions: \(agent.instructions ?? "(none)")")

        // --- Run the agent ---
        let result = try await agent.run("What is the capital of France?")
        print("\nAgent response: \(result.data?.output ?? "no output")")
        print("  Session: \(result.sessionId ?? "none")")
        print("  Credits: \(result.usedCredits)")

        // --- Multi-turn conversation ---
        let sessionId = try await agent.generateSessionId()
        print("\nSession ID: \(sessionId)")

        let turn1 = try await agent.run("My name is Alice", sessionId: sessionId)
        print("Turn 1: \(turn1.data?.output ?? "")")

        let turn2 = try await agent.run("What is my name?", sessionId: sessionId)
        print("Turn 2: \(turn2.data?.output ?? "")")

        // --- Create a new agent with a model as a tool ---
        let model = try await Model.get("669a63646eb56306647e1091", context: aix)
        let newAgent = Agent(
            name: "My Assistant",
            instructions: "You are a helpful assistant. Use the provided tools when needed.",
            tools: [model],
            context: aix
        )
        // newAgent.save() would persist it to the platform
        print("\nNew agent payload preview:")
        let payload = try newAgent.buildSavePayload()
        print("  Name: \(payload["name"] ?? "?")")
        print("  Tools: \((payload["tools"] as? [[String: Any]])?.count ?? 0) tool(s)")
    }
}
