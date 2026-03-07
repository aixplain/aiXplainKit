/// # Working with Models
///
/// Search, fetch, run, and stream AI models.

import aiXplainKit

@main
struct ModelsExample {
    static func main() async throws {
        let aix = try Aixplain()

        // --- Search models ---
        let page = try await Model.search(query: "gpt", pageSize: 5, context: aix)
        print("Found \(page.total) models matching 'gpt'")
        for model in page.results {
            print("  - \(model.name ?? "?") [\(model.id ?? "")]")
        }

        // --- Get a specific model ---
        let gpt4oMini = try await Model.get("669a63646eb56306647e1091", context: aix)
        print("\nModel: \(gpt4oMini.name ?? "?")")
        print("  Host: \(gpt4oMini.host ?? "?")")
        print("  Streaming: \(gpt4oMini.supportsStreaming ?? false)")
        print("  Connection: \(gpt4oMini.connectionType ?? [])")

        // --- Run a model ---
        let result = try await gpt4oMini.run(text: "Explain quantum computing in one sentence")
        print("\nResult: \(result.data?.description ?? "no data")")
        print("  Credits used: \(result.usedCredits ?? 0)")
        print("  Run time: \(result.runTime ?? 0)s")

        // --- Use a model as an agent tool ---
        let toolDict = gpt4oMini.asAgentTool()
        print("\nAs agent tool:")
        print("  ID: \(toolDict.id)")
        print("  Type: \(toolDict.type)")
        print("  Supplier: \(toolDict.supplier)")
    }
}
