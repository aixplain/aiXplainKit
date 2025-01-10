//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 02/01/25.
//

import Foundation

extension ModelProvider {
    /// Creates a new utility model with code provided as a string
    /// - Parameters:
    ///   - name: The name of the utility model
    ///   - code: The code implementation as a string
    ///   - inputs: Array of input parameters that the utility model accepts
    ///   - description: Description of what the utility model does
    ///   - outputExample: Optional example of the model's output format
    /// - Returns: The created UtilityModel instance
    /// - Throws: ModelError if creation fails
    public func createUtilityModel(
        name: String,
        code: String,
        inputs: [UtilityModelInput],
        description: String,
        outputExample: String = ""
    ) async throws -> UtilityModel {
        let headers = try networking.buildHeader()
        
        guard let baseURL = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }
        
        let endpoint = Networking.Endpoint.utilities
        guard let url = URL(string: baseURL.absoluteString + endpoint.path) else {
            throw ModelError.invalidURL(url: baseURL.absoluteString + endpoint.path)
        }
        
        let utilityModel = UtilityModel(
            id: "",
            name: name,
            code: code,
            description: description,
            inputs: inputs,
            outputExamples: outputExample
        )
        
        let encodedModel = try JSONEncoder().encode(utilityModel)
        let (data, response) = try await networking.post(url: url, headers: headers, body: encodedModel)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ModelError.noResponse(endpoint: url.absoluteString)
        }
        
        if (200..<300).contains(httpResponse.statusCode) {
            let responseData = try JSONDecoder().decode([String: String].self, from: data)
            guard let modelId = responseData["id"] else {
                throw ModelError.missingModelUtilityID
            }
            utilityModel.id = modelId
            return utilityModel
        } else {
            let errorMessage = "Utility Model Creation: Failed to create utility model. Status Code: \(httpResponse.statusCode). Error: \(String(data: data, encoding: .utf8) ?? "")"
            throw ModelError.modelUtilityCreationError(error: errorMessage)
        }
    }

    /// Creates a new utility model with code loaded from a file URL
    /// - Parameters:
    ///   - name: The name of the utility model
    ///   - code: URL pointing to the file containing the code implementation
    ///   - inputs: Array of input parameters that the utility model accepts
    ///   - description: Description of what the utility model does
    ///   - outputExample: Optional example of the model's output format
    /// - Returns: The created UtilityModel instance
    /// - Throws: ModelError if creation fails or if code file cannot be read
    public func createUtilityModel(
        name: String,
        code: URL,
        inputs: [UtilityModelInput] = [],
        description: String,
        outputExample: String = ""
    ) async throws -> UtilityModel {
        let codeData = try Data(contentsOf: code)
        guard let codeString = String(data: codeData, encoding: .utf8) else {
            throw ModelError.invalidURL(url: code.absoluteString)
        }
        
        return try await createUtilityModel(
            name: name,
            code: codeString,
            inputs: inputs,
            description: description,
            outputExample: outputExample
        )
    }
}
