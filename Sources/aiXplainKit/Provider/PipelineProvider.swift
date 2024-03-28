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

public final class PipelineProvider {
    private let logger = Logger(subsystem: "AiXplain", category: "PipelineProvider")

    var networking = Networking()

    public init() {
        self.networking = Networking()
    }

    internal init(networking: Networking) {
        self.networking = networking
    }

    public func get(_ pipelineID: String) async throws -> Pipeline {

        let headers: [String: String] = try networking.buildHeader()

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw PipelineError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.pipelines(pipelineIdentifier: pipelineID)
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw ModelError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        let response = try await networking.get(url: url, headers: headers)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 200 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        do {
            let fetchedPipeline = try JSONDecoder().decode(Pipeline.self, from: response.0)
            fetchedPipeline.id = pipelineID
            return fetchedPipeline
        } catch {
            logger.error("\(error.localizedDescription)")
            throw error
        }

    }

}
