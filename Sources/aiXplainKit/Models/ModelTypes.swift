import Foundation

/// Vendor/supplier metadata from the API response.
public struct VendorInfo: Codable, Sendable {
    public let id: String?
    public let name: String?
    public let code: String?

    public init(id: String? = nil, name: String? = nil, code: String? = nil) {
        self.id = id
        self.name = name
        self.code = code
    }
}

/// Model version information.
public struct ModelVersion: Codable, Sendable {
    public let name: String?
    public let id: String?

    public init(name: String? = nil, id: String? = nil) {
        self.name = name
        self.id = id
    }
}

/// Pricing information for a model.
public struct ModelPricing: Codable, Sendable {
    public let price: Double?
    public let unitType: String?
    public let unitTypeScale: String?

    public init(price: Double? = nil, unitType: String? = nil, unitTypeScale: String? = nil) {
        self.price = price
        self.unitType = unitType
        self.unitTypeScale = unitTypeScale
    }
}

/// Token usage statistics from a model run.
public struct TokenUsage: Codable, Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

/// A single chunk from an SSE stream.
public struct StreamChunk: Sendable {
    public let status: ResponseStatus
    public let data: String
}
