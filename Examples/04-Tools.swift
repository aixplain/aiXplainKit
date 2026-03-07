/// # Working with Tools
///
/// Search tools, use them with agents, and work with integrations.

import aiXplainKit

@main
struct ToolsExample {
    static func main() async throws {
        let aix = try Aixplain()

        // --- Search tools ---
        let page = try await Tool.searchTools(pageSize: 5, context: aix)
        print("Found \(page.total) tools")
        for tool in page.results {
            print("  - \(tool.name ?? "?") [\(tool.id ?? "")]")
            print("    Actions available: \(tool.actionsAvailable ?? false)")
            print("    Allowed actions: \(tool.allowedActions)")
        }

        // --- Get a specific tool ---
        if let toolId = page.results.first?.id {
            let tool = try await Tool.getTool(toolId, context: aix)
            print("\nTool details: \(tool.name ?? "?")")

            // Convert to agent tool format
            let agentTool = tool.asAgentTool()
            print("  As agent tool type: \(agentTool.type)")
            if let actions = agentTool.actions {
                print("  Actions: \(actions)")
            }

            // List actions (if available)
            if tool.actionsAvailable == true {
                let actions = try await tool.listActions()
                print("  Available actions:")
                for action in actions {
                    print("    - \(action.name ?? action.slug ?? "?")")
                }
            }
        }

        // --- Use multiple tools with an agent ---
        let model = try await Model.get("669a63646eb56306647e1091", context: aix)
        let tools: [any AgentToolConvertible] = [model]
        if let firstTool = page.results.first {
            let allTools: [any AgentToolConvertible] = [model, firstTool]
            let agent = Agent(
                name: "Multi-tool Agent",
                instructions: "Use available tools to answer questions",
                tools: allTools,
                context: aix
            )
            let payload = try agent.buildSavePayload()
            let toolsList = payload["tools"] as? [[String: Any]] ?? []
            print("\nAgent with \(toolsList.count) tools:")
            for t in toolsList {
                print("  - \(t["name"] ?? "?") (type: \(t["type"] ?? "?"))")
            }
        }
    }
}
