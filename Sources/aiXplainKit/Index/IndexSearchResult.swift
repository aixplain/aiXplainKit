import Foundation

/// Search result from an index query.
public struct IndexSearchResult: @unchecked Sendable {
    public let hits: [SearchHit]
    public let rawData: [String: Any]?

    public init(hits: [SearchHit], rawData: [String: Any]? = nil) {
        self.hits = hits
        self.rawData = rawData
    }

    /// Parse from API response.
    public static func from(_ dict: [String: Any]) -> IndexSearchResult {
        var hits: [SearchHit] = []
        if let dataDict = dict["data"] as? [String: Any],
           let results = dataDict["results"] as? [[String: Any]] ?? dataDict["documents"] as? [[String: Any]] {
            hits = results.compactMap { SearchHit.from($0) }
        } else if let dataStr = dict["data"] as? String,
                  let jsonData = dataStr.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let results = parsed["results"] as? [[String: Any]] ?? parsed["documents"] as? [[String: Any]] {
            hits = results.compactMap { SearchHit.from($0) }
        }
        return IndexSearchResult(hits: hits, rawData: dict)
    }
}

/// A single search hit from an index query.
public struct SearchHit: Sendable {
    public let documentId: String
    public let score: Double
    public let data: String
    public let attributes: [String: String]

    public init(documentId: String, score: Double = 0, data: String = "", attributes: [String: String] = [:]) {
        self.documentId = documentId
        self.score = score
        self.data = data
        self.attributes = attributes
    }

    public static func from(_ dict: [String: Any]) -> SearchHit? {
        guard let docId = dict["document_id"] as? String ?? dict["documentId"] as? String else { return nil }
        return SearchHit(
            documentId: docId,
            score: dict["score"] as? Double ?? 0,
            data: dict["data"] as? String ?? "",
            attributes: dict["attributes"] as? [String: String] ?? [:]
        )
    }
}
