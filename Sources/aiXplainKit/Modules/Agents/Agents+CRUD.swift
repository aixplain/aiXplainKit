//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 07/01/25.
//

import Foundation
//MARK: - Deploy, update, delete
extension Agent {
    /// Deploys the agent by changing its status to "onboarded" and updating it on the server.
    ///
    /// This method transitions the agent from its current state to an "onboarded" status,
    /// making it ready for use. The change is synchronized with the server.
    ///
    /// - Throws: Any error that occurs during the update process, including networking errors.
    ///
    /// # Example
    /// ```swift
    /// let agent = // ... existing agent
    /// do {
    ///     try await agent.deploy()
    ///     print("Agent deployed successfully")
    /// } catch {
    ///     print("Failed to deploy agent: \(error)")
    /// }
    /// ```
    public func deploy() async throws {
        self.status = "onboarded"
        try await self.update()
    }
    
    /// Adds new tools to the agent and updates it on the server.
    ///
    /// This method allows you to add additional tools to an existing agent. The tools are appended
    /// to the agent's current set of tools and the changes are synchronized with the server.
    ///
    /// - Parameter tools: An array of `CreateAgentTool` objects representing the new tools to add.
    ///
    /// - Throws: Any error that occurs during the update process, including networking errors.
    ///
    /// # Example
    /// ```swift
    /// let agent = // ... existing agent
    /// let newTools = [
    ///     CreateAgentTool(name: "Calculator", description: "Performs basic math"),
    ///     CreateAgentTool(name: "Weather", description: "Gets weather info")
    /// ]
    ///
    /// do {
    ///     try await agent.appendTools(newTools)
    ///     print("Tools added successfully")
    /// } catch {
    ///     print("Failed to add tools: \(error)")
    /// }
    /// ```
    public func appendTools(_ tools: [CreateAgentTool]) async throws {
        tools.forEach { tool in
            let convertedTool = tool.convertToTool()
            self.assets.append(convertedTool)
        }
        
        try await update()
    }

    /// Updates the agent on the server with the current state of the agent object.
    ///
    /// This method synchronizes the agent's current state with the server. It encodes the agent
    /// object into JSON format and sends it to the server for updating. The response is then decoded
    /// into an `Agent` object and assigned to the current instance.
    ///
    /// - Throws: Any error that occurs during the update process, including networking errors.
    ///
    /// # Example
    /// ```swift
    public func update()async throws {
        let headers = try networking.buildHeader()
        
        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.agents(agentIdentifier: self.id).path
        guard let url = URL(string: url.absoluteString + endpoint) else {
            throw ModelError.invalidURL(url: url.absoluteString)
        }
        
        let payload = try JSONEncoder().encode(self)

        let response = try await networking.put(url: url, body: payload, headers: headers)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           !(200...299).contains(httpUrlResponse.statusCode) {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(Agent.self, from: response.0)
            self.id = decodedResponse.id
            self.status = decodedResponse.status
            self.assets = decodedResponse.assets
        } catch {
            throw AgentsError.errorOnUpdate(error: "")
        }
    }
    
    
    /// Deletes the agent from the server.
    ///
    /// This method sends a DELETE request to remove the agent from the aiXplain platform.
    /// Once deleted, the agent cannot be recovered.
    ///
    /// - Throws:
    ///   - `ModelError.missingBackendURL` if the backend URL is not configured
    ///   - `ModelError.invalidURL` if the constructed URL is invalid
    ///   - `AgentsError.errorOnDelete` if the deletion request fails
    ///   - Any networking errors that occur during the request
    ///
    /// # Example
    /// ```swift
    /// do {
    ///     try await agent.delete()
    ///     print("Agent successfully deleted")
    /// } catch {
    ///     print("Failed to delete agent: \(error)")
    /// }
    /// ```
    public func delete() async throws {
        let networking = networking ?? Networking()
        let headers = try networking.buildHeader()
        
        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.agents(agentIdentifier: self.id).path
        guard let url = URL(string: url.absoluteString + endpoint) else {
            throw ModelError.invalidURL(url: url.absoluteString)
        }
        
        let response = try await networking.delete(url: url, headers: headers)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           !(200...299).contains(httpUrlResponse.statusCode) {
            throw AgentsError.errorOnDelete(error: "")
        }
    }
    
}
