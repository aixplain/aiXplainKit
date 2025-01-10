//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 06/01/25.
//

import Foundation

/// Protocol defining requirements for objects that can be used as tools by an agent
public protocol AgentUsableTool {
    /// Converts the implementing type into a Tool object
    func convertToTool() -> Tool
}

/// Represents a specialized software or resource designed to assist AI agents in executing specific tasks or functions based on user commands.
public struct Tool: Codable, AgentUsableTool {
    /// Unique identifier for the tool
    var id: String
    
    /// The type of tool (model or pipeline)
    var type: ToolType = .model
    
    /// Optional identifier for the function this tool provides
    var function: String?
    
    /// Optional supplier information for the tool
    var supplier: Supplier?
    
    /// Description of the tool's purpose and capabilities
    var description: String = ""
    
    /// Optional version identifier for the tool
    var version: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "assetId"
        case type
        case function
        case supplier
        case description
        case version
    }
    
    /// Creates a Tool instance from a decoder
    /// - Parameter decoder: The decoder containing the tool data
    /// - Throws: DecodingError if decoding fails
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(ToolType.self, forKey: .type)
        function = try? container.decode(String.self, forKey: .function)
        supplier = try? container.decode(Supplier.self, forKey: .supplier)
        description = try container.decode(String.self, forKey: .description)
        version = try? container.decode(String.self, forKey: .version)
    }
    
    /// Creates a Tool instance with the specified parameters
    /// - Parameters:
    ///   - id: Unique identifier for the tool
    ///   - type: Type of tool (defaults to .model)
    ///   - function: Optional function associated with the tool
    ///   - supplier: Optional supplier information
    ///   - description: Description of the tool (defaults to empty string)
    ///   - version: Optional version identifier
    init(id: String, type: ToolType = .model, function: Function? = nil, supplier: Supplier? = nil, description: String = "", version: String? = nil) {
        self.id = id
        self.type = type
        self.function = function?.id
        self.supplier = supplier
        self.description = description
        self.version = version
    }
    
    /// Implements AgentUsableTool protocol by returning self
    public func convertToTool() -> Tool {
        self
    }
}

/// Defines the types of tools available in the system
enum ToolType: String, Codable {
    /// Represents an AI model tool
    case model
    /// Represents a pipeline tool
    case pipiline
}
