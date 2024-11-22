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
    
    // MARK: - Initializer
    
    /// Creates a new instance of `ModelQuery`.
    ///
    /// - Parameters:
    ///   - query: An optional search query string.
    ///   - pageNumber: The current page number for paginated results (default is `0`).
    ///   - pageSize: The number of results per page (default is `40`).
    ///   - functions: A list of specific functions to be executed by the model.
    public init(query: String? = nil, pageNumber: Int = 0, pageSize: Int = 40, functions: [String]) {
        self.query = query
        self.pageNumber = pageNumber
        self.pageSize = pageSize
        self.functions = functions
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
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            throw PipelineError.inputEncodingError // Ensure proper error is implemented
        }
        
        return jsonData
    }
}
