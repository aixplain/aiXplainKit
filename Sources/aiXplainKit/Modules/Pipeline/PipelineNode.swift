//
//  File.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 19/03/24.
//

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
