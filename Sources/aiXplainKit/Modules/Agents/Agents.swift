//
//  Agents.swift
//  aiXplainKit
//
//  Created by Joao Maia on 11/11/24.
//

import Foundation
import os

/// A class representing an agent in the aiXplain ecosystem.
///
/// The `Agent` class is designed to manage and execute tasks for an agent, including handling inputs, configuring parameters,
/// and retrieving results. It supports various execution methods and includes utilities for polling and network handling.
public final class Agent: Codable {
    
    // MARK: - Properties
    
    /// The unique identifier of the agent.
    public var id: String
    
    /// The name of the agent.
    public var name: String
    
    /// The current status of the agent.
    public var status: String
    
    /// The identifier of the team associated with the agent.
    public let teamId: Int
    
    /// A description of the agent.
    public var description: String
    
    /// The identifier of the associated large language model (LLM).
    public let llmId: String
    
    /// The timestamp when the agent was created.
    public let createdAt: Date
    
    /// The timestamp when the agent was last updated.
    public let updatedAt: Date
    
    /// The instructions for the agent.
    public var instructions: String
    
    /// A logger instance for recording events and debugging information.
    private let logger: Logger
    
    /// The assets associated with the agent.
    public var assets: [Tool]
    
    /// The networking service responsible for making API calls and handling URL sessions.
    var networking: Networking
    
    
    // MARK: - Initializers
    
    /// Creates an instance of `Agent` from a decoder.
    ///
    /// - Parameter decoder: The decoder to use for decoding the agent data.
    /// - Throws: An error if the decoding process fails.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decode(String.self, forKey: .status)
        teamId = try container.decode(Int.self, forKey: .teamId)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? "No description"
        llmId = try container.decode(String.self, forKey: .llmId)
        assets = try container.decodeIfPresent([Tool].self, forKey: .assets) ?? []
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions) ?? ""
        
        logger = Logger(subsystem: "AiXplain", category: "Agent(\(name))")
        networking = Networking()
    }
    
    /// Creates a new instance of `Agent` with specific properties.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the agent.
    ///   - name: The name of the agent.
    ///   - status: The current status of the agent.
    ///   - teamId: The identifier of the associated team.
    ///   - description: A brief description of the agent.
    ///   - llmId: The identifier of the associated large language model.
    ///   - createdAt: The creation timestamp of the agent.
    ///   - updatedAt: The last update timestamp of the agent.
    ///   - assets: The assets associated with the agent.
    ///   - instructions: The instructions for the agent.
    public init(id: String, name: String, status: String, teamId: Int, description: String, llmId: String, createdAt: Date, updatedAt: Date, assets: [Tool] = [], instructions: String = "") {
        self.id = id
        self.name = name
        self.status = status
        self.teamId = teamId
        self.description = description
        self.llmId = llmId
        self.assets = assets
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.instructions = instructions
        self.logger = Logger(subsystem: "AiXplain", category: "Agent(\(name))")
        self.networking = Networking()
    }
    
    /// Encodes the `Agent` instance into the provided encoder.
    ///
    /// - Parameter encoder: The encoder to use for encoding the agent.
    /// - Throws: An error if the encoding process fails.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(status, forKey: .status)
        try container.encode(teamId, forKey: .teamId)
        try container.encode(description, forKey: .description)
        try container.encode(llmId, forKey: .llmId)
        try container.encode(assets, forKey: .assets)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(instructions, forKey: .instructions)
    }
    
    /// Private keys for encoding and decoding the `Agent` properties.
    private enum CodingKeys: String, CodingKey {
        case id, name, status, teamId, description, llmId, createdAt, updatedAt, assets, instructions
    }
}


// MARK: - Agent Execution

extension Agent {
    
    /// Executes the agent with specified input and parameters.
    ///
    /// This method sends the given input to the agent, configured with the provided parameters,
    /// and returns the result of the execution.
    ///
    /// - Parameters:
    ///   - agentInput: The input conforming to `AgentInputable` used for the agent execution.
    ///   - sessionID: An optional session identifier, useful for tracking execution context.
    ///   - parameters: Parameters to configure the agent execution, including polling and timeout settings.
    /// - Returns: The `AgentOutput` containing the result of the agent execution.
    /// - Throws: Errors related to networking, invalid input, or execution failure.
    ///
    /// # Example
    /// ```swift
    /// let agentInput:String = "Hello World"
    /// let parameters = AgentRunParameters()
    /// do {
    ///     let output = try await agent.run(agentInput, sessionID: "12345", parameters: parameters)
    ///     print("Execution result: \(output)")
    /// } catch {
    ///     print("Failed to execute agent: \(error)")
    /// }
    /// ```
    public func run(_ agentInput: any AgentInputable, sessionID: String? = nil, parameters: AgentRunParameters = .defaultParameters) async throws -> AgentOutput {
        let headers = try self.networking.buildHeader()
        let payload = try await agentInput.generateInputPayloadForAgent(using: parameters, withID: sessionID)
        
        guard let backendURL = APIKeyManager.shared.BACKEND_URL else {
            throw AgentsError.missingBackendURL
        }
        
        guard let url = URL(string: backendURL.absoluteString + Networking.Endpoint.agentRun(agentIdentifier: self.id).path ) else {
            throw AgentsError.invalidURL(url: backendURL.absoluteString)
        }
        
        logger.debug("Creating an execution with the following payload \(String(data: payload, encoding: .utf8) ?? "-")")
        networking.parameters = parameters
        let response = try await networking.post(url: url, headers: headers, body: payload)
        
        if let httpResponse = response.1 as? HTTPURLResponse,
           httpResponse.statusCode != 201 {
            throw NetworkingError.invalidStatusCode(statusCode: httpResponse.statusCode)
        }
        
        let decodedResponse = try JSONDecoder().decode(AgentExecuteResponse.self, from: response.0)
        
        guard let pollingURL = decodedResponse.maybeUrl else {
            throw ModelError.failToDecodeRunResponse
        }
        
        logger.info("Successfully created an execution")
        return try await polling(from: pollingURL,
                                 maxRetry: parameters.maxPollingRetries,
                                 waitTime: parameters.pollingWaitTimeInSeconds)
    }
    
