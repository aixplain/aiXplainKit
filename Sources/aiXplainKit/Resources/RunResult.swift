import Foundation

/// Base result for all run/poll operations.
///
/// Mirrors Python v2 `Result` dataclass from `resource.py`.
/// Subclassed or extended by `AgentRunResult`, `ModelResult`, etc.
public struct RunResult: Sendable {
    public let status: String
    public let completed: Bool
    public let errorMessage: String?
    public let url: String?
    public let supplierError: String?
    public let data: AnyCodable?
    public let rawData: [String: Any]?

    public init(
        status: String,
        completed: Bool,
        errorMessage: String? = nil,
        url: String? = nil,
        supplierError: String? = nil,
        data: AnyCodable? = nil,
        rawData: [String: Any]? = nil
    ) {
        self.status = status
        self.completed = completed
        self.errorMessage = errorMessage
        self.url = url
        self.supplierError = supplierError
        self.data = data
        self.rawData = rawData
    }

    /// Parse from a polling response dictionary.
    public static func from(_ dict: [String: Any]) -> RunResult {
        RunResult(
            status: dict["status"] as? String ?? "IN_PROGRESS",
            completed: dict["completed"] as? Bool ?? false,
            errorMessage: dict["errorMessage"] as? String,
            url: dict["url"] as? String,
            supplierError: dict["supplierError"] as? String,
            data: (dict["data"]).map { AnyCodable($0) },
            rawData: dict
        )
    }
}
