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

/// Represents a supplier of a asset.
public struct Supplier: Codable {
    /// The unique identifier of the supplier.
      let id: Int

      /// The name of the supplier.
    public let name: String

      /// A unique code associated with the supplier.
      let code: String
    
    
    init(id: Int, name: String, code: String) {
        self.id = id
        self.name = name
        self.code = code
    }
    
    /// Creates a new `Supplier` instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? UUID().uuidString.hashValue
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "unknown"
        code = try container.decodeIfPresent(String.self, forKey: .code) ?? "unknown"
    }

    /// Defines the coding keys for the `Supplier` struct.
    private enum CodingKeys: String, CodingKey {
        case id, name, code
    }

}
