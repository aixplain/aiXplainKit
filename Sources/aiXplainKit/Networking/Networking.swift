//
//  Networking.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation

/// A class responsible for making network requests.
public class Networking {

    /// Fetches data from the specified URL using the GET method.
    /// - Parameters:
    ///   - url: The URL of the resource to fetch data from.
    ///   - headers: Optional dictionary of headers to include in the request (default: empty).
    /// - Throws: Any error that may occur during the network request.
    /// - Returns: A tuple containing the retrieved data and the URL response.
    public func get(url: URL, headers: [String: String] = [:]) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10

        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }

        // TODO: Add a logging function here to print the url request

        return try await URLSession.shared.data(for: request)
    }

    /// Posts data to the specified URL using the POST method.
    ///
    /// - Parameters:
    ///   - url: The URL of the resource to post data to.
    ///   - headers: Optional dictionary of headers to include in the request (default: empty).
    ///   - body: Optional data to send in the request body (default: nil).
    ///
    /// - Throws: Any error that may occur during the network request.
    /// - Returns: A tuple containing the retrieved data and the URL response.
    public func post(url: URL, headers: [String: String] = [:], body: Data? = nil) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10

        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }

        if let body = body {
            request.httpBody = body
        }

        // TODO: Add a logging function here to print the url request
        return try await URLSession.shared.data(for: request)
    }

}
