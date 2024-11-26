//
//  ModelFunctionTests.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 26/03/24.
//

import XCTest
@testable import aiXplainKit

final class ModelFunctionalTests: XCTestCase {

    let llamaModelIdentifier = "6543cb991f695e72028e9428"

    var testRunningCosts: Float = 0

    override func setUp() async throws {
//        AiXplainKit.shared.logLevel = .error
        AiXplainKit.shared.keyManager.reload()
    }

    override func tearDown() {
        print("Cost until now for running the functional tests: \(testRunningCosts)")
    }

    // MARK: Text-to-Text

    func testRunTextToTextOnPrem() async throws {
        let llamaModel = try await ModelProvider().get(llamaModelIdentifier)
        let modelOutput = try! await llamaModel.run("Hello World")
        XCTAssertTrue(modelOutput.output.count > 0)
        XCTAssertTrue(modelOutput.usedCredits > 0 || modelOutput.usedCredits < 1)
        XCTAssertTrue(modelOutput.runtime < 60 * 5)
        testRunningCosts += modelOutput.usedCredits
    }

    func testRunPerformanceTextToTextOnPrem() async throws {
        let llamaModel = try await ModelProvider().get(llamaModelIdentifier)
        self.measure {
            let exp = expectation(description: "Finished")
            Task {
                let modelOutput = try! await llamaModel.run("Hello World")
                testRunningCosts += modelOutput.usedCredits
                exp.fulfill()
            }
            wait(for: [exp], timeout: 200.0)
        }
    }

    func test_model_description() async {
        let llamaModel = try! await ModelProvider().get(llamaModelIdentifier)

        XCTAssertTrue(llamaModel.id == "6543cb991f695e72028e9428")
        XCTAssertEqual(llamaModel.name, "Llama 2 7B")
        XCTAssertEqual(llamaModel.supplier.id, 1)
        XCTAssertEqual(llamaModel.supplier.name, "aiXplain")
        XCTAssertEqual(llamaModel.supplier.code, "aixplain")
        XCTAssertEqual(llamaModel.version, "llama-2-7b-hf")
        XCTAssertEqual(llamaModel.pricing.price, 5e-06)
        XCTAssertEqual(llamaModel.pricing.unitType, "TOKEN")
        XCTAssertNil(llamaModel.pricing.unitScale)

        var description = "Model:\n  ID: 6543cb991f695e72028e9428\n  Name: Llama 2 7B\n  Description: Creates coherent and contextually relevant textual content based on prompts or certain parameters. Useful for chatbots, content creation, and data augmentation.\n  Hosted By: aiXplain\n  Developed By: aiXplain\n  Version: llama-2-7b-hf\n  Pricing: Pricing(price: 5e-06, unitType: Optional(\"TOKEN\"), unitScale: nil)\n"

        XCTAssertTrue(llamaModel.description == description)
    }

    // MARK: Audio-to-Text

    func testRunAudioToTextOnPrem() async throws {
        let speechModel = try await ModelProvider().get("621cf3fa6442ef511d2830af")

        let marshallPlanURL: URL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/7/75/Marshall_Plan_Speech.wav")!
        // Audio file from: George C. Marshall, Public domain, via Wikimedia Commons

        let modelOutput = try! await speechModel.run(marshallPlanURL)

        XCTAssert(modelOutput.output == "It is logical that the United States should do whatever it is able to do to assist in the return of normal economic health in the world, without which there can be no political stability and no assured peace. Our policy is directed not against any country or doctrine, but against hunger, poverty, desperation and chaos.")
        XCTAssert(modelOutput.usedCredits < 0.01)
        testRunningCosts += modelOutput.usedCredits

        // From Local URL

        await self.withTempFile(from: marshallPlanURL) { localURL in
                let modelOutput = try! await speechModel.run(localURL)

                XCTAssert(modelOutput.output == "It is logical that the United States should do whatever it is able to do to assist in the return of normal economic health in the world, without which there can be no political stability and no assured peace. Our policy is directed not against any country or doctrine, but against hunger, poverty, desperation and chaos.")
                XCTAssert(modelOutput.usedCredits < 0.01)
            self.testRunningCosts += modelOutput.usedCredits

        }
    }

    // MARK: Image-to-text

    func testRunImageToTextOnPrem() async throws {
        let blipModel = try await ModelProvider().get("60ddef7d8d38c51c5885d1e9")

        let nasaURL: URL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/4/4e/Surveyor_3-Apollo_12.jpg")!
        // Image file from: NASA, Alan L. Bean, Public domain, via Wikimedia Commons

        let modelOutput = try! await blipModel.run(nasaURL)

        let expectedOutputList = "Aircraft, Airplane, Landing, Vehicle, Baby, Outer Space, Nature, Face, Head, Portrait, Worker, Night, Moon, Motorcycle, Beach, Coast, Sea, Shoreline, Hat, People, Hardhat, Building, Shelter, Airfield, Space Station, Ammunition, Bomb, Antenna, Radio Telescope, Cannon, Photographer, Spaceship, Desert, Sand, Bird, Flying, Camping".components(separatedBy: ", ")

        let modelOutputSet = Set(modelOutput.output.components(separatedBy: ", "))

        let intersection = modelOutputSet.intersection(expectedOutputList)

        let matchPercentage = Double(intersection.count) / Double(expectedOutputList.count) * 100

        // check if at least 50% match the list
        XCTAssertTrue(matchPercentage >= 50)
    }

    // TODO: Image-To-Image
    // TODO: Text-To-Audio

}
