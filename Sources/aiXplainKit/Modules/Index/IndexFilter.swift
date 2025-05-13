//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 13/05/25.
//

import Foundation

//TODO: DOCS, this is a index field, this is used for queries in indexes
public struct IndexFilter{
    let fieldName: String
    let operation: IndexFieldOperator
    
    static subscript (fieldName: String,operation:IndexFieldOperator) -> IndexFilter {
        return IndexFilter(fieldName: fieldName, operation: operation)
    }
    
    
    public func toDict()->[String:String]{
        return [
            "field" : fieldName,
            "value": operation.value,
            "operator": operation.toString
        ]
    }
    
}

public enum IndexFieldOperator {
    case equals(value:String)
    case notEquals(value:String)
    case contains(value:String)
    case notContains(value:String)
    case greaterThan(value:String)
    case lessThan(value:String)
    case greaterThanOrEquals(value:String)
    case lessThanOrEquals(value:String)
    
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
