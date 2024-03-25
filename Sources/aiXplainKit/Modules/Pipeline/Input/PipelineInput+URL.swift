//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 22/03/24.
//

import Foundation

/// An extension that conforms `URL` to the `PipelineInput` protocol.
extension URL: PipelineInput {

    /// Generates an input payload data for the pipeline.
    ///
    /// - Returns: An empty `Data` instance.
    public func generateInputPayloadForPipeline() async throws -> Data {
        var payload = ["data": self.absoluteString]

        switch self.absoluteString {
        case let link where link.starts(with: "s3://"):
            break
        case let link where link.starts(with: "http://"):
            break
        case let link where link.starts(with: "https://"):
            break
        default:
            let fileManager = FileUploadManager()
            let s3URL = try await fileManager.uploadFile(at: self)

            payload.updateValue(s3URL.absoluteString, forKey: "data")
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            throw ModelError.failToGenerateAFilePayload(error: String(describing: payload))
        }

        return jsonData

    }

    // TODO: Docs - will only use context if implemented, otherwise no context will be used
    public func generateContextAwareInputPayloadForPipeline(using nodes: [PipelineNode]) async throws -> Data {
        throw fatalError("Not implemented for this kind of input")
    }
}
