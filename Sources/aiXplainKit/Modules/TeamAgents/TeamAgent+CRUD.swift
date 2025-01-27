//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 27/01/25.
//

import Foundation

/// Extension providing CRUD (Create, Read, Update, Delete) operations for TeamAgent
extension TeamAgent {
    
    
    /// Updates the team agent's information on the server.
    /// - Throws: Various errors that might occur during the update process:
    ///   - `ModelError.missingBackendURL`: If the backend URL is not configured
    ///   - `ModelError.invalidURL`: If the constructed URL is invalid
    ///   - `NetworkingError.invalidStatusCode`: If the server responds with a non-2xx status code
    ///   - `AgentsError.errorOnUpdate`: If there's an error decoding the server response
    public func update() async throws {
        let headers = try networking.buildHeader()
        
        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.agentCommunities(agentIdentifier: self.id).path
        guard let url = URL(string: url.absoluteString + endpoint) else {
            throw ModelError.invalidURL(url: url.absoluteString)
        }
        
        let payload = try self.encode()

        let response = try await networking.put(url: url, body: payload, headers: headers)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           !(200...299).contains(httpUrlResponse.statusCode) {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(TeamAgent.self, from: response.0)
            self.update(id: decodedResponse.id)
            self.update(agents: decodedResponse.agents)
            self.status = decodedResponse.status
        } catch {
            throw AgentsError.errorOnUpdate(error: "")
        }
    }
    
    /// Deploys the team agent by changing its status to "onboarded" and updating it on the server.
    /// - Throws: Any error that might occur during the update process.
    /// See ``update()`` for possible errors.
    public func deploy() async throws {
        self.status = "onboarded"
        try await self.update()
    }
    
    /// Deletes the team agent from the server.
    /// - Throws: Various errors that might occur during the deletion process:
    ///   - `ModelError.missingBackendURL`: If the backend URL is not configured
    ///   - `ModelError.invalidURL`: If the constructed URL is invalid
    ///   - `AgentsError.errorOnDelete`: If the server responds with a non-2xx status code
    public func delete() async throws {
        let networking = networking ?? Networking()
        let headers = try networking.buildHeader()
        
        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.agentCommunities(agentIdentifier: self.id).path
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
