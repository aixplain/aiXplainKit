/*
 AiXplainKit Library.
 ---
 
 aiXplain SDK enables Swift programmers to add AI functions
 to their software.
 
 Copyright 2024 The aiXplain SDK authors
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 AUTHOR: João Pedro Maia
 */

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
   
   /// The standard output from the model execution, if any
   public let stdout: String?
   
   /// The standard error from the model execution, if any 
   public let stderr: String?

   /// The number of credits used for running the model.
   public let usedCredits: Float

   /// The time it took to run the model, measured in seconds.
   public let runtime: TimeInterval

   private enum CodingKeys: String, CodingKey {
       case output = "data"
       case stdout
       case stderr
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
       stdout = try container.decodeIfPresent(String.self, forKey: .stdout)
       stderr = try container.decodeIfPresent(String.self, forKey: .stderr)
       usedCredits = try container.decode(Float.self, forKey: .usedCredits)
       runtime = try container.decode(Double.self, forKey: .runtime)
   }
}
