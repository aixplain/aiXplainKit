import Foundation
import OSLog

/// Central HTTP client for the aiXplain platform.
///
/// Mirrors Python v2 `AixplainClient`: single session, shared auth headers, retry logic.
/// Uses `URLSession` directly (resolved question: simplest approach).
public final class AixplainClient: @unchecked Sendable {
    public let credential: Credential
    public let configuration: ClientConfiguration

    private let session: URLSession
    private let logger = Logger(subsystem: "aiXplainKit", category: "Client")

    public init(credential: Credential, configuration: ClientConfiguration = .default) {
        self.credential = credential
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        self.session = URLSession(configuration: sessionConfig)
    }

    // MARK: - Public API

    /// Raw request returning `Response`. Mirrors Python v2 `request_raw()`.
    public func requestRaw(
        method: HTTPMethod,
        path: String,
        body: Data? = nil,
        additionalHeaders: [String: String] = [:]
    ) async throws -> Response {
        let url = try resolveURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        for (field, value) in credential.authHeaders() {
            request.setValue(value, forHTTPHeaderField: field)
        }
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        for (field, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let retryPolicy = configuration.retryPolicy
        var lastError: Error?

        for attempt in 0...retryPolicy.maxRetries {
            do {
                logger.debug("\(method.rawValue) \(url.absoluteString) (attempt \(attempt))")
                let (data, urlResponse) = try await session.data(for: request)

                guard let httpResponse = urlResponse as? HTTPURLResponse else {
                    throw AixplainError.api(APIError(message: "Invalid HTTP response"))
                }

                let response = Response(data: data, httpResponse: httpResponse)

                if response.isSuccess {
                    return response
                }

                if method.isRetryable && retryPolicy.retryableStatusCodes.contains(response.statusCode) && attempt < retryPolicy.maxRetries {
                    let delay = retryPolicy.delay(for: attempt)
                    logger.warning("Retryable status \(response.statusCode), waiting \(delay)s")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

                throw APIError.fromHTTPResponse(data: data, statusCode: response.statusCode)

            } catch let error as AixplainError {
                throw error
            } catch {
                lastError = error
                if method.isRetryable && attempt < retryPolicy.maxRetries {
                    let delay = retryPolicy.delay(for: attempt)
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
        }

        throw lastError ?? AixplainError.api(APIError(message: "Request failed after \(retryPolicy.maxRetries) retries"))
    }

    /// JSON-decoded request. Mirrors Python v2 `request()` which auto-calls `.json()`.
    public func request(
        method: HTTPMethod,
        path: String,
        body: Data? = nil,
        additionalHeaders: [String: String] = [:]
    ) async throws -> [String: Any] {
        let response = try await requestRaw(method: method, path: path, body: body, additionalHeaders: additionalHeaders)
        return try response.json()
    }

    /// GET request. Mirrors Python v2 `get()`.
    public func get(_ path: String) async throws -> [String: Any] {
        try await request(method: .get, path: path)
    }

    /// POST request with JSON body. Mirrors Python v2 `post()`.
    public func post(_ path: String, json payload: Any) async throws -> [String: Any] {
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await request(method: .post, path: path, body: body)
    }

    /// POST request with Encodable body.
    public func post<T: Encodable>(_ path: String, body: T) async throws -> [String: Any] {
        let data = try JSONEncoder().encode(body)
        return try await request(method: .post, path: path, body: data)
    }

    /// Streaming request for SSE. Mirrors Python v2 `request_stream()`.
    public func requestStream(
        method: HTTPMethod,
        path: String,
        body: Data? = nil
    ) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = try self.resolveURL(path)
                    var request = URLRequest(url: url)
                    request.httpMethod = method.rawValue
                    request.httpBody = body
                    for (field, value) in self.credential.authHeaders() {
                        request.setValue(value, forHTTPHeaderField: field)
                    }

                    let (bytes, urlResponse) = try await self.session.bytes(for: request)
                    guard let httpResponse = urlResponse as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: AixplainError.api(APIError(
                            message: "Stream request failed",
                            statusCode: (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
                        )))
                        return
                    }

                    for try await line in bytes.lines {
                        if line.isEmpty { continue }
                        if let data = line.data(using: .utf8) {
                            continuation.yield(data)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    /// Resolves URL: absolute paths pass through, relative paths join with backendURL.
    private func resolveURL(_ path: String) throws -> URL {
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            guard let url = URL(string: path) else {
                throw AixplainError.validation(ValidationError("Invalid URL: \(path)"))
            }
            return url
        }
        let base = configuration.backendURL.absoluteString.hasSuffix("/")
            ? configuration.backendURL.absoluteString
            : configuration.backendURL.absoluteString + "/"
        guard let url = URL(string: base + path) else {
            throw AixplainError.validation(ValidationError("Invalid URL: \(path)"))
        }
        return url
    }
}
