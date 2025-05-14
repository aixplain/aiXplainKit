//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 12/05/25.
//

import Foundation
public class IndexProvider {
    public init(){}
    
    //TODO: Add Docs
    public func create(name:String,description:String,embedding embeddingModel:EmbeddingModel = EmbeddingModel.OPENAI_ADA002, engine:AiXplainEngine = .AIR) async throws -> IndexModel{
    
        let engine = try await engine.getModel()
        
        let requestPayload: [String: ModelInput] = [
            "data": name,
            "description": description,
            "model": embeddingModel.modelId
        ]
        

        do{
            let response = try await engine.run(requestPayload)
            
            do{
                let indexModel = try await ModelProvider().get(response.output)
                
                return IndexModel(from: indexModel)
                
            }catch{
                throw IndexErrors.failedToCreateIndex(reason: String(describing: error))
            }
            
           
        }catch{

            throw IndexErrors.failedToCreateIndex(reason: String(describing: error))
        }
        
       
    }
    
    
    public func get(_ id:String) async throws -> IndexModel?{
        let indexModel = try await ModelProvider().get(id)
        if indexModel.function?.id != "search" {
            throw IndexErrors.failedToCreateIndex(reason: "The provided ID does not correspond to an index model.")
        }
        
        return IndexModel(from: indexModel)
    }
    
    
}

public enum IndexErrors:Error{
    case failedToCreateIndex(reason:String)
    
    var localizedDescription: String {
        switch self {
        case .failedToCreateIndex(reason: let reason):
            return "Failed to create index. Reason: \(reason)"
        }
    }
}
