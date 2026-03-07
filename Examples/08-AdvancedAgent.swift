/// # Advanced Agent Features
///
/// Tasks, conversation history, output formats, and cloning.

import aiXplainKit

@main
struct AdvancedAgentExample {
    static func main() async throws {
        let aix = try Aixplain()

        // --- Agent with tasks ---
        let researchTask = AgentTask(
            name: "research",
            instructions: "Find relevant information about the topic",
            expectedOutput: "A list of key facts",
            dependencies: []
        )
        let summarizeTask = AgentTask(
            name: "summarize",
            instructions: "Summarize the research findings",
            expectedOutput: "A concise summary paragraph",
            dependencies: ["research"]  // depends on research completing first
        )

        let agent = Agent(name: "Research Agent", instructions: "Complete tasks in order", context: aix)
        agent.tasks = [researchTask, summarizeTask]
        agent.outputFormat = .markdown

        print("Agent with \(agent.tasks.count) tasks:")
        for task in agent.tasks {
            print("  - \(task.name) (deps: \(task.dependencies))")
        }

        // --- Output formats ---
        print("\nOutput formats:")
        print("  .text -> '\(OutputFormat.text.rawValue)'")
        print("  .json -> '\(OutputFormat.json.rawValue)'")
        print("  .markdown -> '\(OutputFormat.markdown.rawValue)'")

        // --- Conversation history validation ---
        let validHistory = [
            ConversationMessage(role: .user, content: "Hello"),
            ConversationMessage(role: .assistant, content: "Hi! How can I help?"),
            ConversationMessage(role: .user, content: "Tell me a joke"),
        ]

        do {
            try ConversationMessage.validateHistory(validHistory)
            print("\nHistory is valid (\(validHistory.count) messages)")
        } catch {
            print("Invalid history: \(error)")
        }

        // --- Clone an agent ---
        let agents = try await Agent.search(pageSize: 1, context: aix)
        if let original = agents.results.first {
            let fetched = try await Agent.get(original.id!, context: aix)
            let cloned = fetched.clone(name: "Copy of \(fetched.name ?? "Agent")")
            print("\nCloned agent:")
            print("  Original: \(fetched.name ?? "?") [id: \(fetched.id ?? "")]")
            print("  Clone: \(cloned.name ?? "?") [id: \(cloned.id ?? "nil")]")
            print("  Clone status: \(cloned.status)") // always .draft
        }

        // --- Run with variables ---
        // agent.run(query: "Analyze this topic",
        //           variables: ["topic": "climate change", "depth": "detailed"])

        // --- Run with conversation history ---
        // agent.run(query: "Continue the analysis",
        //           sessionId: sessionId,
        //           history: validHistory)
    }
}
