//
//  File.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 14/03/24.
//

import Foundation
/// An extension that conforms `String` to the `ModelInput` protocol.
extension String: PipelineInput {
    /// Generates an input payload data for the model by wrapping the string value in a dictionary with the key "data".
    ///
    /// - Returns: The input payload data for the model.
    public func generateInputPayloadForPipeline() -> Data {
        let payload = ["data": self]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return Data()
        }

        return jsonData
    }

    // TODO: Docs - will only use context if implemented, otherwise no context will be used
    public func generateContextAwareInputPayloadForPipeline(using nodes: [PipelineNode]) async throws -> Data {
        throw fatalError("Not implemented for this kind of input")
    }

}
