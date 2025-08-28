//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 27/08/25.
//

import Foundation
 
extension Agent{
    //TODO: do this
    public func createSession() async throws -> AgentSession {
        var session = AgentSession()
        let headers = try self.networking.buildHeader()

        let payload: [String: Any] = [
                "id": self.id,
                "query": "/",
                "sessionId": session.id,
                "history": [],
                "executionParams": [
                    "maxTokens": 2048,
                    "maxIterations": 10,
                    "outputFormat": "TEXT",
                    "expectedOutput": NSNull()
                ],
                "allowHistoryAndSessionId": true
            ]
        
        
        guard let backendURL = APIKeyManager.shared.BACKEND_URL else {
            throw AgentsError.missingBackendURL
        }
        
        
        guard let url = URL(string: backendURL.absoluteString + Networking.Endpoint.agentRun(agentIdentifier: self.id).path ) else {
            throw AgentsError.invalidURL(url: backendURL.absoluteString)
        }
        
        
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        let response = try await networking.post(url: url, headers: headers, body: data)
        
        if let httpResponse = response.1 as? HTTPURLResponse,
           httpResponse.statusCode != 201 {
            throw NetworkingError.invalidStatusCode(statusCode: httpResponse.statusCode)
        }

        return AgentSession()
    }
    
    
}



