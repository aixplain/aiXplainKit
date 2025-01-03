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

/**
 This is ready-to-use AI model.

## Overview
The `Model` class represents a ready to use AI Model on the aiXplain Platform. It provides functionality to run the Model and handle its execution.

## Usage
1. Initialize a `Model` object with the necessary parameters.
2. Call the `run(_:id:parameters:)` method to execute the pipeline.

## Example
```swift
let model = ModelProvider.get("ModelID")
let input = "Hello World"
do {
    let output = try await model.run(input)
    // Handle model output
} catch {
    // Handle errors
}```
 */
public class Model: DecodableAsset, EncodableAsset, CustomStringConvertible {

    /// Unique identifier for the model.
    public var id: String

    /// Name of the model.
    public var name: String

    /// Description of the model's functionality.
    public let modelDescription: String

    /// The entity that provides the model.
    public var supplier: Supplier

    /// Version of the model.
    public var version: String

    /// Optional license information associated with the model.
    public let license: License?

    /// Optional privacy information associated with the model.
    public let privacy: Privacy?

    /// Information about the model's pricing.
    public let pricing: Pricing

    /// The networking service responsible for making API calls and handling URL sessions.
    var networking: Networking
    
    /// The entity or platform hosting the model.
    public let hostedBy: String
    
    /// The organization or individual who developed the model.
    public let developedBy: String

    /// Parameters that can be passed to the model during execution
    public let parameters: [ModelParameter]

    private let logger: Logger
    
    public var description: String = ""

    public var debugDescription: String {
        var description = "Model:\n"
        description += "  ID: \(id)\n"
        description += "  Name: \(name)\n"
        description += "  Description: \(self.modelDescription)\n"
        description += "  Hosted By: \(hostedBy)\n"
        description += "  Developed By: \(developedBy)\n"
        description += "  Version: \(version)\n"
        description += "  Pricing: \(pricing)\n"
        if !parameters.isEmpty {
            description += "  Parameters:\n"
            for param in parameters {
                description += "    - \(param.name) (\(param.dataType))\n"
                description += "      Required: \(param.required)\n"
                if !param.availableOptions.isEmpty {
                    description += "      Options: \(param.availableOptions.joined(separator: ", "))\n"
                }
                if !param.defaultValues.isEmpty {
                    description += "      Default Values: \(param.defaultValues)\n"
                }
            }
        }
        return description
    }

    // MARK: - Initialization

    /// Creates a new `Model` instance from the provided decoder. Mainly used to decode JSON data.
    /// - Parameter decoder: The decoder to use for decoding the model.
    /// - Throws: `DecodingError` if there are any issues during decoding.
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        name = try container.decode(String.self, forKey: .name)
        modelDescription = try container.decodeIfPresent(String.self, forKey: .description) ?? "An ML Model"
        description = modelDescription
        supplier = try container.decodeIfPresent(Supplier.self, forKey: .supplier) ?? Supplier(id: 0, name: "no", code: "")
        version = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .version).decodeIfPresent(String.self, forKey: .id) ?? "-"
        pricing = try container.decode(Pricing.self, forKey: .pricing)
        hostedBy = try container.decode(String.self, forKey: .hostedBy)
        developedBy = try container.decode(String.self, forKey: .developedBy)
        parameters = (try? container.decodeIfPresent([ModelParameter].self, forKey: .params)) ?? []
        
        privacy = nil
        license = nil
        logger = Logger(subsystem: "AiXplain", category: "Model(\(name)")
        networking = Networking()
    }
    
    /// Creates a new `Model` instance with the provided parameters.
    /// - Parameters:
    ///   - id: Unique identifier for the model.
    ///   - name: Name of the model.
    ///   - description: Description of the model's functionality.
    ///   - supplier: The entity that provides the model.
    ///   - version: Version of the model.
    ///   - license: Optional license information associated with the model.
    ///   - privacy: Optional privacy information associated with the model.
    ///   - pricing: Information about the model's pricing.
    ///   - hostedBy: The entity or platform hosting the model.
    ///   - developedBy: The organization or individual who developed the model.
    ///   - networking: Networking service used for API calls.
    public init(id: String, name: String, description: String, supplier: Supplier, version: String, license: License? = nil, privacy: Privacy? = nil, pricing: Pricing, hostedBy: String, developedBy: String, networking: Networking) {
        self.id = id
        self.name = name
        self.modelDescription = description
        self.description = modelDescription
        self.supplier = supplier
        self.version = version
        self.license = license
        self.privacy = privacy
        self.pricing = pricing
        self.hostedBy = hostedBy
        self.developedBy = developedBy
        self.parameters = []
        self.logger = Logger(subsystem: "AiXplain", category: "Model(\(name)")
        self.networking = networking
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(modelDescription, forKey: .description)
        try container.encode(supplier, forKey: .supplier)
        try container.encode(version, forKey: .version)
        try container.encode(license, forKey: .license)
        try container.encode(privacy, forKey: .privacy)
        try container.encode(pricing, forKey: .pricing)
        try container.encode(hostedBy, forKey: .hostedBy)
        try container.encode(developedBy, forKey: .developedBy)
        try container.encode(parameters, forKey: .params)
    }

    // Private enum for coding keys to improve readability and maintainability.
    private enum CodingKeys: String, CodingKey {
        case id, name, description, supplier, version, license, privacy, pricing, hostedBy, developedBy, params
    }
}

