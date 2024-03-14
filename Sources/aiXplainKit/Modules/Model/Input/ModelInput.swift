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