    /// Executes the agent with a query and optional content inputs.
    ///
    /// This method allows the agent to process a query and dynamically replace placeholders in the query
    /// with provided content. The content can include URLs, text, or other input types.
    ///
    /// - Parameters:
    ///   - query: A query string for the agent to process. Placeholders in the format `{{key}}` can be replaced by `content` values.
    ///   - content: A dictionary of additional inputs (e.g., files, URLs, text) to be included in the query.
    ///   - sessionID: An optional session identifier, useful for tracking execution context.
    ///   - parameters: Parameters to configure the agent execution, including polling and timeout settings.
    /// - Returns: The `AgentOutput` containing the result of the agent execution.
    /// - Throws: Errors related to networking, invalid input, or execution failure.
    ///
    /// # Example
    /// ```swift
    /// let query = "What is the history of the text in the figure {{poem}}? Please be descriptive."
    /// let content: [String: AgentInputable] = [
    ///     "poem": URL(string: "file:/Users/joao/Downloads/RumiPoemImage.jpeg")!
    /// ]
    /// let parameters = AgentRunParameters()
    /// do {
    ///     let output = try await agent.run(query: query, content: content, sessionID: "12345", parameters: parameters)
    ///     print("Execution result: \(output)")
    /// } catch {
    ///     print("Failed to execute agent: \(error)")
    /// }
    /// ```
    public func run(query: String, content: [String: AgentInputable] = [:], sessionID: String? = nil, parameters: AgentRunParameters = .defaultParameters) async throws -> AgentOutput {
        if content.count > 3{
            throw AgentsError.invalidInput(error: "Only up to 3 content items are supported")
        }
        if query.isEmpty {
            throw AgentsError.invalidInput(error: "Query cannot be empty")
        }
        
        var modifiedQuery = query
        
        for (key, value) in content {
            let formattedValue: String
            switch value {
            case let url as URL:
                formattedValue = try await url.uploadToS3IfNeedIt().absoluteString
            case let string as String:
                formattedValue = string
            default:
                formattedValue = "\(value)"
            }
            
            if modifiedQuery.contains("{{\(key)}}") {
                modifiedQuery = modifiedQuery.replacingOccurrences(of: "{{\(key)}}", with: " \(formattedValue) ")
            } else {
                modifiedQuery.append(" \(formattedValue) ")
            }
        }
        
        return try await run(modifiedQuery.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), sessionID: sessionID, parameters: parameters)
    }
    
    /// Polls a given URL to monitor the agent's execution and retrieve results.
    ///
    /// This method continuously polls the provided URL at specified intervals until the execution
    /// is complete or the maximum number of retries is reached.
    ///
    /// - Parameters:
    ///   - url: The URL to poll for results.
    ///   - maxRetry: The maximum number of retries allowed during polling (default is `300` retries).
    ///   - waitTime: The time interval (in seconds) between polling attempts (default is `0.5` seconds).
    /// - Returns: The `AgentOutput` containing the result of the agent execution.
    /// - Throws: Errors related to timeouts, network failures, or invalid responses.
    ///
    /// # Example
    /// ```swift
    /// let pollingURL = URL(string: "https://api.example.com/agents/results/12345")!
    /// do {
    ///     let output = try await agent.polling(from: pollingURL, maxRetry: 100, waitTime: 1.0)
    ///     print("Polling result: \(output)")
    /// } catch {
    ///     print("Polling failed: \(error)")
    /// }
    /// ```
    private func polling(from url: URL, maxRetry: Int = 300, waitTime: Double = 0.5) async throws -> AgentOutput {
        let headers = try self.networking.buildHeader()
        var attempts = 0
        
        logger.info("Starting polling job")
        repeat {
            let response = try await networking.get(url: url, headers: headers)
            logger.debug("(\(attempts)/\(maxRetry)) Polling...")
            
            if let json = try? JSONSerialization.jsonObject(with: response.0, options: []) as? [String: Any],
               let completed = json["completed"] as? Bool {
                if let _ = json["error"] as? String, let supplierError = json["supplierError"] as? String {
                    throw AgentsError.supplierError(error: supplierError)
                }
                
                if completed {
                    do {
                        let decodedResponse = try JSONDecoder().decode(AgentOutput.self, from: response.0)
                        logger.info("Polling job finished.")
                        return decodedResponse
                    } catch {
                        throw AgentsError.failToDecodeModelOutputDuringPollingPhase(error: String(describing: error))
                    }
                }
            }
            
            try await Task.sleep(nanoseconds: UInt64(max(0.2, waitTime) * 1_000_000_000))
            attempts += 1
        } while attempts < maxRetry
        
        throw ModelError.pollingTimeoutOnModelResponse(pollingURL: url)
    }
}
