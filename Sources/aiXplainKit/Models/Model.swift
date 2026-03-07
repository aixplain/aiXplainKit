import Foundation
import OSLog

/// AI Model resource.
///
/// Mirrors Python v2 `Model(BaseResource, SearchResourceMixin, GetResourceMixin,
/// RunnableResourceMixin, ToolableMixin)` from `model.py`.
public class Model: BaseResource, AgentToolConvertible {
    private static let logger = Logger(subsystem: "aiXplainKit", category: "Model")
    public override class var resourcePath: String { "v2/models" }

    // MARK: - Model-specific fields

    public var serviceName: String?
    public var status: AssetStatus?
    public var host: String?
    public var developer: String?
    public var vendor: VendorInfo?
    public var function: AIFunction?
    public var pricing: ModelPricing?
    public var version: ModelVersion?
    public var functionType: String?
    public var type: String? = "model"
    public var supportsStreaming: Bool?
    public var connectionType: [String]?
    public var createdAt: String?
    public var updatedAt: String?

    public var isSyncOnly: Bool {
        guard let ct = connectionType else { return false }
        return ct.contains("synchronous") && !ct.contains("asynchronous")
    }

    public var isAsyncCapable: Bool {
        guard let ct = connectionType else { return true }
        return ct.contains("asynchronous")
    }

    // MARK: - Init

    public required init(id: String? = nil, name: String? = nil, description: String? = nil, context: Aixplain? = nil) {
        super.init(id: id, name: name, description: description, context: context)
    }

    public required convenience init() {
        self.init(id: nil, name: nil, description: nil, context: nil)
    }

    // MARK: - Get

    public class func get(_ id: String, context: Aixplain) async throws -> Model {
        try await performGet(id, context: context, type: Model.self)
    }

    // MARK: - Search

    public class func search(
        query: String? = nil,
        pageNumber: Int = 0,
        pageSize: Int = 20,
        context: Aixplain
    ) async throws -> Page<Model> {
        var filters: [String: Any] = [
            "pageNumber": pageNumber,
            "pageSize": pageSize,
            "sort": [[:] as [String: Any]]
        ]
        if let q = query {
            filters["q"] = q
        }
        return try await performSearch(filters: filters, context: context, type: Model.self)
    }

    // MARK: - Run

    /// Build the run URL. Uses `context.modelURL` + model ID (matches Python v2).
    public func buildRunURL() throws -> String {
        try ensureValidState()
        let ctx = try ensureContext()
        return "\(ctx.modelURL.absoluteString)/\(id!)"
    }

    /// Build the run payload.
    open func buildRunPayload(text: String? = nil, data: Any? = nil, parameters: [String: Any] = [:]) throws -> [String: Any] {
        var payload: [String: Any] = parameters
        if let text {
            payload["text"] = text
        }
        if let data {
            payload["data"] = data
        }
        return payload
    }

    /// Run the model synchronously (async+poll or sync direct depending on `connectionType`).
    public func run(text: String? = nil, data: Any? = nil, parameters: [String: Any] = [:]) async throws -> ModelResult {
        let payload = try buildRunPayload(text: text, data: data, parameters: parameters)
        let runURL = try buildRunURL()
        let ctx = try ensureContext()

        let response = try await ctx.client.post(runURL, json: payload)

        let status = response["status"] as? String ?? "IN_PROGRESS"
        let completed = response["completed"] as? Bool ?? false

        if status == ResponseStatus.failed.rawValue {
            throw APIError.fromFailedOperation(response)
        }

        if completed {
            return ModelResult.from(response)
        }

        if let pollURL = response["data"] as? String, pollURL.hasPrefix("http") {
            return try await pollModel(pollURL)
        }
        if let pollURL = response["url"] as? String {
            return try await pollModel(pollURL)
        }

        return ModelResult.from(response)
    }

    /// Run asynchronously -- returns immediately with polling URL.
    public func runAsync(text: String? = nil, data: Any? = nil, parameters: [String: Any] = [:]) async throws -> ModelResult {
        let payload = try buildRunPayload(text: text, data: data, parameters: parameters)
        let runURL = try buildRunURL()
        let ctx = try ensureContext()

        let response = try await ctx.client.post(runURL, json: payload)
        return ModelResult.from(response)
    }

