//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 06/01/25.
//

import Foundation

//TODO: Refactor
public protocol AgentUsableTool{
    func convertToTool() -> Tool
}


//Specialized software or resource designed to assist the AI in executing specific tasks or functions based on user commands.
public struct Tool: Codable, AgentUsableTool {
    var id: String
    var type: ToolType = .model
    var function: String?
    var supplier: Supplier?
    var description: String = ""
    var version: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "assetId"
        case type
        case function
        case supplier
        case description
        case version
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(ToolType.self, forKey: .type)
        function = try? container.decode(String.self, forKey: .function)
        supplier = try? container.decode(Supplier.self, forKey: .supplier)
        description = try container.decode(String.self, forKey: .description)
        version = try? container.decode(String.self, forKey: .version)
    }
    
    init(id: String, type: ToolType = .model, function: Function? = nil, supplier: Supplier? = nil, description: String = "", version: String? = nil) {
        self.id = id
        self.type = type
        self.function = function?.id
        self.supplier = supplier
        self.description = description
        self.version = version
    }
    
    public func convertToTool() -> Tool {
        self
    }
}

enum ToolType: String, Codable {
    case model
    case pipiline
}
