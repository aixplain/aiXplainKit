//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 02/01/25.
//

import Foundation

public enum UtilityModelInput{
    case text(name:String, description:String = "")
    case number(name:String, description:String = "")
    case boolean(name:String, description:String = "")
    
    
    func encode() -> UtilityModelInputInformation{
        switch self {
        case .text(name: let name, description: let description):
            return UtilityModelInputInformation(name: name, description: description, type: .text)
        case .number(name: let name, description: let description):
            return UtilityModelInputInformation(name: String(name), description: description, type: .number)
        case .boolean(name: let name, description: let description):
            return UtilityModelInputInformation(name: String(name), description: description, type: .boolean)
        }

    }
}


public enum UtilityModelInputType:String,Codable{
    case text
    case number
    case boolean
}


//TODO: Refactor
public class UtilityModelInputInformation:Codable {
    public let name: String
    public let description: String
    public var type: UtilityModelInputType = .text
    
    
    public init(name: String, description: String, type: UtilityModelInputType = .text) {
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
