//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 19/03/24.
//

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
