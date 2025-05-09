/*
 AiXplainKit Library.
 ---
 
 aiXplain SDK enables Swift programmers to add AI functions
 to their software.
 
 Copyright 2024 The aiXplain SDK authors
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 AUTHOR: João Pedro Maia
 */

import Foundation
import OSLog

/// A class responsible for fetching agent information from the backend.
///
/// The `AgentProvider` class is used to interact with the backend services, allowing you to fetch agent details
/// using the agent's unique identifier. It uses the `Networking` class to handle API requests and responses.
public final class AgentProvider {

    // MARK: - Properties

    /// A logger instance for recording events and debugging information.
    private let logger = Logger(subsystem: "AiXplainKit", category: "AgentProvider")

    /// The networking service used to make API calls.
    var networking = Networking()

    // MARK: - Initializers

    /// Initializes a new instance of `AgentProvider`.
    public init() {
        self.networking = Networking()
    }

    /// Internal initializer for testing or dependency injection purposes.
    ///
    /// - Parameter networking: A pre-configured `Networking` instance.
    internal init(networking: Networking) {
        self.networking = networking
    }

    // MARK: - Methods

    /// Fetches the details of an agent with the provided ID from the backend.
    ///
    /// This method sends a request to the backend to retrieve the details of an agent identified by its unique ID.
    /// It decodes the response into an `Agent` object and logs relevant events during the process.
    ///
    /// - Parameter agentID: The unique identifier of the agent to fetch.
    /// - Returns: An `Agent` object containing the details of the requested agent.
    /// - Throws:
    ///   - `AgentsError.missingBackendURL` if the backend URL is not available.
    ///   - `AgentsError.invalidURL` if the constructed URL is invalid.
    ///   - `NetworkingError.invalidStatusCode` if the response status code is not 200.
    ///   - `DecodingError` if the response cannot be decoded into an `Agent` object.
    ///
    /// # Example
    /// ```swift
    /// do {
    ///     let agentProvider = AgentProvider()
    ///     let agent = try await agentProvider.get("agent-12345")
    ///     print("Fetched agent: \(agent.name)")
    /// } catch {
    ///     print("Failed to fetch agent: \(error)")
    /// }
    /// ```
    public func get(_ agentID: String) async throws -> Agent {
        let headers: [String: String] = try networking.buildHeader()

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw AgentsError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.agents(agentIdentifier: agentID)
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw AgentsError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        let response = try await networking.get(url: url, headers: headers)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 200 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        do {
            logger.debug("\(String(data: response.0, encoding: .utf8)!)")
            let fetchedAgent = try JSONDecoder().decode(Agent.self, from: response.0)
            if fetchedAgent.id.count <= 1 {
                fetchedAgent.id = agentID
            }

            logger.info("\(fetchedAgent.name) fetched")
            return fetchedAgent
        } catch {
            logger.error("\(String(describing: error))")
            throw error
        }
    }
    
    
    /// Retrieves a list of all available agents.
    ///
    /// This method fetches all agents accessible to the authenticated user from the aiXplain platform.
    ///
    /// - Returns: An array of `Agent` objects representing the available agents.
    ///
    /// - Throws:
    ///   - `AgentsError.missingBackendURL` if the backend URL is not available.
    ///   - `AgentsError.invalidURL` if the constructed URL is invalid.
    ///   - `NetworkingError.invalidStatusCode` if the response status code is not 200.
    ///   - `DecodingError` if the response cannot be decoded into an array of `Agent` objects.
    ///
    /// # Example
    /// ```swift
    /// do {
    ///     let agentProvider = AgentProvider()
    ///     let agents = try await agentProvider.list()
    ///     print("Found \(agents.count) agents")
    /// } catch {
    ///     print("Failed to fetch agents: \(error)")
    /// }
    /// ```
    public func list() async throws -> [Agent] {
        let headers: [String: String] = try networking.buildHeader()
        
        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw AgentsError.missingBackendURL
        }
        
        let endpoint = Networking.Endpoint.paginateAgents
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw AgentsError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        let response = try await networking.get(url: url, headers: headers)
        
        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 200 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        do {
            struct agentID:Codable{
                var id:String
            }

            logger.debug("\(String(data: response.0, encoding: .utf8)!)")
            let fetchedAgentID:[agentID] = try JSONDecoder().decode([agentID].self, from: response.0)
            var fetchedAgents:[Agent] = []
            
            for agentID in fetchedAgentID{
                if let agent = try? await get(agentID.id){
                    fetchedAgents.append(agent)
                }
            }

            logger.info("\(fetchedAgents.count) fetched")
            return fetchedAgents
        } catch {
            logger.error("\(String(describing: error))")
            throw error
        }
    }
    
    
    public func list(_ query: ModelQuery) async throws -> [Agent] {
        let headers: [String: String] = try networking.buildHeader()

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.paginateAgents
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw ModelError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        let body = try query.buildQuery()
        let response = try await networking.post(url: url, headers: headers, body: body)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 201 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

//        if let stringedResponse = String(data: response.0, encoding: .utf8) {
//            return parseModelQueryResponse(stringedResponse) ?? []
//        }
        return []
    }
}
