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
///
/// The `ModelProvider` class interacts with the backend services to retrieve information
/// about specific models or lists of models using queries.
public final class ModelProvider {

    // MARK: - Properties

    /// A logger instance for recording events and debugging information.
    private let logger = Logger(subsystem: "AiXplinaKit", category: "ModelProvider")

    /// The networking service used to make API calls.
    var networking = Networking()

    // MARK: - Initializers

    /// Initializes a new instance of `ModelProvider`.
    public init() {
        self.networking = Networking()
    }

    /// Internal initializer for testing or dependency injection purposes.
    ///
    /// - Parameter networking: A pre-configured `Networking` instance.
    internal init(networking: Networking) {
        self.networking = networking
    }

    // MARK: - Methods

    /// Fetches the details of a model with the specified ID.
    ///
    /// This method sends a request to the backend to retrieve the details of a specific model
    /// identified by its unique ID. The response is decoded into a `Model` object.
    ///
    /// - Parameter modelID: The unique identifier of the model to fetch.
    /// - Returns: A `Model` object containing the details of the fetched model.
    /// - Throws:
    ///   - `ModelError.missingBackendURL` if the backend URL is not configured.
    ///   - `ModelError.invalidURL` if the constructed URL is invalid.
    ///   - `NetworkingError.invalidStatusCode` if the response status code is not 200.
    ///   - `DecodingError` if the response cannot be decoded into a `Model` object.
    ///
    /// # Example
    /// ```swift
    /// let modelProvider = ModelProvider()
    /// do {
    ///     let model = try await modelProvider.get("model-12345")
    ///     print("Fetched model: \(model.name)")
    /// } catch {
    ///     print("Failed to fetch model: \(error)")
    /// }
    /// ```
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
    
    /// Lists models based on the specified query.
    ///
    /// This method sends a paginated request to the backend to retrieve a list of models
    /// matching the provided query parameters. The response is parsed into an array of `Model` objects.
    ///
    /// - Parameter query: A `ModelQuery` object defining the search parameters.
    /// - Returns: An array of `Model` objects matching the query.
    /// - Throws:
    ///   - `ModelError.missingBackendURL` if the backend URL is not configured.
    ///   - `ModelError.invalidURL` if the constructed URL is invalid.
    ///   - `NetworkingError.invalidStatusCode` if the response status code is not 201.
    ///   - `PipelineError.inputEncodingError` if the query cannot be serialized into JSON.
    ///
    /// # Example
    /// ```swift
    /// let query = ModelQuery(query: "AI models", pageNumber: 1, pageSize: 20, functions: ["text-analysis"])
    /// let modelProvider = ModelProvider()
    /// do {
    ///     let models = try await modelProvider.list(query)
    ///     print("Fetched models: \(models.count)")
    /// } catch {
    ///     print("Failed to fetch models: \(error)")
    /// }
    /// ```
    public func list(_ query: ModelQuery) async throws -> [Model] {
        let headers: [String: String] = try networking.buildHeader()

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.paginateModels
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw ModelError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        let body = try query.buildQuery()
        let response = try await networking.post(url: url, headers: headers, body: body)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 201 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        if let stringedResponse = String(data: response.0, encoding: .utf8) {
            return parseModelQueryResponse(stringedResponse) ?? []
        }
        return []
    }
    
    
    public func listFunctions() async throws -> FunctionListResponse {
        let headers: [String: String] = try networking.buildHeader()

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.functions
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw ModelError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        let response = try await networking.get(url: url,headers: headers)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 200 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }
        
        let functionListResponse = try! JSONDecoder().decode(FunctionListResponse.self, from: response.0)
        
        return functionListResponse
    }

    /// Parses a JSON string response into an array of `Model` objects.
    ///
    /// This method extracts the "items" array from the JSON response and decodes it
    /// into an array of `Model` objects.
    ///
    /// - Parameter jsonData: A JSON string containing the response from the backend.
    /// - Returns: An optional array of `Model` objects if parsing succeeds, or `nil` if parsing fails.
    private func parseModelQueryResponse(_ jsonData: String) -> [Model]? {
        guard let data = jsonData.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let itemsData = json["items"] as? [[String: Any]] else {
            return nil
        }

        let items = itemsData.compactMap { itemDict -> Model? in
            guard let itemData = try? JSONSerialization.data(withJSONObject: itemDict, options: []) else {
                return nil
            }

            return try? JSONDecoder().decode(Model.self, from: itemData)
        }

        return items
    }
}
