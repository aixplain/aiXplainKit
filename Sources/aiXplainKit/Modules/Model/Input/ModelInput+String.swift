//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 14/03/24.
//

import Foundation
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
