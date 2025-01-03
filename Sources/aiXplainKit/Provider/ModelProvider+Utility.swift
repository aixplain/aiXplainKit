//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 02/01/25.
//

import Foundation

//TODO: Refactor and document
extension ModelProvider {
    public func createUtilityModel(name:String, code:String, inputs:[UtilityModelInputInformation] = [], description:String, outputExample:String = "") async throws -> UtilityModel{
        
        
        let headers: [String: String] = try networking.buildHeader()

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.utilities
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw ModelError.invalidURL(url: url.absoluteString + endpoint.path)
        }
        
        let utilityModel = UtilityModel(id: "", name:name, code:code, description: description, inputs: inputs, outputExamples: outputExample)
        
        let (data, response) = try await networking.post(url: url, headers: headers, body: JSONEncoder().encode(utilityModel))
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ModelError.noResponse(endpoint: url.absoluteString)
        }
        
        if (200..<300).contains(httpResponse.statusCode) {
            let responseData = try JSONDecoder().decode([String: String].self, from: data)
            if let modelId = responseData["id"] {
                utilityModel.id = modelId
//                logger.info("Utility Model Creation: Model \(modelId) instantiated.") //TODO: Use logger here
                return utilityModel
            }
            else {
                throw ModelError.missingModelUtilityID
            }
        } else {
            let errorMessage = "Utility Model Creation: Failed to create utility model. Status Code: \(httpResponse.statusCode). Error: \(String(data: data, encoding: .utf8) ?? "")"
//            Logger.model.error("\(errorMessage)") //TODO: Use logger here
            throw ModelError.modelUtilityCreationError(error: errorMessage)
            return utilityModel
        }
    }
}
