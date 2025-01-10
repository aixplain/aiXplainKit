//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 06/01/25.
//

import Foundation
extension AgentProvider{
//    //TODO: Document
////Args:
////    name (Text): name of the agent
////    description (Text): description of the agent role.
////    llm_id (Text, optional): aiXplain ID of the large language model to be used as agent. Defaults to "669a63646eb56306647e1091" (GPT-4o mini).
////    tools (List[Tool], optional): list of tool for the agent. Defaults to [].
////    api_key (Text, optional): team/user API key. Defaults to config.TEAM_API_KEY.
////    supplier (Union[Dict, Text, Supplier, int], optional): owner of the agent. Defaults to "aiXplain".
////    version (Optional[Text], optional): version of the agent. Defaults to None.
    public func create(name:String, description:String, llm_id:String = "6646261c6eb563165658bbb1", tools:[CreateAgentTool], suplier:String = "", version:String = "") async throws -> Agent{
        let headers: [String: String] = try networking.buildHeader()

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw AgentsError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.agents(agentIdentifier: "")
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw AgentsError.invalidURL(url: url.absoluteString + endpoint.path)
        }
        
        
        //TODO: Refactor this mess
        let agent = Agent(id: "", name: name, status: "draft", teamId: 0, description: description, llmId: llm_id, createdAt: .now, updatedAt: .now)
        agent.assets = tools.map{ $0.convertToTool()}
        
        print(try? String(data:JSONEncoder().encode(agent),encoding:.utf8))
        
        let response = try await networking.post(url: url, headers: headers, body: JSONEncoder().encode(agent))
        
        print(String(data:response.0,encoding:.utf8))
        return try JSONDecoder().decode(Agent.self, from: response.0)
        
    }
    
}
