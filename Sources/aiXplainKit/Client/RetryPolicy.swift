import Foundation

/// Retry configuration matching Python v2 `create_retry_session()` defaults.
public struct RetryPolicy: Sendable {
    public var maxRetries: Int
    public var backoffFactor: Double
    public var retryableStatusCodes: Set<Int>

    public init(maxRetries: Int = 5, backoffFactor: Double = 0.1, retryableStatusCodes: Set<Int> = [500, 502, 503, 504]) {
        self.maxRetries = maxRetries
        self.backoffFactor = backoffFactor
        self.retryableStatusCodes = retryableStatusCodes
    }

    public static let `default` = RetryPolicy()

    /// Delay for a given attempt (exponential backoff).
    func delay(for attempt: Int) -> TimeInterval {
        backoffFactor * pow(2.0, Double(attempt))
    }
}
