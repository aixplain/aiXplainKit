//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 12/03/24.
//

import Foundation

///  A struct that represents the output provided by a model when calling `Model.run()`.
///
/// This struct conforms to the `Codable` protocol, which allows it to be encoded and decoded from external representations such as JSON or property lists.
///
/// - Parameters:
///     - `output`: The main output string returned by the model.
///     - `usedCredits`: The number of credits used for running the model.
///     - `runtime`: The time it took to run the model, measured in seconds.
///
public struct ModelOutput: Codable {

   /// The main output string returned by the model.
   public let output: String

   /// The number of credits used for running the model.
   public let usedCredits: Float

   /// The time it took to run the model, measured in seconds.
   public let runtime: TimeInterval

   private enum CodingKeys: String, CodingKey {
       case output = "data"
       case usedCredits
       case runtime = "runTime"
   }

   // MARK: - Codable

   /// Creates a new `ModelOutput` instance by decoding from the given decoder.
   ///
   /// - Parameter decoder: The decoder to read data from.
   /// - Throws: `DecodingError` if there are any issues during decoding.
   public init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       output = try container.decode(String.self, forKey: .output)
       usedCredits = try container.decode(Float.self, forKey: .usedCredits)
       runtime = try container.decode(Double.self, forKey: .runtime)
   }
}
