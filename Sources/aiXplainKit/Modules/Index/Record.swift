//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 13/05/25.
//

import Foundation

/// A `Record` represents a single item in the index – either text or an image reference – together with
/// optional metadata that can later be used for filtering or retrieval.
///
/// The struct is lightweight and `Codable`, so it can be (de)serialised when sent over the network.
public struct Record: Codable, Identifiable {

    // MARK: - Public Types

    /// The underlying type of the record’s payload.
    public enum RecordDataType: String, Codable {
        case text  = "text"
        case image = "image"
    }

    // MARK: - Public Stored Properties

    public let id: String
    public private(set) var recordDataType: RecordDataType
    public private(set) var value: String
    public private(set) var attributes: [String: String]
    public private(set) var uri: URL?

    // MARK: - Initialisers

    /// Creates a textual record.
    public init(text: String,
                attributes: [String: String] = [:],
                id: String = UUID().uuidString) {
        self.id = id
        self.recordDataType = .text
        self.value = text
        self.attributes = attributes
        self.uri = nil
    }

    /// Creates an image record.
    public init(image: URL,
                attributes: [String: String] = [:],
                id: String = UUID().uuidString) {
        self.id = id
        self.recordDataType = .image
        self.value = ""
        self.attributes = attributes
        self.uri = image
    }

    /// Asynchronously extracts text from a remote resource and initialises a textual record with the result.
    ///
    /// The extraction closure allows callers to supply their own extraction logic (OCR, web scraping, etc.)
    /// while keeping the model agnostic.
    ///
    /// - Parameters:
    ///   - url:        The source `URL`.
    ///   - attributes: Optional metadata to attach.
    ///   - extraction: A closure that receives the `URL` and returns the extracted string.
    public init(from url: URL,
                attributes: [String: String] = [:],
                using extraction: (URL) async throws -> String) async throws {
        let extractedText = try await extraction(url)
        self.init(text: extractedText, attributes: attributes)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case data        = "data"
        case dataType    = "dataType"
        case documentID  = "document_id"
        case uri         = "uri"
        case attributes  = "attributes"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .data)
        try container.encode(recordDataType.rawValue, forKey: .dataType)
        try container.encode(id, forKey: .documentID)
        try container.encodeIfPresent(uri?.absoluteString, forKey: .uri)
        try container.encode(attributes, forKey: .attributes)
    }

    public init(from decoder: Decoder) throws {
        let container      = try decoder.container(keyedBy: CodingKeys.self)
        self.value         = try container.decode(String.self, forKey: .data)
        self.recordDataType = RecordDataType(rawValue: try container.decode(String.self, forKey: .dataType)) ?? .text
        self.id            = try container.decode(String.self, forKey: .documentID)
        if let uriString = try container.decodeIfPresent(String.self, forKey: .uri) {
            self.uri = URL(string: uriString)
        } else {
            self.uri = nil
        }
        self.attributes    = try container.decodeIfPresent([String: String].self, forKey: .attributes) ?? [:]
    }

    // MARK: - Convenience

    /// Returns a dictionary representation mirroring the expected server‑side format.
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "data": value,
            "dataType": recordDataType.rawValue,
            "document_id": id,
            "attributes": attributes,
            "uri" : uri?.absoluteString ?? ""
        
        ]

        return dict
    }
}
