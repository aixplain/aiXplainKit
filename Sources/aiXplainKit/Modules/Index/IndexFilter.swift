//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 13/05/25.
//

import Foundation

/// A filter used to constrain index search queries.
///
/// `IndexFilter` represents a predicate that is evaluated against a document's
/// metadata field when executing an search.
/// Each filter is composed of the field name that should be inspected and an
/// [`IndexFieldOperator`](#) that describes the comparison that must hold true
/// for a document to be returned in the search results.
///
/// You create an instance by passing a metadata field name and an operator:
///
/// ```swift
/// let filter = IndexFilter(fieldName: "sourceLanguage", operation: .equals(value: "en"))
/// ```
///
/// — or, more concisely, using the subscript shortcut:
///
/// ```swift
/// let filter = IndexFilter["sourceLanguage", .equals(value: "en")]
/// ```
///
/// Pass the resulting filter to `IndexModel.search(_:top_k:filters:)` to limit
/// the pool of candidate records.
public struct IndexFilter{
    let fieldName: String
    let operation: IndexFieldOperator
    
    /// Creates an `IndexFilter` using a subscript-style shorthand.
    ///
    /// This convenience allows for a terser syntax when building filter
    /// collections:
    ///
    /// ```swift
    /// let filters: [IndexFilter] = [
    ///     IndexFilter["author", .equals(value: "Virginia Woolf")],
    ///     IndexFilter["year",   .greaterThan(value: "1920")]
    /// ]
    /// ```
    ///
    /// - Parameters:
    ///   - fieldName: The name of the metadata field to query.
    ///   - operation: The comparison operation to apply.
    static subscript (fieldName: String,operation:IndexFieldOperator) -> IndexFilter {
        return IndexFilter(fieldName: fieldName, operation: operation)
    }
    
    /// Converts the filter into a dictionary expected by the backend API.
    ///
    /// - Returns: A `[String : String]` representation suitable for JSON
    ///   serialization.
    public func toDict()->[String:String]{
        return [
            "field" : fieldName,
            "value": operation.value,
            "operator": operation.toString
        ]
    }
    
}

/// The comparison operations that can be applied to an index field.
///
/// Each case embeds the **value** that will be compared against the field
/// contents. For instance, `.greaterThan(value: "10")` translates to the
/// predicate *field > "10"*.
public enum IndexFieldOperator {
    case equals(value:String)
    case notEquals(value:String)
    case contains(value:String)
    case notContains(value:String)
    case greaterThan(value:String)
    case lessThan(value:String)
    case greaterThanOrEquals(value:String)
    case lessThanOrEquals(value:String)
    
    /// The value component of the comparison operation.
    ///
    /// For example, in the case `.equals(value: "en")`, the `value` returned
    /// is `"en"`.
    var value:String{
        switch self {
        case .equals(value: let v):
            return v
        case .notEquals(value: let v):
            return v
        case .contains(value: let v):
            return v
        case .notContains(value: let v):
            return v
        case .greaterThan(value: let v):
            return v
        case .lessThan(value: let v):
            return v
        case .greaterThanOrEquals(value: let v):
            return v
        case .lessThanOrEquals(value: let v):
            return v
        }
    }
    
    /// Returns the string representation expected by the backend for the
    /// operator.
    ///
    /// For instance, `.greaterThan` becomes `">"`.
    var toString:String{
        switch self {
        case .equals:
            return "=="
        case .notEquals:
            return "!="
        case .contains:
            return "in"
        case .notContains:
            return "not in"
        case .greaterThan:
            return  ">"
        case .lessThan:
            return "<"
        case .greaterThanOrEquals:
            return ">="
        case .lessThanOrEquals:
            return "<="
        }
    }
    
    
}
