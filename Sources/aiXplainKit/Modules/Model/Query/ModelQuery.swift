//
//  File.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 22/05/24.
//

import Foundation

/// Represents a query to be sent to a model.
///
/// The `ModelQuery` struct is used to encapsulate the parameters needed for querying a model, including optional filters,
/// pagination settings, and specific functions to execute. It also includes utilities for building the query
/// as a JSON payload.
public struct ModelQuery {
    // MARK: - Properties
    
    /// The search query string.
    var query: String?
    
    /// The current page number for paginated results (default is `0`).
    var pageNumber: Int = 0
    
    /// The number of results per page (default is `40`).
    var pageSize: Int = 40
    
    /// A list of specific functions to be executed by the model.
    var functions: [String]
    
    var sortBy:SortByParameter? = nil
    
    var sortOrder:SortOrderParameter? = nil
    
    // Initializes a new instance of `ModelQuery` with the specified parameters.
    ///
    /// Use this initializer to configure a query with optional search filters, pagination settings,
    /// sorting preferences, and a list of functions to execute.
    ///
    /// - Parameters:
    ///   - query: An optional search query string. Defaults to `nil`.
    ///   - pageNumber: The current page number for paginated results. Defaults to `0`.
    ///   - pageSize: The number of results per page. Defaults to `40`.
    ///   - functions: A list of specific functions to be executed by the model.
    ///   - sortBy: An optional sorting parameter that specifies the attribute by which results are sorted. Defaults to `nil`.
    ///   - sortOrder: An optional sorting order (e.g., ascending or descending). Defaults to `nil`.
    ///
    /// # Example
    /// ```swift
    /// let query = ModelQuery(
    ///     query: "example",
    ///     pageNumber: 1,
    ///     pageSize: 20,
    ///     functions: ["function1", "function2"],
    ///     sortBy: .creationDate,
    ///     sortOrder: .ascending
    /// )
    /// ```
    ///
    /// This creates a query configured to search for the term "example," request results
    /// from page 1 with 20 items per page, and sort by creation date in ascending order.
    public init(query: String? = nil, pageNumber: Int = 0, pageSize: Int = 40, functions: [String], sortBy: ModelQuery.SortByParameter? = nil, sortOrder: ModelQuery.SortOrderParameter? = nil) {
        self.query = query
        self.pageNumber = pageNumber
        self.pageSize = pageSize
        self.functions = functions
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }

    
    // MARK: - Methods
    
    /// Builds the query as a JSON payload.
    ///
    /// This method constructs a JSON object with the query parameters, including pagination settings,
    /// the search query, and the list of functions. It then serializes the object into `Data`.
    ///
    /// - Returns: A `Data` object representing the JSON payload of the query.
    /// - Throws:
    ///   - `PipelineError.inputEncodingError` if the JSON serialization fails.
    ///
    /// # Example
    /// ```swift
    /// let query = ModelQuery(query: "example", pageNumber: 1, pageSize: 20, functions: ["function1", "function2"])
    /// do {
    ///     let jsonData = try query.buildQuery()
    ///     print(String(data: jsonData, encoding: .utf8)!) // JSON representation of the query
    /// } catch {
    ///     print("Failed to build query: \(error)")
    /// }
    /// ```
    public func buildQuery() throws -> Data {
        var body: [String: Decodable] = ["pageNumber": pageNumber, "pageSize": pageSize]
        
        if !functions.isEmpty {
            body["functions"] = functions
        }
        
        if let q = query {
            body["q"] = q
        }
        
        if let sortBy {
            body["sortBy"] = sortBy.rawValue
        }
        
        if let sortOrder {
            body["sortOrder"] = sortOrder.rawValue
        }
        
        
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            throw PipelineError.inputEncodingError // Ensure proper error is implemented
        }
        
        return jsonData
    }
}


//MARK: Query parameters
extension ModelQuery{
    public enum SortByParameter:String{
        case creationDate = "createdAt"
        case price = "normalizedPrice"
        case popularity = "totalSubscribed"
    }
    
    public enum SortOrderParameter:String{
        case ascending = "asc"
        case descending = "desc"
    }
}
