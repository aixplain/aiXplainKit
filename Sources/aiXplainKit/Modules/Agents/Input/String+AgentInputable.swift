//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 18/11/24.
//

import Foundation

/// Extends the `String` type to conform to the `AgentInputable` protocol.
///
/// This allows strings to be used as inputs for agents, enabling them to generate payloads
/// for execution with the specified parameters.
extension String: AgentInputable {
    
    /// Generates a JSON payload to be used as input for an agent.
    ///
    /// This method converts the string into a query payload, merging it with the provided agent
    /// run parameters and optionally adding a session ID. The result is serialized into JSON format.
    ///
    /// - Parameters:
    ///   - using: The `AgentRunParameters` containing additional configuration for the agent execution.
    ///   - id: An optional session ID to include in the payload.
    /// - Returns: A `Data` object containing the JSON representation of the payload.
    ///
    /// # Example
    /// ```swift
    /// let query = "What is the history of AI?"
    /// let parameters = AgentRunParameters()
    /// let sessionID = "session-12345"
    ///
    /// let payload = query.generateInputPayloadForAgent(using: parameters, withID: sessionID)
    /// print(String(data: payload, encoding: .utf8)!) // JSON representation of the payload
    /// ```
    public func generateInputPayloadForAgent(using: AgentRunParameters, withID id: String? = nil) -> Data {
        var payload = ["query": self]
        
        for (key, value) in using.runParametersIterator() {
            payload.updateValue("\(value)", forKey: key)
        }
        
        if let id = id {
            payload.updateValue(id, forKey: "sessionId")
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return Data()
        }

        return jsonData
    }
}
