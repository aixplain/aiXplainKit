//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 07/01/25.
//

import Foundation
extension UtilityModel:AgentUsableTool{
    public func convertToTool() -> Tool {
        return Tool(id: self.id, type: .model, function: Function(id: "utilities", name: "Utilites"),supplier: self.supplier, version: self.version)
    }
}
