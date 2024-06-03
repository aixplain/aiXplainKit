//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 22/05/24.
//

import Foundation

//TODO: Add docs, this represents a query for a model
public struct ModelQuery{
    var query:String?
    var pageNumber:Int = 0
    var pageSize:Int = 40
    var functions:[String]
    
    public init(query: String? = nil, pageNumber: Int = 0, pageSize: Int = 40, functions: [String]) {
        self.query = query
        self.pageNumber = pageNumber
        self.pageSize = pageSize
        self.functions = functions
    }
    
    
    
    
    public func buildQuery() throws ->Data{
        var body:[String:Decodable] = ["pageNumber": pageNumber, "pageSize": pageSize]
        
        if !functions.isEmpty{
            body["functions"] = functions
        }
        
        if let q = query{
            body["q"] = q
        }
        
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            throw PipelineError.inputEncodingError //TODO: Implement proper error
        }
        
        return jsonData
    }
    
    
}
