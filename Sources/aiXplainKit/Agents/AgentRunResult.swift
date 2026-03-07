import Foundation

/// Result from running an agent.
///
/// Mirrors Python v2 `AgentRunResult(Result)` from `agent.py`.
public struct AgentRunResult: @unchecked Sendable {
    public let status: String
    public let completed: Bool
    public let data: AgentResponseData?
    public let sessionId: String?
    public let requestId: String?
    public let usedCredits: Double
    public let runTime: Double
    public let errorMessage: String?
    public let supplierError: String?
    public let url: String?
    public let rawData: [String: Any]?

    /// Parse from a polling/run response dictionary.
    public static func from(_ dict: [String: Any]) -> AgentRunResult {
        var responseData: AgentResponseData? = nil
        if let dataDict = dict["data"] as? [String: Any] {
            responseData = AgentResponseData(
                input: dataDict["input"] as? String,
                output: dataDict["output"] as? String,
                steps: dataDict["steps"] as? [[String: Any]],
                sessionId: dataDict["sessionId"] as? String ?? dataDict["session_id"] as? String
            )
        } else if let dataStr = dict["data"] as? String, !dataStr.hasPrefix("http") {
            responseData = AgentResponseData(output: dataStr)
        }

        return AgentRunResult(
            status: dict["status"] as? String ?? "IN_PROGRESS",
            completed: dict["completed"] as? Bool ?? false,
            data: responseData,
            sessionId: dict["sessionId"] as? String,
            requestId: dict["requestId"] as? String,
            usedCredits: dict["usedCredits"] as? Double ?? 0,
            runTime: dict["runTime"] as? Double ?? 0,
            errorMessage: dict["errorMessage"] as? String,
            supplierError: dict["supplierError"] as? String,
            url: dict["url"] as? String ?? (dict["data"] as? String),
            rawData: dict
        )
    }
}

/// Data structure for agent response content.
public struct AgentResponseData: @unchecked Sendable {
    public let input: String?
    public let output: String?
    public let steps: [[String: Any]]?
    public let sessionId: String?

    public init(input: String? = nil, output: String? = nil, steps: [[String: Any]]? = nil, sessionId: String? = nil) {
        self.input = input
        self.output = output
        self.steps = steps
        self.sessionId = sessionId
    }
}
