import Foundation

/// Comparison operators for index field filters.
public enum FieldOperator: Sendable {
    case equals(String)
    case notEquals(String)
    case contains(String)
    case notContains(String)
    case greaterThan(String)
    case lessThan(String)
    case greaterThanOrEquals(String)
    case lessThanOrEquals(String)

    var value: String {
        switch self {
        case .equals(let v), .notEquals(let v), .contains(let v), .notContains(let v),
             .greaterThan(let v), .lessThan(let v), .greaterThanOrEquals(let v), .lessThanOrEquals(let v):
            return v
        }
    }

    var operatorString: String {
        switch self {
        case .equals: return "=="
        case .notEquals: return "!="
        case .contains: return "in"
        case .notContains: return "not in"
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .greaterThanOrEquals: return ">="
        case .lessThanOrEquals: return "<="
        }
    }
}

/// A filter for constraining index search queries.
///
/// Adapted from v1 with builder pattern support.
public struct IndexFilter: Sendable {
    public let fieldName: String
    public let operation: FieldOperator

    public init(fieldName: String, operation: FieldOperator) {
        self.fieldName = fieldName
        self.operation = operation
    }

    /// Subscript shorthand: `IndexFilter["author", .equals("Woolf")]`
    public static subscript(fieldName: String, operation: FieldOperator) -> IndexFilter {
        IndexFilter(fieldName: fieldName, operation: operation)
    }

    public func toDict() -> [String: String] {
        ["field": fieldName, "value": operation.value, "operator": operation.operatorString]
    }

    public static func builder() -> IndexFilterBuilder { IndexFilterBuilder() }
}

/// Builder for chaining index filters.
public class IndexFilterBuilder {
    private var filters: [IndexFilter] = []

    @discardableResult
    public func `where`(_ field: String, _ op: FieldOperator) -> IndexFilterBuilder {
        filters.append(IndexFilter(fieldName: field, operation: op))
        return self
    }

    public func build() -> [IndexFilter] { filters }
}
