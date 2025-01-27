//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 24/01/25.
//

import Foundation
public extension TeamAgentProvider{
    public func create(_ name:String,agents: [Agent], usingLLMID llmID:String = "669a63646eb56306647e1091" ,description:String = "",useMentalistAndSpector:Bool = true) async throws -> TeamAgent{
        
        if agents.isEmpty{
            throw(AgentsError.teamOfAgentsHasNoAgents)
        }
        
        let headers = try networking.buildHeader()
        
        guard let baseURL = APIKeyManager.shared.BACKEND_URL else {
            throw AgentsError.missingBackendURL
        }
        
        let endpoint = Networking.Endpoint.agentCommunities(agentIdentifier: "")
        guard let url = URL(string: baseURL.absoluteString + endpoint.path) else {
            throw AgentsError.invalidURL(url: baseURL.absoluteString + endpoint.path)
        }
        
        
        
        let team = TeamAgent(id: "", name: name,
                             agents: agents.map({$0.id}),
                             description: description,
                             llmID: llmID,
                             supplier: nil,
                             version: nil,
                             useMentalistAndInspector: useMentalistAndSpector)

        let response = try await networking.post(url: url, headers: headers, body: team.encode())
        
        
        if let httpResponse = response.1 as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorData = try? JSONSerialization.jsonObject(with: response.0) as? [String: Any],
                   let message = errorData["message"] as? String {
                    var errorMessage = message
                    
                    switch message {
                    case "err.name_already_exists":
                        errorMessage = "TeamAgent name already exists."
                    case "err.asset_is_not_available": 
                        errorMessage = "Some tools are not available."
                    default:
                        break
                    }
                    
                    throw NetworkingError.invalidStatusCode(statusCode: httpResponse.statusCode)
                    
                    /*(statusCode: httpResponse.statusCode, message: "TeamAgent Onboarding Error: \(errorMessage)")TODO: Inform this */
                } else {
                    throw NetworkingError.invalidStatusCode(statusCode: httpResponse.statusCode)
                }
            }
        }
  
        let teamAgentResponse = try JSONDecoder().decode(TeamAgent.self, from: response.0)
        
        return teamAgentResponse
    }
    
}
