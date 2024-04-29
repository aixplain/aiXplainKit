/*
 AiXplainKit Library.
 ---
 
 aiXplain SDK enables Swift programmers to add AI functions
 to their software.
 
 Copyright 2024 The aiXplain SDK authors
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 AUTHOR: João Pedro Maia
 */

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
            if fetchedModel.id.count <= 1 {
                fetchedModel.id = modelID
            }

            logger.info("\(fetchedModel.name) fetched")
            return fetchedModel
        } catch {
            logger.error("\(String(describing: error))")
            throw error
        }

    }

}
