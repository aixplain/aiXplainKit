//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 12/05/25.
//

import Foundation

/// A catalogue of embedding models supported by aiXplain.
///
/// Use instances of `EmbeddingModel` when creating vector indexes via
/// `IndexProvider.create(name:description:embedding:engine:)`. Each case
/// encapsulates the identifier required by the aiXplain backend. You can also
/// supply an arbitrary model identifier through the ``custom(id:)`` case.
///
/// ```swift
/// // Create an index backed by the OpenAI Ada v2 embedding model
/// let index = try await IndexProvider().create(
///     name: "Books",
///     description: "Embeddings for the public-domain library",
///     embedding: .OPENAI_ADA002
/// )
/// ```
///
/// To discover the identifiers for new models, consult the aiXplain console or
/// contact support.

public enum EmbeddingModel{
    case SNOWFLAKE_ARCTIC_EMBED_M_LONG
    case OPENAI_ADA002
    case SNOWFLAKE_ARCTIC_EMBED_L_V2_0
    case JINA_CLIP_V2_MULTIMODAL
    case MULTILINGUAL_E5_LARGE
    case BGE_M3
    case AIXPLAIN_LEGAL_EMBEDDINGS
    case custom(id: String)
    
    /// The backend identifier corresponding to the embedding model.
    ///
    /// When the enum case is ``custom(id:)``, the supplied identifier is
    /// returned verbatim; otherwise the constant identifier defined by
    /// aiXplain is provided.
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
    
    /// Retrieves the underlying `Model` instance associated with the selected
    /// embedding model.
    ///
    /// This method performs a network call through ``ModelProvider``.
    ///
    /// - Returns: A fully populated ``Model`` ready to be executed.
    /// - Throws: An error if the model cannot be fetched from the backend.
    func getModel() async throws -> Model {
        return try await ModelProvider().get(self.modelId)
    }
    
}
