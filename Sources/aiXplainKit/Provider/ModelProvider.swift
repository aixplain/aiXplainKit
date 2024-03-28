//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation
import OSLog

/// A class responsible for fetching model information from the backend.
public final class ModelProvider {

    private let logger = Logger(subsystem: "AiXplinaKit", category: "ModelProvider")

    var networking = Networking()

    public init() {
        self.networking = Networking()
    }

    internal init(networking: Networking) {
        self.networking = networking
    }

    /// Fetches and prints details of the model with the provided ID.
    /// - Parameter modelID: The unique identifier of the model to fetch.
    /// - Throws: `ModelError` if there are issues with API keys, URL construction, or decoding the response.
    /// - Throws: `NetworkingError` if the network request fails with an invalid status code.
    public func get(_ modelID: String) async throws -> Model {

        let headers: [String: String] = try networking.buildHeader()

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.model(modelIdentifier: modelID)
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw ModelError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        let response = try await networking.get(url: url, headers: headers)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 200 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        do {
            logger.debug("\(String(data: response.0, encoding: .utf8)!)")
            let fetchedModel = try JSONDecoder().decode(Model.self, from: response.0)

            logger.info("\(fetchedModel.name) fetched")
            return fetchedModel
        } catch {
            logger.error("\(String(describing: error))")
            throw error
        }

    }

}
