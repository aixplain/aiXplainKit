import Foundation

/// Supported embedding models for index creation.
///
/// Adapted from v1 with Swift `camelCase` convention (resolved question).
public enum EmbeddingModel: Sendable, Identifiable, Hashable {
    case snowflakeArcticEmbedMLong
    case openaiAda002
    case snowflakeArcticEmbedLV20
    case jinaClipV2Multimodal
    case multilingualE5Large
    case bgeM3
    case aixplainLegalEmbeddings
    case custom(id: String)

    public var id: String { modelId }

    var modelId: String {
        switch self {
        case .snowflakeArcticEmbedMLong: return "6658d40729985c2cf72f42ec"
        case .openaiAda002: return "6734c55df127847059324d9e"
        case .snowflakeArcticEmbedLV20: return "678a4f8547f687504744960a"
        case .jinaClipV2Multimodal: return "67c5f705d8f6a65d6f74d732"
        case .multilingualE5Large: return "67efd0772a0a850afa045af3"
        case .bgeM3: return "67efd4f92a0a850afa045af7"
        case .aixplainLegalEmbeddings: return "681254b668e47e7844c1f15a"
        case .custom(let id): return id
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(modelId)
    }

    public static func == (lhs: EmbeddingModel, rhs: EmbeddingModel) -> Bool {
        lhs.modelId == rhs.modelId
    }
}

/// Index engine backend.
///
/// Renamed from v1 `AiXplainEngine` for clarity.
public enum IndexEngine: Sendable {
    case air
    case custom(id: String)

    var id: String {
        switch self {
        case .air: return "66eae6656eb56311f2595011"
        case .custom(let id): return id
        }
    }
}
