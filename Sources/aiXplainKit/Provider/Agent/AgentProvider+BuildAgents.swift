//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 06/01/25.
//

import Foundation

extension AgentProvider {
    /// Creates a new agent with the specified configuration.
    ///
    /// This method creates an agent on the aiXplain platform with the provided parameters.
    /// The agent will be initialized in a "draft" status and can later be deployed using
    /// the `deploy()` method.
    ///
    /// - Parameters:
    ///   - name: The name of the agent
    ///   - description: A description of the agent's role and capabilities
    ///   - llmId: The aiXplain ID of the large language model to be used. Defaults to GPT-4 mini.
    ///   - tools: Array of tools that the agent can use
    ///   - supplier: The owner/supplier of the agent. Defaults to empty string.
    ///   - version: Version identifier for the agent. Defaults to empty string.
    ///
    /// - Returns: A newly created `Agent` instance
    ///
    /// - Throws:
    ///   - `AgentsError.missingBackendURL` if the backend URL is not configured
    ///   - `AgentsError.invalidURL` if the constructed URL is invalid
    ///   - Networking errors if the request fails
    ///   - Decoding errors if the response cannot be parsed
    ///
    /// # Example
    /// ```swift
    /// let tools = [
    ///     CreateAgentTool(name: "Calculator", description: "Performs calculations"),
    ///     CreateAgentTool(name: "Translator", description: "Translates text")
    /// ]
    ///
    /// do {
    ///     let agent = try await agentProvider.create(
    ///         name: "Math Assistant",
    ///         description: "Helps with mathematical problems",
    ///         tools: tools
    ///     )
    ///     print("Created agent with ID: \(agent.id)")
    /// } catch {
    ///     print("Failed to create agent: \(error)")
    /// }
    /// ```
    public func create(
        name: String,
        description: String,
        llmId: String = "6646261c6eb563165658bbb1",
        tools: [CreateAgentTool],
        supplier: String = "",
        version: String = ""
    ) async throws -> Agent {
        let headers = try networking.buildHeader()
        
        guard let baseURL = APIKeyManager.shared.BACKEND_URL else {
            throw AgentsError.missingBackendURL
        }
        
        let endpoint = Networking.Endpoint.agents(agentIdentifier: "")
        guard let url = URL(string: baseURL.absoluteString + endpoint.path) else {
            throw AgentsError.invalidURL(url: baseURL.absoluteString + endpoint.path)
        }
        
        let agent = Agent(
            id: "",
            name: name,
            status: "draft",
            teamId: 0,
            description: description,
            llmId: llmId,
            createdAt: .now,
            updatedAt: .now
        )
        agent.assets = tools.map { $0.convertToTool() }
        
        let encodedAgent = try JSONEncoder().encode(agent)
        let response = try await networking.post(url: url, headers: headers, body: encodedAgent)
         if let httpUrlResponse = response.1 as? HTTPURLResponse,
           !(200...299).contains(httpUrlResponse.statusCode) {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }
        
        return try JSONDecoder().decode(Agent.self, from: response.0)
    }
}