    /// Stream model responses as SSE chunks.
    public func runStream(text: String? = nil, parameters: [String: Any] = [:]) -> AsyncThrowingStream<StreamChunk, Error> {
        AsyncThrowingStream { [self] continuation in
            Task {
                do {
                    let payload = try self.buildRunPayload(text: text, parameters: parameters)
                    var payloadWithStream = payload
                    if payloadWithStream["options"] == nil {
                        payloadWithStream["options"] = [String: Any]()
                    }
                    if var options = payloadWithStream["options"] as? [String: Any] {
                        options["stream"] = true
                        payloadWithStream["options"] = options
                    }

                    let runURL = try self.buildRunURL()
                    let body = try JSONSerialization.data(withJSONObject: payloadWithStream)
                    let ctx = try self.ensureContext()

                    let stream = ctx.client.requestStream(method: .post, path: runURL, body: body)
                    for try await lineData in stream {
                        guard let line = String(data: lineData, encoding: .utf8) else { continue }
                        let trimmed = line.hasPrefix("data:") ? String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces) : line
                        if trimmed == "[DONE]" { break }
                        if let jsonData = trimmed.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let content = json["data"] as? String {
                            if content == "[DONE]" { break }
                            continuation.yield(StreamChunk(status: .inProgress, data: content))
                        } else if !trimmed.isEmpty {
                            continuation.yield(StreamChunk(status: .inProgress, data: trimmed))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - AgentToolConvertible

    public func asAgentTool() -> AgentToolDict {
        AgentToolDict(
            id: id ?? "",
            name: name ?? "",
            description: description ?? "",
            supplier: vendor?.code ?? "aixplain",
            function: function?.rawValue ?? "",
            type: .model,
            version: version?.id ?? "",
            assetId: id ?? ""
        )
    }

    // MARK: - Deserialization

    public override class func from(dict: [String: Any], context: Aixplain) throws -> Self {
        let instance = Self.init(
            id: dict["id"] as? String,
            name: dict["name"] as? String,
            description: dict["description"] as? String,
            context: context
        )
        instance.serviceName = dict["serviceName"] as? String
        instance.host = dict["host"] as? String
        instance.developer = dict["developer"] as? String
        instance.functionType = dict["functionType"] as? String
        instance.type = dict["type"] as? String
        instance.supportsStreaming = dict["supportsStreaming"] as? Bool
        instance.connectionType = dict["connectionType"] as? [String]
        instance.createdAt = dict["createdAt"] as? String
        instance.updatedAt = dict["updatedAt"] as? String

        if let statusStr = dict["status"] as? String {
            instance.status = AssetStatus(rawValue: statusStr)
        }
        if let vendorDict = dict["vendor"] as? [String: Any] {
            instance.vendor = VendorInfo(
                id: (vendorDict["id"] as? Int).map(String.init) ?? vendorDict["id"] as? String,
                name: vendorDict["name"] as? String,
                code: vendorDict["code"] as? String
            )
        }
        if let funcDict = dict["function"] as? [String: Any], let funcId = funcDict["id"] as? String {
            instance.function = AIFunction(rawValue: funcId)
        }
        if let pricingDict = dict["pricing"] as? [String: Any] {
            instance.pricing = ModelPricing(
                price: pricingDict["price"] as? Double,
                unitType: pricingDict["unitType"] as? String,
                unitTypeScale: pricingDict["unitTypeScale"] as? String
            )
        }
        if let versionDict = dict["version"] as? [String: Any] {
            instance.version = ModelVersion(name: versionDict["name"] as? String, id: versionDict["id"] as? String)
        } else if let versionStr = dict["version"] as? String {
            instance.version = ModelVersion(name: versionStr, id: versionStr)
        }

        return instance
    }

    // MARK: - Polling

    private func pollModel(_ pollURL: String, timeout: TimeInterval = 300, waitTime: TimeInterval = 0.5) async throws -> ModelResult {
        let startTime = Date()
        var currentWait = max(waitTime, 0.2)
        let ctx = try ensureContext()

        while Date().timeIntervalSince(startTime) < timeout {
            let response = try await ctx.client.get(pollURL)
            let status = response["status"] as? String ?? "IN_PROGRESS"

            if status == ResponseStatus.failed.rawValue {
                throw APIError.fromFailedOperation(response)
            }

            if response["completed"] as? Bool == true {
                return ModelResult.from(response)
            }

            try await Task.sleep(nanoseconds: UInt64(currentWait * 1_000_000_000))
            currentWait = min(currentWait * 1.1, 60)
        }

        throw AixplainError.timeout(TimeoutError(
            "Model polling timed out after \(Int(timeout))s",
            pollingURL: pollURL,
            timeout: timeout
        ))
    }
}
