//
//  NetworkingTests.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 08/03/24.
//

import XCTest
@testable import aiXplainKit

final class NetworkingTests: XCTestCase {

    override func tearDownWithError() throws {
        AiXplainKit.shared.keyManager.clear()
    }

    func test_buildHeaders_correctly() {
        AiXplainKit.shared.keyManager.TEAM_API_KEY = "-"
        let network = Networking()

        var headers = try? network.buildHeader()

        XCTAssertEqual(headers, ["Authorization": "Token -", "Content-Type": "application/json"])

        AiXplainKit.shared.keyManager.TEAM_API_KEY = nil
        AiXplainKit.shared.keyManager.TEAM_API_KEY = "-"

        XCTAssertEqual(headers, ["Authorization": "Token -", "Content-Type": "application/json"])

    }

    func test_buildHeaders_MissingKeysError() {
        let network = Networking()
        do {
            _ = try network.buildHeader()
        } catch {
            XCTAssertTrue(error as! ModelError == ModelError.missingAPIKey)
        }
    }

    func test_buildHeaders_MissingBackendError() {
        AiXplainKit.shared.keyManager.BACKEND_URL = nil
        let network = Networking()

        do {
            _ = try network.buildUrl(for: .function)
        } catch {
            XCTAssertTrue(error as! ModelError == ModelError.missingBackendURL)
        }

        do {
            _ = try network.buildUrl(for: .model(modelID: "123"))
        } catch {
            XCTAssertTrue(error as! ModelError == ModelError.missingBackendURL)
        }

    }

}
