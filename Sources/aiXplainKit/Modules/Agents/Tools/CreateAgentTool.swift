//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 06/01/25.
//

import Foundation

public enum CreateAgentTool:AgentUsableTool{
    case model(_ model: Model, description:String)
    case pipeline(_ Pipeline: Pipeline, description:String)
    case asset(id:String, description:String)
    case utility(_ model:UtilityModel, description:String)
    case tool(_ tool:AgentUsableTool, description:String)
    
    
    public func convertToTool() -> Tool {
        switch self {
        case .model(let model, let description):
            var tool = model.convertToTool()
            tool.description = description
            return tool
        case .utility(let model, let description):
            var tool = model.convertToTool()
            tool.description = description
            return tool
        case .pipeline(let pipeline, let description):
            var tool = pipeline.convertToTool()
            tool.description = description
            return tool
        case .asset(let id, let description):
            return Tool(id: id, description: description)
        case .tool(let tool, let description):
            var tool = tool.convertToTool()
            tool.description = description
            return tool
        }
    }
    
}
