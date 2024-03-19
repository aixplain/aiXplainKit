//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 19/03/24.
//
// TODO: Documentation
import Foundation

/// A custom pipeline that can be created on the aiXplain Platform
public final class Pipeline: Decodable {
    public var id: String
    private let apiKey: String  // This API key is dynamic generated for Pipeline-uses only. It is not the same thing as the API key for the model
    public let inputNodes: [PipelineNode]
    public let outputNodes: [PipelineNode]

    /// The networking service is responsible for making API calls and handling URL sessions.
    var networking: Networking

    private let logger: ParrotLogger

    enum CodingKeys: String, CodingKey {
        case id
        case nodes
        case subscription
        case apiKey
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let subscriptionContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .subscription)
        id = try subscriptionContainer.decode(String.self, forKey: .id)
        apiKey = try subscriptionContainer.decode(String.self, forKey: .apiKey)
        inputNodes = try container.decode([PipelineNode].self, forKey: .nodes).filter {$0.type == "INPUT"}
        outputNodes = try container.decode([PipelineNode].self, forKey: .nodes).filter {$0.type == "OUTPUT"}
        networking = Networking()
        logger = ParrotLogger(category: "AiXplainKit | Pipeline")
    }
}

// MARK: - Pipeline Execution

extension Pipeline {

    // TODO: Implement parameters | Docs
    /// Function responsable for running the pipeline
    public func run(_ pipelineInput: PipelineInput, id: String = "model_process", parameters: [String: String]? = nil) async throws {
        let headers = try self.networking.buildHeader()
        let payload = try await pipelineInput.generateInputPayloadForPipeline()
        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingModelRunURL
        }

        let endpoint = Networking.Endpoint.pipelineRun(pipelineIdentifier: self.id).path
        guard let url = URL(string: url.absoluteString + endpoint) else {
            throw PipelineError.invalidURL(url: url.absoluteString)
        }

        logger.debug("Creating a execution with the following payload \(String(data: payload, encoding: .utf8))")
        let response = try await networking.post(url: url, headers: headers, body: payload)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 201 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        let decodedResponse = try JSONDecoder().decode(PipelineExecuteResponse.self, from: response.0)

        guard let pollingURL = decodedResponse.url else {
            throw PipelineError.failToDecodeRunResponse
        }
        logger.info("Successfully created a execution")
        try await self.polling(from: pollingURL)
    }

    // TODO: Docs
    private func polling(from url: URL, maxRetry: Int = 300, waitTime: Double = 0.5) async throws -> ModelOutput {
        let headers = try self.networking.buildHeader()

        var itr = 0

        logger.info("Starting polling job")
        repeat {
            let response = try await networking.get(url: url, headers: headers)
            print(String(data: response.0, encoding: .utf8))
            logger.debug("(\(itr)/\(maxRetry))Polling...")
//            if let json = try? JSONSerialization.jsonObject(with: response.0, options: []) as? [String: Any],
//              let completed = json["completed"] as? Bool {
//
//                if let _ = json["error"] as? String, let supplierError = json["supplierError"] as? String {
//                    throw ModelError.supplierError(error: supplierError)
//                }
//
//                if completed {
//                    do {
//                        let decodedResponse = try JSONDecoder().decode(ModelOutput.self, from: response.0)
//                        logger.info("Polling job finished.")
//                        return decodedResponse
//                    } catch {
//                        throw ModelError.failToDecodeModelOutputDuringPollingPhase(error: String(describing: error))
//                    }
//                }
//            }

            try await Task.sleep(nanoseconds: UInt64(max(0.2, waitTime) * 1_000_000_000))
            itr+=1
        } while itr < maxRetry

        // TODO: Better eerrs
        throw ModelError.pollingTimeoutOnModelResponse(pollingURL: url)
    }
}
