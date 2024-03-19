//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 19/03/24.
//

import Foundation

/// A protocol that defines the requirements for an object to be used as input for a pipeline.
public protocol PipelineInput {
    /// Generates an input payload data for the pipeline.
    ///
    /// - Returns: The input payload data for the pipeline.
    func generateInputPayloadForPipeline() async throws -> Data
}
