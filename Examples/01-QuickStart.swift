/// # Quick Start
///
/// The simplest way to use aiXplainKit v2.
///
/// Set your API key via environment variable:
///   export TEAM_API_KEY="your-api-key"
///
/// Or pass it explicitly to `Aixplain(apiKey:)`.

import aiXplainKit

@main
struct QuickStart {
    static func main() async throws {

        // 1. Initialize the SDK
        let aix = try Aixplain(apiKey: "your-team-api-key")

        // 2. Run a model
        let model = try await Model.get("669a63646eb56306647e1091", context: aix) // GPT-4o Mini
        let result = try await model.run(text: "Say hello in French")
        print("Model output:", result.data ?? "no output")

        // 3. Run an agent
        let agents = try await Agent.search(pageSize: 1, context: aix)
        if let agent = agents.results.first {
            let response = try await agent.run("What can you help me with?")
            print("Agent says:", response.data?.output ?? "no output")
        }
    }
}
