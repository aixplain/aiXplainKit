import aiXplainKit

AiXplainKit.shared.keyManager.TEAM_API_KEY = "123"

do {
    let model = try await ModelProvider().get("640b517694bf816d35a59125")
} catch {
    //  Error
}
