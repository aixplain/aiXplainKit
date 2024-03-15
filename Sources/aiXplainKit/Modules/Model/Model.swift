//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation

// TODO: Add example on how to use it, how to set the API key too
// TODO: Custom String decodable
/// This is ready-to-use AI model. This model can be run in both synchronous and asynchronous manner.
public final class Model: DecodableAsset, CustomStringConvertible {

        /// Unique identifier for the model.
        public let id: String

        /// Name of the model.
        public let name: String

        /// Description of the model's functionality.
        public let modelDescription: String

        /// The entity that provides the model.
        public let supplier: Supplier

        /// Version of the model.
        public let version: String

        /// Optional license information associated with the model.
        public let license: License?

        /// Optional privacy information associated with the model.
        public let privacy: Privacy?

        /// Information about the model's pricing.
        public let pricing: Pricing

        /// The networking service is responsible for making API calls and handling URL sessions.
        var networking: Networking

        private let logger: ParrotLogger

    public var description: String {
        var description = "Model:\n"
                description += "  ID: \(id)\n"
                description += "  Name: \(name)\n"
                description += "  Description: \(self.modelDescription)\n"
                description += "  Supplier: \(supplier)\n"
                description += "  Version: \(version)\n"
                description += "  Pricing: \(pricing)\n"
        return description
    }

        // MARK: - Initialization

    /// Creates a new `Model` instance from the provided decoder. Mainly used to decode JSON data.
    /// - Parameter decoder: The decoder to use for decoding the model.
    /// - Throws: `DecodingError` if there are any issues during decoding.
         public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            modelDescription = try container.decodeIfPresent(String.self, forKey: .description) ?? "An ML Model"
            supplier = try container.decode(Supplier.self, forKey: .supplier)

            version = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .version).decodeIfPresent(String.self, forKey: .id) ?? "-"

            pricing = try container.decode(Pricing.self, forKey: .pricing)

            privacy = nil
            license = nil

            logger = ParrotLogger(category: "AiXplainKit | Model(\(name)")

            networking = Networking()
        }

        /// Creates a new `MLModel` instance with the provided parameters.
        /// - Parameters:
        ///   - id: Unique identifier for the model.
        ///   - name: Name of the model.
        ///   - description: Description of the model's functionality.
        ///   - supplier: The entity that provides the model.
        ///   - version: Version of the model.
        ///   - license: Optional license information associated with the model.
        ///   - privacy: Optional privacy information associated with the model.
        ///   - pricing: Information about the model's pricing.
    public init(id: String, name: String, description: String, supplier: Supplier, version: String, license: License? = nil, privacy: Privacy? = nil, pricing: Pricing, networking: Networking) {
            self.id = id
            self.name = name
            self.modelDescription = description
            self.supplier = supplier
            self.version = version
            self.license = license
            self.privacy = privacy
            self.pricing = pricing
            self.logger = ParrotLogger(category: "AiXplainKit | Model(\(name))")
            self.networking = networking
        }

    // Private enum for coding keys to improve readability and maintainability.
    private enum CodingKeys: String, CodingKey {
        case id, name, description, supplier, version, license, privacy, pricing
    }

}

// MARK: - Model Execution

extension Model {
    // Runs the model with the provided input and parameters.
       /// - Parameters:
       ///   - modelInput: The input data for the model.
       ///   - id: The unique identifier for the model run. Default is "model_process".
       ///   - parameters: Optional dictionary of parameters for the model run.
       /// - Returns: The output of the model run.
       /// - Throws: `ModelError` or `NetworkingError` if there are any issues during the model run.
    public func run(_ modelInput: ModelInput, id: String = "model_process", parameters: [String: String]? = nil) async throws -> ModelOutput {
        let headers = try self.networking.buildHeader()
        let payload = try await modelInput.generateInputPayloadForModel()

        guard let url = APIKeyManager.shared.MODELS_RUN_URL else {
            throw ModelError.missingModelRunURL
        }

        guard let url = URL(string: url.absoluteString + self.id) else {
            throw ModelError.invalidURL(url: url.absoluteString)
        }

        logger.debug("Creating a execution with the following payload \(String(data: payload, encoding: .utf8))")
        let response = try await networking.post(url: url, headers: headers, body: payload)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 201 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        let decodedResponse = try JSONDecoder().decode(ExecuteResponse.self, from: response.0)

        guard let pollingURL = decodedResponse.pollingURL else {
            throw ModelError.failToDecodeRunResponse
        }
        logger.info("Successfully created a execution")
        return try await polling(from: pollingURL)

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
