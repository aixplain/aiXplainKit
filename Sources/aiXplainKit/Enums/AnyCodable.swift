import Foundation

/// Type-erased `Codable` wrapper for heterogeneous JSON values.
///
/// Wraps `Any` (strings, numbers, bools, arrays, dictionaries, null) with
/// `Codable` conformance via `JSONSerialization`. Used across the SDK for
/// fields where the API returns dynamic JSON shapes.
public struct AnyCodable: @unchecked Sendable, Equatable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (let l as String, let r as String): return l == r
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as Bool, let r as Bool): return l == r
        case (is NSNull, is NSNull): return true
        default: return false
        }
    }
}

extension AnyCodable: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let v as Bool:
            try container.encode(v)
        case let v as Int:
            try container.encode(v)
        case let v as Double:
            try container.encode(v)
        case let v as String:
            try container.encode(v)
        case let v as [Any]:
            try container.encode(v.map { AnyCodable($0) })
        case let v as [String: Any]:
            try container.encode(v.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

extension AnyCodable: CustomStringConvertible {
    public var description: String {
        "\(value)"
    }
}
