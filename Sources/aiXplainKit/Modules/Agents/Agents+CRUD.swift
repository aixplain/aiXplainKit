//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 07/01/25.
//

import Foundation
//MARK: - Deploy, update, delete
extension Agent {
    public func deploy()async throws {
        self.status = "onboarded"
        try await self.update()
    }
    
    //TODO: Document, better namming
    public func addNewTools(_ tools:[CreateAgentTool]) async throws {
        tools.forEach { tool in
            let tool = tool.convertToTool()
            self.assets.append(tool)
        }
        
        try await update()
    }

    
    func update()async throws {
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
            //self = decodedResponse//TODO: Assing each property
        } catch {
            //TODO: Propper error, coult not update, agent error?
            throw ModelError.unableToUpdateModelUtility(error: error.localizedDescription)
        }
    }
    
    
    public func delete()async throws {
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
            //TODO: Propper error -> Should indicate delete was not sucessfull
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }
        
        
    }
    
}
