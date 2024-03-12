//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation

enum NetworkingError: Error {
    /// An invalid status code was received from the network request.
    case invalidStatusCode(statusCode: Int)

    /// The provided URL is malformed.
    case invalidURL(url: String?)

    var localizedDescription: String {
        switch self {
        case .invalidStatusCode(let statusCode):
            return "Invalid status code received: \(statusCode)"
        case .invalidURL(url: let url):
            guard let url = url else { return "Invalid URL." }
            return "The provided URL is malformed: \(url)"
        }
    }
}
