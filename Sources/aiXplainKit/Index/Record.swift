import Foundation

/// A single item in an index -- text or image with metadata.
///
/// Adapted from v1 `Record` with Sendable conformance and cleanup.
public struct Record: Codable, Identifiable, Sendable {

    public enum DataType: String, Codable, Sendable {
        case text
        case image
    }

    public let id: String
    public let dataType: DataType
    public let value: String
    public let attributes: [String: String]
    public let uri: String?

    public init(text: String, attributes: [String: String] = [:], id: String = UUID().uuidString) {
        self.id = id
        self.dataType = .text
        self.value = text
        self.attributes = attributes
        self.uri = nil
    }

    public init(imageURL: URL, attributes: [String: String] = [:], id: String = UUID().uuidString) {
        self.id = id
        self.dataType = .image
        self.value = ""
        self.attributes = attributes
        self.uri = imageURL.absoluteString
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case data, dataType, documentID = "document_id", uri, attributes
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .data)
        try container.encode(dataType.rawValue, forKey: .dataType)
        try container.encode(id, forKey: .documentID)
        try container.encodeIfPresent(uri, forKey: .uri)
        try container.encode(attributes, forKey: .attributes)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(String.self, forKey: .data)
        let typeStr = try container.decode(String.self, forKey: .dataType)
        dataType = DataType(rawValue: typeStr) ?? .text
        id = try container.decode(String.self, forKey: .documentID)
        uri = try container.decodeIfPresent(String.self, forKey: .uri)
        attributes = try container.decodeIfPresent([String: String].self, forKey: .attributes) ?? [:]
    }

    /// Dictionary for API payloads.
    public func toDictionary() -> [String: Any] {
        [
            "data": value,
            "dataType": dataType.rawValue,
            "document_id": id,
            "attributes": attributes,
            "uri": uri ?? ""
        ]
    }
}
