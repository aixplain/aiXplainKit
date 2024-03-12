//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 12/03/24.
//

import Foundation

extension Networking {
    /// This function generates the header nescessary to make the API-calls
    func buildHeader() throws -> [String: String] {
        var headers: [String: String]?
        if let aiXplainKey = APIKeyManager.shared.AIXPLAIN_API_KEY {
            headers =  ["x-aixplain-key": "\(aiXplainKey)", "Content-Type": "application/json"]
        }

        if let teamKey = APIKeyManager.shared.TEAM_API_KEY {
            headers =  ["Authorization": "Token \(teamKey)", "Content-Type": "application/json"]
        }

        guard let headers else {
            throw ModelError.missingAPIKey
        }

        return headers
    }

    func buildUrl(for endpoint: Endpoint) throws -> URL? {

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }
        return URL(string: url.absoluteString + endpoint.path)
    }
}
