//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 19/03/24.
//

import Foundation

// TODO: DOCS
public struct PipelineOutput {
    public let rawData: Data
    public let usedCredits: Float
    public let elapsedTime: TimeInterval

    public init(from rawData: Data) {

        // Primary Information
        guard let json = try? JSONSerialization.jsonObject(with: rawData, options: []) as? [String: Any] else {
            self.usedCredits = 0.0
            self.elapsedTime = 0.0
            self.rawData = rawData
            return
        }

        // Secondary Information
        guard let secondaryJson = json["data"] as? Data else {
            self.usedCredits = (json["used_credits"] as? Float) ?? 0.0
            self.elapsedTime = (json["elapsed_time"] as? TimeInterval) ?? 0.0
            self.rawData = rawData
            return
        }

        self.rawData = secondaryJson
        self.usedCredits = (json["used_credits"] as? Float) ?? 0.0
        self.elapsedTime = (json["elapsed_time"] as? TimeInterval) ?? 0.0
    }
}
