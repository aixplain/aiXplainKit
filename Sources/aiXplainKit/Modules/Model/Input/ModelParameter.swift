//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 03/01/25.
//

import Foundation

/// A struct representing a parameter for a model with its properties and constraints
public struct ModelParameter: Codable, Hashable, Equatable {
    /// The name of the parameter
    public let name: String
    
    /// Whether this parameter is required
    public let required: Bool
    
    /// Whether this parameter has fixed values
    public let isFixed: Bool
    
    /// Possible values for this parameter
    public let values: [Double]
    
    /// Default values for this parameter
    public let defaultValues: [Double]
    
    /// Available options for this parameter
    public let availableOptions: [String]
    
    /// The data type of this parameter
    public let dataType: String
    
    /// The data subtype of this parameter
    public let dataSubType: String
    
    /// Whether this parameter accepts multiple values
    public let multipleValues: Bool
    
    private enum CodingKeys: String, CodingKey {
        case name, required, isFixed, values, defaultValues
        case availableOptions, dataType, dataSubType, multipleValues
    }
}
