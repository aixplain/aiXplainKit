//
//  ModelProviderTests.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 08/03/24.
//

import XCTest
@testable import aiXplainKit

/// Test_method_description_expectation
final class ModelProviderTests: XCTestCase {

    let networking = MockNetworking()

    override func tearDownWithError() throws {
        AiXplainKit.shared.keyManager.clear()
    }

    func test_get_fetchesAndDecodesModel_whenSuccessfulResponse() async throws {
        AiXplainKit.shared.keyManager.TEAM_API_KEY = "-"

        let mockNetworking = MockNetworking()
        let response = HTTPURLResponse(url: URL(string: "http://mock.com")!, statusCode: 200, httpVersion: "", headerFields: [:])!
        let data = ModelProvider_get_MockResponse!
        mockNetworking.getReturnValue = (data, response)

        let modelProvider = ModelProvider(networking: mockNetworking)

        let fetchedModel = try await modelProvider.get("640b517694bf816d35a59125")
        XCTAssertEqual(fetchedModel.id, "640b517694bf816d35a59125")
    }

    func test_get_missingKEY_ThrowError() async throws {
        let mockNetworking = MockNetworking()
        let modelProvider = ModelProvider(networking: mockNetworking)

        do {
            _ = try await  modelProvider.get("-")
        } catch {
            XCTAssertTrue(error as! ModelError == ModelError.missingAPIKey)
        }

    }

    func test_get_noBackendURL_ThrowError() async throws {
        AiXplainKit.shared.keyManager.TEAM_API_KEY = "-"
        AiXplainKit.shared.keyManager.BACKEND_URL = nil

        let mockNetworking = MockNetworking()
        let modelProvider = ModelProvider(networking: mockNetworking)

        do {
            _ = try await  modelProvider.get("-")
        } catch {
            XCTAssertTrue(error as! ModelError == ModelError.missingBackendURL)
        }

    }

}
