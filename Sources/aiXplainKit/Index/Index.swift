import Foundation
import OSLog

/// Index resource -- standalone type wrapping a Model (resolved question: not a subclass).
///
/// Provides search (text/image), upsert, getDocument, and count operations.
/// An index is backed by a model with `function == "search"`.
public final class Index: @unchecked Sendable {
    private static let logger = Logger(subsystem: "aiXplainKit", category: "Index")

    public var id: String?
    public var name: String?
    public var description: String?
    public var context: Aixplain?

    public init(id: String? = nil, name: String? = nil, description: String? = nil, context: Aixplain? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.context = context
    }

    // MARK: - Get

    public static func get(_ id: String, context: Aixplain) async throws -> Index {
        let model = try await Model.get(id, context: context)
        return Index(id: model.id, name: model.name, description: model.description, context: context)
    }

    // MARK: - Create

    /// Create a new index using an engine model and embedding model.
    /// Mirrors v1 `IndexProvider.create()` flow.
    public static func create(
        name: String,
        description: String,
        embedding: EmbeddingModel = .openaiAda002,
        engine: IndexEngine = .air,
        context: Aixplain
    ) async throws -> Index {
        let engineModel = try await Model.get(engine.id, context: context)

        let payload: [String: Any] = [
            "data": name,
            "description": description,
            "model": embedding.modelId
        ]
        let result = try await engineModel.run(parameters: payload)

        guard let output = result.data?.value as? String, !output.isEmpty else {
            throw AixplainError.resource(ResourceError("Failed to create index: no model ID returned"))
        }

        return try await Index.get(output, context: context)
    }

    // MARK: - Search (text)

    public func search(_ query: String, topK: Int = 10, filters: [IndexFilter] = []) async throws -> IndexSearchResult {
        let payload: [String: Any] = [
            "action": "search",
            "data": query,
            "data_type": "text",
            "filters": filters.map { $0.toDict() },
            "payload": [
                "uri": "",
                "top_k": topK,
                "value_type": "text"
            ]
        ]
        return try await runIndexOperation(payload)
    }

    // MARK: - Search (image)

    public func search(imageURL: URL, topK: Int = 10, filters: [IndexFilter] = []) async throws -> IndexSearchResult {
        let payload: [String: Any] = [
            "action": "search",
            "data": "",
            "data_type": "image",
            "filters": filters.map { $0.toDict() },
            "payload": [
                "uri": imageURL.absoluteString,
                "top_k": topK,
                "value_type": "image"
            ]
        ]
        return try await runIndexOperation(payload)
    }

    // MARK: - Upsert

    @discardableResult
    public func upsert(_ records: [Record]) async throws -> Bool {
        let recordDicts = records.map { $0.toDictionary() }
        let payload: [String: Any] = ["action": "ingest", "data": recordDicts]
        let result = try await executeModel(payload)
        let output = result["data"] as? String ?? ""
        return output.lowercased().contains("success")
    }

    // MARK: - Get Document

    public func getDocument(_ documentId: String) async throws -> Record? {
        let payload: [String: Any] = ["action": "get_document", "data": documentId]
        let result = try await executeModel(payload)
        guard let output = result["data"] as? String, !output.isEmpty else { return nil }
        return Record(text: output, id: documentId)
    }

    // MARK: - Count

    public func count() async throws -> Int {
        let payload: [String: Any] = ["action": "count", "data": ""]
        let result = try await executeModel(payload)
        if let output = result["data"] as? String { return Int(output) ?? -1 }
        if let output = result["data"] as? Int { return output }
        return -1
    }

    // MARK: - Subscript

    public subscript(documentId: String) -> Record? {
        get async throws {
            try await getDocument(documentId)
        }
    }

    // MARK: - Private

    private func runIndexOperation(_ payload: [String: Any]) async throws -> IndexSearchResult {
        let result = try await executeAndPoll(payload)
        return IndexSearchResult.from(result)
    }

    private func executeModel(_ payload: [String: Any]) async throws -> [String: Any] {
        try await executeAndPoll(payload)
    }

    private func executeAndPoll(_ payload: [String: Any]) async throws -> [String: Any] {
        guard let id else {
            throw AixplainError.validation(ValidationError("Index has not been saved yet."))
        }
        guard let ctx = context else {
            throw AixplainError.resource(ResourceError("Context is required for index operations."))
        }

        let runURL = "\(ctx.modelURL.absoluteString)/\(id)"
        let body = try JSONSerialization.data(withJSONObject: payload)
        let response = try await ctx.client.requestRaw(method: .post, path: runURL, body: body)
        let responseDict = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] ?? [:]

        let status = responseDict["status"] as? String ?? "IN_PROGRESS"
        if status == ResponseStatus.failed.rawValue {
            throw APIError.fromFailedOperation(responseDict)
        }

        if responseDict["completed"] as? Bool == true {
            return responseDict
        }

        guard let pollURL = responseDict["data"] as? String, pollURL.hasPrefix("http") else {
            if let pollingURL = responseDict["url"] as? String {
                return try await pollIndex(pollingURL, context: ctx)
            }
            return responseDict
        }

        return try await pollIndex(pollURL, context: ctx)
    }

    private func pollIndex(_ pollURL: String, context ctx: Aixplain, timeout: TimeInterval = 300) async throws -> [String: Any] {
        let startTime = Date()
        var waitTime = 0.5

        while Date().timeIntervalSince(startTime) < timeout {
            let response = try await ctx.client.get(pollURL)
            let status = response["status"] as? String ?? "IN_PROGRESS"

            if status == ResponseStatus.failed.rawValue {
                throw APIError.fromFailedOperation(response)
            }
            if response["completed"] as? Bool == true {
                return response
            }

            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            waitTime = min(waitTime * 1.1, 60)
        }

        throw AixplainError.timeout(TimeoutError("Index operation timed out", pollingURL: pollURL, timeout: timeout))
    }
}
