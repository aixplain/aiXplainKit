/// # Team Agents (Multi-Agent Systems)
///
/// In v2, team agents are just agents with subagents. No separate class.

import aiXplainKit

@main
struct TeamAgentsExample {
    static func main() async throws {
        let aix = try Aixplain()

        // --- A TeamAgent is just an Agent with subagents ---
        // The typealias exists for discoverability:
        //   public typealias TeamAgent = Agent

        // --- Check if an agent is a team agent ---
        let agent = Agent(name: "Solo Agent", context: aix)
        print("Is team agent: \(agent.isTeamAgent)") // false

        // --- Create a team agent from existing agents ---
        let agents = try await Agent.search(pageSize: 3, context: aix)
        guard agents.results.count >= 2 else {
            print("Need at least 2 agents to form a team")
            return
        }

        let subAgent1 = agents.results[0]
        let subAgent2 = agents.results[1]

        let team = Agent(
            name: "Research Team",
            instructions: "Coordinate the sub-agents to answer research questions",
            context: aix
        )
        team.subagents = [subAgent1, subAgent2]

        print("Team agent: \(team.name ?? "?")")
        print("  Is team: \(team.isTeamAgent)") // true
        print("  Subagents: \(team.subagents.count)")
        for sub in team.subagents {
            print("    - \(sub.name ?? "?") [\(sub.id ?? "")]")
        }

        // --- The save payload includes agent references ---
        let payload = try team.buildSavePayload()
        let agentRefs = payload["agents"] as? [[String: Any]] ?? []
        print("\nSave payload agent refs: \(agentRefs.count)")
    }
}
