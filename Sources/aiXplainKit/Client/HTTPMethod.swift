import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"

    /// Python v2 only retries GET and POST.
    var isRetryable: Bool {
        self == .get || self == .post
    }
}
