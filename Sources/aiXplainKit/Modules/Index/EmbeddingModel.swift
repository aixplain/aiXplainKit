//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 12/05/25.
//

import Foundation

//TODO: Docs
public enum EmbeddingModel{
    case SNOWFLAKE_ARCTIC_EMBED_M_LONG
    case OPENAI_ADA002
    case SNOWFLAKE_ARCTIC_EMBED_L_V2_0
    case JINA_CLIP_V2_MULTIMODAL
    case MULTILINGUAL_E5_LARGE
    case BGE_M3
    case AIXPLAIN_LEGAL_EMBEDDINGS
    case custom(id: String)
    
    var modelId: String {
        switch self {
        case .SNOWFLAKE_ARCTIC_EMBED_M_LONG:
            return "6658d40729985c2cf72f42ec"
        case .OPENAI_ADA002:
            return "6734c55df127847059324d9e"
        case .SNOWFLAKE_ARCTIC_EMBED_L_V2_0:
            return "678a4f8547f687504744960a"
        case .JINA_CLIP_V2_MULTIMODAL:
            return "67c5f705d8f6a65d6f74d732"
        case .MULTILINGUAL_E5_LARGE:
            return "67efd0772a0a850afa045af3"
        case .BGE_M3:
            return "67efd4f92a0a850afa045af7"
        case .AIXPLAIN_LEGAL_EMBEDDINGS:
            return "681254b668e47e7844c1f15a"
        case .custom(id: let id):
            return id
        }
    }
    
    
    func getModel() async throws -> Model {
        return try await ModelProvider().get(self.modelId)
    }
    
}
