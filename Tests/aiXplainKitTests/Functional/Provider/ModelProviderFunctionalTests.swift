// ModelProviderFunctionalTests.swift
// Created by Joao Pedro Monteiro Maia on 15/03/24.

import XCTest
import aiXplainKit

// IMPORTANT: THESE TESTS WILL COST CREDITS FROM YOUR ACCOUNT

final class ModelProviderFunctionalTests: XCTestCase {

    let llamaModelIdentifier = "6543cb991f695e72028e9428"
    let msftEnglishArabicModelIdentifier = "60ddefca8d38c51c58860131"
    let aiXplainEnglishSpeechRecognitionModelIdentifier = "621cf3fa6442ef511d2830af"
    let aiXplainArabicSpeechSynthesisModelIdentifier = "6171ef97159531495cadef56"

    var testRunningCosts: Float = 0

    override func setUp() async throws {
//        AiXplainKit.shared.logLevel = .error
    }

    override func tearDown() {
        print("Cost until now for running the functional tests: \(testRunningCosts)")
    }

    // MARK: Text-to-Text

    func testGetTextToTextOnPrem() async throws {
        let llamaModel = try await ModelProvider().get(llamaModelIdentifier)
        XCTAssertEqual(llamaModel.id, llamaModelIdentifier)
        XCTAssertEqual(llamaModel.name, "Llama 2 7B")
        XCTAssertEqual(llamaModel.version, "llama-2-7b-hf")
        XCTAssertEqual(llamaModel.pricing.price, 5e-06)
    }

    func testPerformanceTextToTextOnPrem() async throws {
        self.measure {
            let exp = expectation(description: "Finished")
            Task {
                _ = try await ModelProvider().get(llamaModelIdentifier)
                exp.fulfill()
            }
            wait(for: [exp], timeout: 200.0)
        }
    }

}
