//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 06/01/25.
//

import Foundation
extension Pipeline:AgentUsableTool{
    public func convertToTool() -> Tool {
        return Tool(id: self.id, type: .pipiline, function: Function(id: "pipeline", name: "pipeline"))
    }
    
    
    
}
