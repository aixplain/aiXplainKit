//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 19/03/24.
//

import Foundation

// TODO: DOCS
struct PipelineOutput {
    /// The main output string returned by the model.
    public let output: String

    /// The number of credits used for running the model.
    public let usedCredits: Float

    /// The time it took to run the model, measured in seconds.
    public let runtime: TimeInterval
}
