//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 02/01/25.
//

import Foundation

public enum ValidUtilityModelInputType:String,Codable{
    case text
    case number
    case boolean
}


//TODO: Refactor
public struct UtilityModelInput: Codable {
    public let name: String
    public let description: String
    public var type: ValidUtilityModelInputType = .text
    
    
    public init(name: String, description: String, type: ValidUtilityModelInputType = .text) {
        self.name = name
        self.description = description
        self.type = type
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case type
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(type.rawValue, forKey: .type)
    }
}
