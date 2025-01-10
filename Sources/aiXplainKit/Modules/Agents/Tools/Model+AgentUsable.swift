//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 06/01/25.
//

import Foundation
extension Model:AgentUsableTool{
    public func convertToTool() -> Tool {
        return Tool(id: self.id, type: .model, function: function,supplier: self.supplier, version: self.version)
    }
}
