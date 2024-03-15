//
//  ModelTestCase.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 15/03/24.
//

import XCTest
@testable import aiXplainKit

final class ModelTests: XCTestCase {

    let testedModel = Model(id: "MOCKMODEL", name: "Mock",
                            description: "Mock Model to unit testing",
                            supplier: Supplier(id: 0, name: "123", code: "123"),
                            version: "0",
                            pricing: Pricing(price: 0, unitType: "TOKENS"), networking: MockNetworking())

    override func tearDown() {
        testedModel.networking = MockNetworking()
        AiXplainKit.shared.keyManager.TEAM_API_KEY = nil

        AiXplainKit.shared.keyManager.BACKEND_URL  = URL(string: "https://platform-api.aixplain.com")

        AiXplainKit.shared.keyManager.MODELS_RUN_URL  = URL(string: "https://models.aixplain.com/api/v1/execute/")
    }

    func test_modelRun_Run_sucess() async {
        AiXplainKit.shared.keyManager.TEAM_API_KEY = "123"
        let modelOutput = try! await testedModel.run("Hello World")

        XCTAssertEqual(modelOutput.output, "Olá! Como posso ajudar você hoje?")
        XCTAssertEqual(modelOutput.usedCredits, 3.8e-05)
        XCTAssertEqual(modelOutput.runtime, 0.645)
    }

    func test_modelRun_Run_MissingModelRunError() async {
        AiXplainKit.shared.keyManager.TEAM_API_KEY = "123"
        AiXplainKit.shared.keyManager.MODELS_RUN_URL = nil
        do {
            _ = try await  testedModel.run("-")
        } catch {
            XCTAssertTrue(error as! ModelError == ModelError.missingModelRunURL)
        }
    }

    func test_modelRun_Run_MissingAPIKeyError() async {
        do {
            _ = try await  testedModel.run("-")
        } catch {
            XCTAssertTrue(error as! ModelError == ModelError.missingAPIKey)
        }
    }

    func test_modelRun_Run_InvalidStatusCodeError() async throws {
        guard let networking = testedModel.networking as? MockNetworking else {
            throw fatalError()
        }

        AiXplainKit.shared.keyManager.TEAM_API_KEY = "123"

        networking.addPattern("^https://models\\.aixplain\\.com/api/v1/execute/.*$",
                              data: model_CreateExecution_MockResponse!,
                              response: HTTPURLResponse(url: URL(string: "https://models.aixplain.com/api/v1/execute/")!, statusCode: 400, httpVersion: nil, headerFields: nil)!)

        do {
            _ = try await  testedModel.run("-")
        } catch {
            XCTAssertTrue(error as! NetworkingError == NetworkingError.invalidStatusCode(statusCode: 400))
        }
    }

}
