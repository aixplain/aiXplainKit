import Foundation

/// Transport settings for the aiXplain client.
///
/// Default URLs match Python v2 `Aixplain` class attributes in `core.py`.
public struct ClientConfiguration: Sendable {
    public var backendURL: URL
    public var modelsRunURL: URL
    public var timeoutInterval: TimeInterval
    public var retryPolicy: RetryPolicy
    public var userAgent: String

    public init(
        backendURL: URL = URL(string: "https://platform-api.aixplain.com")!,
        modelsRunURL: URL = URL(string: "https://models.aixplain.com/api/v2/execute")!,
        timeoutInterval: TimeInterval = 30,
        retryPolicy: RetryPolicy = .default,
        userAgent: String = "aiXplainKit-Swift/2.0"
    ) {
        self.backendURL = backendURL
        self.modelsRunURL = modelsRunURL
        self.timeoutInterval = timeoutInterval
        self.retryPolicy = retryPolicy
        self.userAgent = userAgent
    }

    public static let `default` = ClientConfiguration()
}
