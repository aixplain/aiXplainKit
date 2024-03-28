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
A custom pipeline that can be created on the aiXplain Platform.

## Overview
The `Pipeline` class represents a custom pipeline on the aiXplain Platform. It provides functionality to run the pipeline and handle its execution.

## Usage
1. Initialize a `Pipeline` object with the necessary parameters.
2. Call the `run(_:id:parameters:)` method to execute the pipeline.

## Example
```swift
let pipeline = PipelineFactory.get("PipelineID")
let input = "Hello World"
do {
    let output = try await pipeline.run(input)
    // Handle pipeline output
} catch {
    // Handle errors
}```
 */
public final class Pipeline: Decodable, CustomStringConvertible {
    /// The unique identifier of the pipeline.
    public var id: String

    /// The API key generated for pipeline usage.
    private let apiKey: String

    /// An array of input nodes in the pipeline.
    public let inputNodes: [PipelineNode]

    /// An array of output nodes in the pipeline.
    public let outputNodes: [PipelineNode]

    /// The networking service responsible for making API calls.
    var networking: Networking

    /// The logger used for logging pipeline events.
    private let logger: Logger

    enum CodingKeys: String, CodingKey {
        case id
        case nodes
        case subscription
        case apiKey
    }

    /// Initializes a pipeline object from decoder.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let subscriptionContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .subscription)
        id = try subscriptionContainer.decode(String.self, forKey: .id)
        apiKey = try subscriptionContainer.decode(String.self, forKey: .apiKey)
        inputNodes = try container.decode([PipelineNode].self, forKey: .nodes).filter {$0.type == "INPUT"}
        outputNodes = try container.decode([PipelineNode].self, forKey: .nodes).filter {$0.type == "OUTPUT"}
        networking = Networking()
        logger = Logger(subsystem: "AiXplain", category: "Pipeline")
    }

    public var description: String {
        var description = "Pipeline:\n"
        description += "  ID: \(id)\n"
        description += "  <- Input:\n"
        inputNodes.forEach { node in
            description += "\t[\(node.number)]\(node.label):\(node.type)\n"
        }
        description += "  -> output:\n"
        outputNodes.forEach { node in
            description += "\t[\(node.number)]\(node.label):\(node.type)\n"
        }
        return description
    }

}

// MARK: - Pipeline Execution

extension Pipeline {

    /**
     Runs the pipeline with the provided input.

     - Parameters:
        - pipelineInput: The input data for the pipeline.
        - executionIdentifier: The identifier for the pipeline execution (default value: "model_process").
        - parameters: Additional parameters for the pipeline execution (default value: nil).
     - Returns: A `PipelineOutput` object representing the output of the pipeline.
     - Throws: Throws an error if the pipeline execution fails.
     */
    public func run(_ pipelineInput: PipelineInput, id: String = "model_process", parameters: PipelineRunParameters = PipelineRunParameters.defaultParameters) async throws -> PipelineOutput {
        let headers = try self.networking.buildHeader()
        let payload = try await pipelineInput.generateInputPayloadForPipeline()

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingModelRunURL
        }

        self.networking.parameters = parameters
        let endpoint = Networking.Endpoint.pipelineRun(pipelineIdentifier: self.id).path
        guard let url = URL(string: url.absoluteString + endpoint) else {
            throw PipelineError.invalidURL(url: url.absoluteString)
        }

        logger.debug("Creating a execution with the following payload \(String(data: payload, encoding: .utf8) ?? "-")")
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
        return try await self.polling(from: pollingURL, maxRetry: parameters.maxPollingRetries, waitTime: parameters.pollingWaitTimeInSeconds)
    }

    /**
     Polls the specified URL for pipeline output.
     
     - Parameters:
        - url: The URL to poll for pipeline output.
        - maxRetry: The maximum number of polling retries (default value: 300).
        - waitTime: The time to wait between polling attempts in seconds (default value: 0.5).
     - Returns: A `PipelineOutput` object representing the output of the pipeline.
     - Throws: Throws an error if polling fails or times out.
     */
    private func polling(from url: URL, maxRetry: Int = 300, waitTime: Double = 0.5) async throws -> PipelineOutput {
        let headers = try self.networking.buildHeader()

        var itr = 0
        logger.info("Starting polling job")
        repeat {
            let response = try await networking.get(url: url, headers: headers)
            print(String(data: response.0, encoding: .utf8))
            logger.debug("(\(itr)/\(maxRetry))Polling...")
            if let json = try? JSONSerialization.jsonObject(with: response.0, options: []) as? [String: Any],
              let completed = json["completed"] as? Bool {
                if let _ = json["error"] as? String, let supplierError = json["supplierError"] as? String {
                    throw ModelError.supplierError(error: supplierError)
                }

                if completed {
                    do {
                        let partialyDecodedResponse = PipelineOutput(from: response.0)
                        logger.info("Polling job finished.")
                        return partialyDecodedResponse
                    } catch {
                        throw PipelineError.failToDecodeModelOutputDuringPollingPhase(error: String(describing: error))
                    }
                }
            }

            try await Task.sleep(nanoseconds: UInt64(max(0.2, waitTime) * 1_000_000_000))
            itr+=1
        } while itr < maxRetry

        throw PipelineError.pollingTimeoutOnModelResponse(pollingURL: url)
    }
}
