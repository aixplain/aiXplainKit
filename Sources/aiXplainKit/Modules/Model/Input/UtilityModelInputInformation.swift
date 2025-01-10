//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 02/01/25.
//

import Foundation

/// Represents different types of inputs that can be provided to a utility model
public enum UtilityModelInput {
    /// A text input with a name and optional description
    case text(name: String, description: String = "")
    /// A numeric input with a name and optional description 
    case number(name: String, description: String = "")
    /// A boolean input with a name and optional description
    case boolean(name: String, description: String = "")
    
    /// Converts the UtilityModelInput into a UtilityModelInputInformation object
    /// - Returns: A UtilityModelInputInformation object containing the input's details
    func encode() -> UtilityModelInputInformation {
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

/// The possible data types for utility model inputs
public enum UtilityModelInputType: String, Codable {
    /// Text input type
    case text
    /// Numeric input type
    case number
    /// Boolean input type
    case boolean
}

/// Contains information about an input parameter for a utility model
public class UtilityModelInputInformation: Codable {
    /// The name of the input parameter
    public let name: String
    /// A description of the input parameter
    public let description: String
    /// The data type of the input parameter
    public var type: UtilityModelInputType = .text
    
    /// Creates a new UtilityModelInputInformation instance
    /// - Parameters:
    ///   - name: The name of the input parameter
    ///   - description: A description of the input parameter
    ///   - type: The data type of the input parameter (defaults to .text)
    public init(name: String, description: String, type: UtilityModelInputType = .text) {
        self.name = name
        self.description = description
        self.type = type
    }
    
    /// Keys used for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case type
    }
    
    /// Encodes this instance into the given encoder
    /// - Parameter encoder: The encoder to write data to
    /// - Throws: An error if encoding fails
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(type.rawValue, forKey: .type)
    }
}
