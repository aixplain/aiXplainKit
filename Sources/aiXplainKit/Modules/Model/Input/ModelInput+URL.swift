//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 14/03/24.
//

import Foundation

/// An extension that conforms `URL` to the `ModelInput` protocol.
extension URL: ModelInput {

    /// Generates an input payload data for the model.
    ///
    /// - Returns: An empty `Data` instance.
    public func generateInputPayloadForModel() async throws -> Data {
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
            print(payload) // TODO: Fix this
            return Data()
        }

        return jsonData

    }

}
