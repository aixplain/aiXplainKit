//
//  MockNetworking.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 08/03/24.
//

import Foundation
@testable import aiXplainKit

final class MockNetworking: Networking {

    var urlPatterns: [NSRegularExpression: (Data, URLResponse)] = [:]

    override init() {
        super.init()

        addPattern("^https://platform-api\\.aixplain\\.com/sdk/models/.*$",
                   data: ModelProvider_get_MockResponse!,
                   response: HTTPURLResponse(url: URL(string: "https://platform-api.aixplain.com/sdk/models/example")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)

        addPattern("^https://models\\.aixplain\\.com/api/v1/execute/.*$",
                   data: model_CreateExecution_MockResponse!,
                   response: HTTPURLResponse(url: URL(string: "https://models.aixplain.com/api/v1/execute/")!, statusCode: 201, httpVersion: nil, headerFields: nil)!)

        addPattern("^https://models\\.aixplain\\.com/api/v1/data/8d548248-c4b8-4051-b036-ccb0417f9cf1$",
                   data: model_Polling_MockResponse!,
                   response: HTTPURLResponse(url: URL(string: "https://models.aixplain.com/api/v1/data/8d548248-c4b8-4051-b036-ccb0417f9cf1$")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)

    }

    public func addPattern(_ pattern: String, data: Data, response: URLResponse) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return
        }
        urlPatterns[regex] = (data, response)
    }

    override func get(url: URL, headers: [String: String]) async throws -> (Data, URLResponse) {
        if let matchingPattern = urlPatterns.first(where: { regex in
            !regex.key.matches(in: url.absoluteString, options: [], range: NSRange(url.absoluteString.startIndex..., in: url.absoluteString)).isEmpty
        }) {
            return matchingPattern.value
        }
        return (Data(), URLResponse())
    }

    override func post(url: URL, headers: [String: String], body: Data?) async throws -> (Data, URLResponse) {
        if let matchingPattern = urlPatterns.first(where: { regex in
            !regex.key.matches(in: url.absoluteString, options: [], range: NSRange(url.absoluteString.startIndex..., in: url.absoluteString)).isEmpty
        }) {
            return matchingPattern.value
        }
        return (Data(), URLResponse())
    }

}
