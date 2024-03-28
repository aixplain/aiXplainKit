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

public struct PipelineNode: Decodable, Identifiable, Hashable {
    let number: Int
    let label: String
    let dataType: [String]
    let type: String

    public var id: String {
        return "\(number)"
    }

    enum CodingKeys: String, CodingKey {
        case number, label, dataType, type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        label = try container.decode(String.self, forKey: .label)
        dataType = try container.decodeIfPresent([String].self, forKey: .dataType) ?? []
        type = try container.decode(String.self, forKey: .type)
    }

}