// MARK: - Model Execution

extension Model {
    // Runs the model with the provided input and parameters.
    /// - Parameters:
    ///   - modelInput: The input data for the model.
    ///   - modelRunIdentifier: A unique identifier for the model run. Default is "model_process".
    ///   - runParameters: Parameters for the model run, such as polling wait time and retry limits.
    ///
    /// - Returns: The output of the model run.
    ///
    /// - Throws:
    ///   - ModelError: If there are any issues related to the model itself.
    ///   - NetworkingError: If there are any networking issues during the model run.
    public func run(_ modelInput: ModelInput, id: String = "model_process", parameters: ModelRunParameters = .defaultParameters) async throws -> ModelOutput {
        let headers = try self.networking.buildHeader()
        let payload = try await modelInput.generateInputPayloadForModel()
        guard let url = APIKeyManager.shared.MODELS_RUN_URL else {
            throw ModelError.missingModelRunURL
        }

        guard let url = URL(string: url.absoluteString + self.id) else {
            throw ModelError.invalidURL(url: url.absoluteString)
        }

        logger.debug("Creating a execution with the following payload \(String(data: payload, encoding: .utf8) ?? "-")")
        networking.parameters = parameters
        let response = try await networking.post(url: url, headers: headers, body: payload)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 201 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        let decodedResponse = try JSONDecoder().decode(ModelExecuteResponse.self, from: response.0)

        guard let pollingURL = decodedResponse.pollingURL else {
            throw ModelError.failToDecodeRunResponse
        }
        logger.info("Successfully created a execution")
        return try await polling(from: pollingURL,
                                 maxRetry: parameters.maxPollingRetries,
                                 waitTime: parameters.pollingWaitTimeInSeconds)

    }

    /// Keeps polling the platform to check whether an asynchronous model run is complete.
    /// - Parameters:
    ///   - url: The URL to poll for the model run result.
    ///   - maxRetries: The maximum number of retries before giving up. Default is 300.
    ///   - waitTime: The time to wait between retries in seconds. Default is 0.5 seconds.
    /// - Returns: The output of the model run.
    /// - Throws: `ModelError` or `NetworkingError` if there are any issues during polling.
    private func polling(from url: URL, maxRetry: Int = 300, waitTime: Double = 0.5) async throws -> ModelOutput {
        let headers = try self.networking.buildHeader()

        var itr = 0

        logger.info("Starting polling job")
        repeat {
            let response = try await networking.get(url: url, headers: headers)

            logger.debug("(\(itr)/\(maxRetry))Polling...")
            if let json = try? JSONSerialization.jsonObject(with: response.0, options: []) as? [String: Any],
               let completed = json["completed"] as? Bool {

                if let _ = json["error"] as? String, let supplierError = json["supplierError"] as? String {
                    throw ModelError.supplierError(error: supplierError)
                }

                if completed {
                    do {
                        let decodedResponse = try JSONDecoder().decode(ModelOutput.self, from: response.0)
                        logger.info("Polling job finished.")
                        return decodedResponse
                    } catch {
                        throw ModelError.failToDecodeModelOutputDuringPollingPhase(error: String(describing: error))
                    }
                }
            }

            try await Task.sleep(nanoseconds: UInt64(max(0.2, waitTime) * 1_000_000_000))
            itr+=1
        } while itr < maxRetry

        throw ModelError.pollingTimeoutOnModelResponse(pollingURL: url)
    }
}
