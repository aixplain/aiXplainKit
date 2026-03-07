import Foundation

/// Unified response from the aiXplain client.
public struct Response: @unchecked Sendable {
    public let data: Data
    public let httpResponse: HTTPURLResponse

    public var statusCode: Int { httpResponse.statusCode }
    public var isSuccess: Bool { (200..<300).contains(statusCode) }

    public func decode<T: Decodable>(_ type: T.Type, using decoder: JSONDecoder = .init()) throws -> T {
        try decoder.decode(type, from: data)
    }

    public func json() throws -> [String: Any] {
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AixplainError.validation(ValidationError("Response body is not a JSON object"))
        }
        return dict
    }
}
