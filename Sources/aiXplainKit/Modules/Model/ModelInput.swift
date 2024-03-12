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
   func generateInputPayloadForModel() -> Data
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
           // TODO: Handle error case if JSON serialization fails
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
   public func generateInputPayloadForModel() -> Data {
       return Data()
   }
}
