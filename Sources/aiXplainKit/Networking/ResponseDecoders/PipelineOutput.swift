//
//  File.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 19/03/24.
//

import Foundation

/// Represents the output of an AI pipeline execution.
///
/// This struct encapsulates the raw data returned from the pipeline execution, along with additional metadata such as the number of credits used and the elapsed time for the execution.
public struct PipelineOutput {
    /// The raw data returned from the pipeline execution.
    /// The format of this data depends on the pipeline configuration and needs to be decoded by the user.
    public let rawData: Data

    /// The number of credits used for the pipeline execution.
    public let creditsUsed: Float

    /// The elapsed time for the pipeline execution.
    public let elapsedTime: TimeInterval

    /// Initializes a new instance of `PipelineOutput` by parsing the raw data received from the pipeline execution.
    ///
    /// - Parameter rawData: The raw data received from the pipeline execution.
    public init(from rawData: Data) {

        // Primary Information
        guard let json = try? JSONSerialization.jsonObject(with: rawData, options: []) as? [String: Any] else {
            self.creditsUsed = 0.0
            self.elapsedTime = 0.0
            self.rawData = rawData
            return
        }

        // Secondary Information
        guard let secondaryJson = json["data"] as? Data else {
            self.creditsUsed = (json["used_credits"] as? Float) ?? 0.0
            self.elapsedTime = (json["elapsed_time"] as? TimeInterval) ?? 0.0
            self.rawData = rawData
            return
        }

        self.rawData = secondaryJson
        self.creditsUsed = (json["used_credits"] as? Float) ?? 0.0
        self.elapsedTime = (json["elapsed_time"] as? TimeInterval) ?? 0.0
    }
}
