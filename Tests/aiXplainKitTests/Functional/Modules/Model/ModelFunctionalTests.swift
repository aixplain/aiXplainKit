//
//  ModelFunctionTests.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 26/03/24.
//

import XCTest
@testable import aiXplainKit

final class ModelFunctionalTests: XCTestCase {

    let llamaModelIdentifier = "6622cf096eb563537126b1a1"

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

        XCTAssertTrue(llamaModel.id == "6622cf096eb563537126b1a1")
        XCTAssertEqual(llamaModel.name, "Llama 3 8B")
        XCTAssertEqual(llamaModel.supplier.id, 6839)
        XCTAssertEqual(llamaModel.supplier.name, "Groq")
        XCTAssertEqual(llamaModel.supplier.code, "groq")
        XCTAssertEqual(llamaModel.version, "llama3-8b-8192")
        XCTAssertEqual(llamaModel.pricing.price, 7.5e-07)
        XCTAssertEqual(llamaModel.pricing.unitType, "TOKEN")
        XCTAssertNil(llamaModel.pricing.unitScale)

        var description = "Model:\n  ID: 6622cf096eb563537126b1a1\n  Name: Llama 3 8B\n  Description: Creates coherent and contextually relevant textual content based on prompts or certain parameters. Useful for chatbots, content creation, and data augmentation.\n  Hosted By: Groq\n  Developed By: Meta\n  Version: llama3-8b-8192\n  Pricing: Pricing(price: 7.5e-07, unitType: Optional(\"TOKEN\"), unitScale: nil)\n"

        XCTAssertTrue(llamaModel.description == description)
    }

    // MARK: Audio-to-Text

    func testRunAudioToTextOnPrem() async throws {
        let speechModel = try await ModelProvider().get("61716a9ed4e2751804b8097a")

        let marshallPlanURL: URL = URL(string: "https://www.americanrhetoric.com/mp3clips/newmoviespeeches/moviespeechthereturnofthekingbenediction.mp3")!
        // Audio file from: Lord of The Rings: The Return of the King, https://www.americanrhetoric.com/MovieSpeeches/moviespeechreturnoftheking.html


        // From Local URL
        await self.withTempFile(from: marshallPlanURL) { localURL in
                let modelOutput = try! await speechModel.run(localURL)

                XCTAssert(modelOutput.output == "This day does not belong to one man, but to all let us together rebuild this world that we may share in the days of peace.")
                XCTAssert(modelOutput.usedCredits < 0.1)
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

    //TODO: Model Provider to get a list
    func testModelList() async throws {
        let modelList = try await ModelProvider().list(.init(functions: []))
        XCTAssertTrue(modelList.count > 0)
    }
    
}
