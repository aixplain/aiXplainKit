//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 24/01/25.
//

import Foundation
import OSLog

/// Team Agents are a sophisticated type of agent on the aiXplain platform, designed for handling complex,
/// multi-step tasks that require coordination between multiple components. By leveraging a system of
/// specialized agents, tools, and workflows, Team Agents excel in scenarios that demand advanced task
/// planning, quality control, and adaptability.
public class TeamAgent: Codable {
    /// Unique identifier for the team agent
    private(set) public var id: String
    
    /// Name of the team agent
    public let name: String
    
    /// Array of agent identifiers that are part of this team
    private(set) public var agents: [String]
    
    /// Description of the team agent's purpose and capabilities
    public let description: String?
    
    /// Identifier for the language model associated with this team agent
    public let llmID: String?
    
    /// Information about the supplier of this team agent
    public let supplier: Supplier?
    
    /// Version information for this team agent
    public let version: Version?
    
    /// Identifier for the supervisor agent that oversees the team's operations
    public let supervisorId: String?
    
    /// Identifier for the planner agent that coordinates task execution
    public let plannerId: String?
        
    
    /// A logger instance for recording events and debugging information.
    private let logger: Logger
    
    /// The networking service responsible for making API calls and handling URL sessions.
    var networking: Networking
    
    public var status:String = "draft"
    
    public var useMentalistAndInspector:Bool = true
    
    
    /// Creates a new team agent with the specified parameters.
    /// - Parameters:
    ///   - id: The unique identifier for the team agent.
    ///   - name: The name of the team agent.
    ///   - agents: An array of agent identifiers that are part of this team.
    ///   - description: An optional description of the team agent's purpose or capabilities.
    ///   - llmID: An optional identifier for the language model associated with this team agent.
    ///   - supplier: An optional supplier information for this team agent.
    ///   - version: An optional version information for this team agent.
    ///   - status: The status of the team agent, defaults to "draft".
    ///   - useMentalistAndInspector: A flag indicating whether to use mentalist and inspector features, defaults to true.
    init(id: String, name: String, agents: [String], description: String? = nil, llmID: String? = nil, supplier: Supplier? = nil, version: Version? = nil, status: String = "draft", useMentalistAndInspector: Bool = true) {
        self.id = id
        self.name = name
        self.agents = agents
        self.description = description
        self.llmID = llmID
        self.supplier = supplier
        self.version = version
        self.status = status
        self.useMentalistAndInspector = useMentalistAndInspector
        self.logger = Logger(subsystem: "aiXplainKit", category: "TeamAgent")
        self.networking = Networking()
        self.supervisorId = llmID
        self.plannerId = llmID
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case agents
        case description
        case llmID = "llm_id"
        case supplier
        case version
        case status
        case useMentalistAndInspector = "use_mentalist_and_inspector"
        case supervisorId = "supervisor_id"
        case plannerId = "planner_id"
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Decode agents array from response format
        let agentsArray = try container.decode([AgentResponse].self, forKey: .agents)
        agents = agentsArray.map { $0.assetId }
        
        description = try container.decodeIfPresent(String.self, forKey: .description)
        llmID = try container.decodeIfPresent(String.self, forKey: .llmID)
        supplier = try container.decodeIfPresent(Supplier.self, forKey: .supplier)
        version = try container.decodeIfPresent(Version.self, forKey: .version)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "draft"
        useMentalistAndInspector = try container.decodeIfPresent(Bool.self, forKey: .useMentalistAndInspector) ?? true
        supervisorId = try container.decodeIfPresent(String.self, forKey: .supervisorId)
        plannerId = try container.decodeIfPresent(String.self, forKey: .plannerId)
        logger = Logger(subsystem: "AiXplain", category: "Agent(\(name))")
        networking = Networking()
    }
    
    private struct AgentResponse: Codable {
        let assetId: String
        let type: String
        let number: Int
        let label: String
        
        private enum CodingKeys: String, CodingKey {
            case assetId
            case type
            case number
            case label
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(agents, forKey: .agents)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(llmID, forKey: .llmID)
        try container.encodeIfPresent(supplier, forKey: .supplier)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encode(status, forKey: .status)
        try container.encode(useMentalistAndInspector, forKey: .useMentalistAndInspector)
        try container.encodeIfPresent(supervisorId, forKey: .supervisorId)
        try container.encodeIfPresent(plannerId, forKey: .plannerId)
    }
    
    
    func encode() throws -> Data {
        let agentDicts = agents.enumerated().map { (idx, agent) in
            [
                "assetId": agent,
                "number": idx,
                "type": "AGENT",
                "label": "AGENT"
            ] as [String: Any]
        }
        
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "agents": agentDicts,
            "links": [],
            "description": description ?? "",
            "llmId": llmID ?? "",
            "supervisorId": supervisorId ?? llmID ?? ""
        ]
        
        if useMentalistAndInspector {
            dict["plannerId"] = plannerId ?? llmID ?? ""
        }
        
        if let supplier = supplier {
            dict["supplier"] = supplier
        }
        
        if let version = version {
            dict["version"] = version
        }
        
        dict["status"] = status
        
        return try JSONSerialization.data(withJSONObject: dict)
    }
    
    
    func update(id:String){
        self.id = id
    }
    
    func update(agents:[String]){
        self.agents = agents
    }
    
    func removeAgent(where removingFunction:(String)->Bool){
        agents.removeAll(where: { agendID in
            return removingFunction(agendID)
        })
    }
}

//MARK: - Execution
extension TeamAgent{
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
        
        guard let url = URL(string: backendURL.absoluteString + Networking.Endpoint.agentCommunityRun(agentIdentifier: self.id).path) else {
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
