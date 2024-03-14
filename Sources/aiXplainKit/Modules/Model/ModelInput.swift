//
//  FileHandlingUtilities.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 11/03/24.
//

import Foundation

/// A protocol that defines the requirements for an object to be used as input for a model.
public protocol ModelInput {
    /// Generates an input payload data for the model.
    ///
    /// - Returns: The input payload data for the model.
    func generateInputPayloadForModel() async throws -> Data
}

// MARK: - Foundation Types as Input

/// An extension that conforms `String` to the `ModelInput` protocol.
extension String: ModelInput {
    /// Generates an input payload data for the model by wrapping the string value in a dictionary with the key "data".
    ///
    /// - Returns: The input payload data for the model.
    public func generateInputPayloadForModel() -> Data {
        let payload = ["data": self]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return Data()
        }

        return jsonData
    }
}

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

extension Dictionary: ModelInput where Key == String, Value == Any {
    public func generateInputPayloadForModel() async throws -> Data {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return Data()
        }
        return jsonData
    }
}

// TODO: CombineInputs
