import Foundation

/// HTTP/API-level error with full context.
///
/// Mirrors Python v2 `APIError`: carries status code, response body, and request ID.
public struct APIError: Error, Sendable, LocalizedError, CustomStringConvertible {
    public let message: String
    public let statusCode: Int
    public let error: String?
    public let requestId: String?
    private let _responseData: ResponseData?

    /// Thread-safe wrapper for the response dictionary.
    struct ResponseData: @unchecked Sendable {
        let value: [String: Any]
    }

    public var responseData: [String: Any]? { _responseData?.value }

    public init(
        message: String,
        statusCode: Int = 0,
        responseData: [String: Any]? = nil,
        error: String? = nil,
        requestId: String? = nil
    ) {
        self.message = message
        self.statusCode = statusCode
        self._responseData = responseData.map { ResponseData(value: $0) }
        self.error = error ?? message
        self.requestId = requestId
    }

    public var userMessage: String {
        if let err = error, !err.isEmpty { return err }
        return message
    }

    public var errorDescription: String? { message }

    public var description: String {
        var parts = ["APIError(\(statusCode)): \(message)"]
        if let rid = requestId { parts.append("requestId=\(rid)") }
        return parts.joined(separator: ", ")
    }

    // MARK: - Factories

    /// Build from a polling response with status == "FAILED".
    /// Mirrors Python v2 `create_operation_failed_error(response)`.
    public static func fromFailedOperation(_ response: [String: Any]) -> AixplainError {
        let errorMsg = (response["supplierError"] as? String)
            ?? (response["supplier_error"] as? String)
            ?? (response["error_message"] as? String)
            ?? (response["error"] as? String)
            ?? "Operation failed"

        return .api(APIError(
            message: "Operation failed: \(errorMsg)",
            statusCode: response["statusCode"] as? Int ?? 0,
            responseData: response,
            error: errorMsg,
            requestId: response["requestId"] as? String
        ))
    }

    /// Build from a non-2xx HTTP response.
    /// Mirrors Python v2 `client.py` error handling in `request_raw()`.
    public static func fromHTTPResponse(data: Data, statusCode: Int) -> AixplainError {
        if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return .api(APIError(
                message: errorObj["message"] as? String
                    ?? errorObj["error"] as? String
                    ?? "Request failed with status \(statusCode)",
                statusCode: errorObj["statusCode"] as? Int ?? statusCode,
                responseData: errorObj,
                error: errorObj["error"] as? String,
                requestId: errorObj["requestId"] as? String
            ))
        }
        return .api(APIError(
            message: String(data: data, encoding: .utf8) ?? "Request failed with status \(statusCode)",
            statusCode: statusCode
        ))
    }
}
