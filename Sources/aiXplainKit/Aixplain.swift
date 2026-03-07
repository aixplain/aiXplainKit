import Foundation

/// Main entry point for the aiXplain Swift SDK v2.
///
/// Mirrors Python v2 `Aixplain` class in `core.py`.
///
/// ```swift
/// let aix = try Aixplain(apiKey: "your-team-key")
/// let agent = try await aix.Agent.get("agent-id")
/// let result = try await agent.run("Hello!")
/// ```
public final class Aixplain: @unchecked Sendable {
    public let client: AixplainClient
    public let apiKey: String
    public let backendURL: URL
    public let modelURL: URL

    /// Initialize with explicit API key or environment fallback.
    ///
    /// - Parameters:
    ///   - apiKey: Team API key. If nil, resolved from `TEAM_API_KEY` env var.
    ///   - backendURL: Override the default backend URL.
    ///   - modelURL: Override the default model execution URL.
    public init(
        apiKey: String? = nil,
        backendURL: URL? = nil,
        modelURL: URL? = nil
    ) throws {
        let credential = try Credential.resolve(apiKey: apiKey)
        var config = ClientConfiguration.default
        if let url = backendURL { config.backendURL = url }
        if let url = modelURL { config.modelsRunURL = url }

        self.apiKey = credential.scheme.key
        self.backendURL = config.backendURL.absoluteString
            .hasSuffix("/") ? config.backendURL : URL(string: config.backendURL.absoluteString + "/")!
        self.modelURL = config.modelsRunURL
        self.client = AixplainClient(credential: credential, configuration: config)
    }

    // Resource accessors will be added in subsequent phases.
    // Phase 4 (RFC-0007): public lazy var Model = ...
    // Phase 5 (RFC-0008): public lazy var Tool = ...
    // Phase 6 (RFC-0003): public lazy var Agent = ...
    // Phase 7 (RFC-0009): public lazy var Index = ...
}
