//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 27/03/24.
//

import Foundation
import XCTest
@testable import aiXplainKit

final class PipelineFunctionalTests: XCTestCase {

    let textToTextPipelineID: String = "66044a4d2d35979dedf6017f"
    let multipleTextToTextPipelineID: String = ""
    let imageToTextPipelineID: String = ""
    let audioToTextPipelienID: String = ""
    let multipleInputPipelineID: String = "660550382d35979dedf60307"

    var testRunningCosts: Float = 0

    override func setUp() async throws {
//        AiXplainKit.shared.logLevel = .error
        AiXplainKit.shared.keyManager.reload()
    }

    override func tearDown() {
        print("Cost until now for running the functional tests: \(testRunningCosts)")
    }

    func testTextToTextPipeline() async {
        let pipeline = try! await PipelineProvider().get(textToTextPipelineID)

        XCTAssert(pipeline.id == textToTextPipelineID)
        XCTAssert(pipeline.inputNodes.count == 1)
        XCTAssert(pipeline.inputNodes.first?.dataType.first == "text")
        XCTAssert(pipeline.outputNodes.count == 1)

        let pipelineOutput = try! await pipeline.run("The primary duty of an exception handler is to get the error out of the lap of the programmer and into the surprised face of the user.")

        XCTAssertEqual(pipelineOutput.creditsUsed, 0)

        if let json = try? JSONSerialization.jsonObject(with: pipelineOutput.rawData, options: []) as? [String: Any] {

            if let dataArray = json["data"] as? [[String: Any]],
               let dataObject = dataArray.first,
               let segments = dataObject["segments"] as? [[String: Any]],
               let segment = segments.first,
               let details = segment["details"] as? [String: Any],
               let rawData = details["rawData"] as? [String: Any],
               let data = rawData["data"] as? [String: Any],
               let translations = data["translations"] as? [[String: String]],
               let translation = translations.first {

                if let translatedText = translation["translatedText"] {
                   XCTAssertEqual(translatedText, "La tâche principale d'un gestionnaire d'exceptions est d'extraire l'erreur du programmeur et de la faire apparaître sur le visage surpris de l'utilisateur.")
                }
            }
        }
    }

    func testmultipleInputPipeline() async {
        let pipeline = try! await PipelineProvider().get(multipleInputPipelineID)

        let marshallPlanURL: URL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/7/75/Marshall_Plan_Speech.wav")!
        // Audio file from: George C. Marshall, Public domain, via Wikimedia Commons

        let input: [String: PipelineInput] = ["Voice": marshallPlanURL, "Text": "In the week before their departure to Arrakis, when all the final scurrying about had reached a nearly unbearable frenzy, an old crone came to visit the mother of the boy, Paul."]

        let pipelineOutput = try! await pipeline.run(input)
        XCTAssertNotNil(pipelineOutput.rawData)

        await self.withTempFile(from: marshallPlanURL) { localURL in
            let input: [String: PipelineInput] = ["Voice": localURL, "Text": "In the week before their departure to Arrakis, when all the final scurrying about had reached a nearly unbearable frenzy, an old crone came to visit the mother of the boy, Paul."]

            let pipelineOutput = try! await pipeline.run(input)
            XCTAssertNotNil(pipelineOutput.rawData)
        }

    }
}
