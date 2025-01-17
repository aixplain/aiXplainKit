//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 10/01/25.
//

import XCTest
@testable import aiXplainKit

final class ModelUtilityFunctionTests: XCTestCase {
    // MARK: - Setup
    
    func testCreateTool() async throws {
        let code = """
            def main(number,text):
                if number > 0:
                    return text
                return number + 10
            """
        
        let utility = try await ModelProvider().createUtilityModel(
            name: "Functional test",
            code: code, 
            inputs: [
                .number(name: "number", description: "number to be used in the test"),
                .text(name: "text", description: "text to be used in the test")
            ],
            description: "Test Utility"
        )
        
        // Test positive number case - should return text
        let response1 = try await utility.run(["number": "10", "text": "Hello World"])
        XCTAssertEqual(response1.output as? String, "Hello World")
        
        // Test zero case - should return number + 10
        let response2 = try await utility.run(["number": "0", "text": "Hello World"]) 
        XCTAssertEqual(Int(response2.output), 10)
        
        // Test negative number case - should return number + 10
        let response3 = try await utility.run(["number": "-5", "text": "Hello World"])
        XCTAssertEqual(Int(response3.output), 5)
    }
    
    func testUpdateTool() async throws {

        let code = """
            def main(number,text):
                if number > 0:
                    return text
                return number + 10
            """
        
        let utility = try await ModelProvider().createUtilityModel(
            name: "Functional test",
            code: code,
            inputs: [
                .number(name: "number", description: "number to be used"),
                .text(name: "text", description: "text to be used")
            ],
            description: "Test Utility"
        )
        
        // Test positive number case - should return text
        let response1 = try await utility.run(["number": "10", "text": "Hello World"])
        XCTAssertEqual(response1.output as? String, "Hello World")
        
        utility.code = """
        def main(text):
            return text
        """
        
        utility.inputs = [
            .init(name: "text", description: "text to be used")
        ]
        
        try await utility.update()
        
        let response2 = try await utility.run(["text": "Hello World"])
        XCTAssertEqual(response2.output, "Hello World")
    }
    
    func testDeleteTool() async throws {
        let code = """
            def main(number,text):
                if number > 0:
                    return text
                return number + 10
            """
        
        let utility = try await ModelProvider().createUtilityModel(
            name: "Functional test",
            code: code,
            inputs: [
                .number(name: "number", description: "number to be used"),
                .text(name: "text", description: "text to be used")
            ],
            description: "Test Utility"
        )
        
        try await utility.delete()
        
        do {
            _ = try await ModelProvider().get(utility.id)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
        }
    }
    
}
