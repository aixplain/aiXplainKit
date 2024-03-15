//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 12/03/24.
//

import Foundation

/// Output provided by a model when calling `Model.run()`
public struct ModelOutput: Codable {
    public let output: String
    public let usedCredits: Float
    public let runtime: TimeInterval

    enum CodingKeys: String, CodingKey {
        case output = "data"
        case usedCredits
        case runtime = "runTime"
    }

    // - Throws: DecodingError if there are any issues during decoding.
     public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

         output = try container.decode(String.self, forKey: .output)
         usedCredits = try container.decode(Float.self, forKey: .usedCredits)
         runtime = try container.decode(Double.self, forKey: .runtime)

    }

}
