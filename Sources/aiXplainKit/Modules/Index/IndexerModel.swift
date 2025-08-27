//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 12/05/25.
//

import Foundation
public enum AiXplainEngine{
    case AIR
    case custom(id:String)
    
    var id:String{
        switch self {
        case .AIR:
            return "66eae6656eb56311f2595011"
        case .custom(id: let id):
            return id
        }
    }
    
    public func getModel() async throws -> Model {
        return try await ModelProvider().get(self.id)
    }
}
