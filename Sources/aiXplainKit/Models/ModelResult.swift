import Foundation

/// Result from running a model. Extends `RunResult` with model-specific fields.
///
/// Mirrors Python v2 `ModelResult(Result)` from `model.py`.
public struct ModelResult: @unchecked Sendable {
    public let status: String
    public let completed: Bool
    public let data: AnyCodable?
    public let url: String?
    public let errorMessage: String?
    public let supplierError: String?
    public let runTime: Double?
    public let usedCredits: Double?
    public let usage: TokenUsage?
    public let sessionId: String?
    public let requestId: String?
    public let rawData: [String: Any]?

    public init(
        status: String,
        completed: Bool,
        data: AnyCodable? = nil,
        url: String? = nil,
        errorMessage: String? = nil,
        supplierError: String? = nil,
        runTime: Double? = nil,
        usedCredits: Double? = nil,
        usage: TokenUsage? = nil,
        sessionId: String? = nil,
        requestId: String? = nil,
        rawData: [String: Any]? = nil
    ) {
        self.status = status
        self.completed = completed
        self.data = data
        self.url = url
        self.errorMessage = errorMessage
        self.supplierError = supplierError
        self.runTime = runTime
        self.usedCredits = usedCredits
        self.usage = usage
        self.sessionId = sessionId
        self.requestId = requestId
        self.rawData = rawData
    }

    /// Parse from a polling/run response dictionary.
    public static func from(_ dict: [String: Any]) -> ModelResult {
        var usage: TokenUsage? = nil
        if let usageDict = dict["usage"] as? [String: Any],
           let pt = usageDict["prompt_tokens"] as? Int,
           let ct = usageDict["completion_tokens"] as? Int,
           let tt = usageDict["total_tokens"] as? Int {
            usage = TokenUsage(promptTokens: pt, completionTokens: ct, totalTokens: tt)
        }

        return ModelResult(
            status: dict["status"] as? String ?? "IN_PROGRESS",
            completed: dict["completed"] as? Bool ?? false,
            data: (dict["data"]).map { AnyCodable($0) },
            url: dict["url"] as? String,
            errorMessage: dict["errorMessage"] as? String,
            supplierError: dict["supplierError"] as? String,
            runTime: dict["runTime"] as? Double,
            usedCredits: dict["usedCredits"] as? Double,
            usage: usage,
            sessionId: dict["sessionId"] as? String,
            requestId: dict["requestId"] as? String,
            rawData: dict
        )
    }
}
