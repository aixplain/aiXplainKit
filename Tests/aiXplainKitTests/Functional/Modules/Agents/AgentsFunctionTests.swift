//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 22/11/24.
//

import Foundation
import Foundation
import XCTest
@testable import aiXplainKit

// IMPORTANT: THESE TESTS WILL COST CREDITS FROM YOUR ACCOUNT

final class AgentFunctionalTests: XCTestCase {
    
    private var agent: Agent!
    
    override func setUp() async throws {
        try await super.setUp()
        // Use a shared agent instance for most tests
        agent = try await AgentProvider().get("67851fd27fbcb5fa9a62b53f")
    }
    
    func testAgentRun() async throws {
        let response = try await agent.run("Brazil population in 2020")
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
        XCTAssertFalse(response.data.input.isEmpty)
    }
    
    func testAgentRunWithParameters() async throws {
        let parameters = AgentRunParameters(
            pollingWaitTimeInSeconds: 1.0, maxPollingRetries: 5
        )
        
        let response = try await agent.run("What is Swift?", parameters: parameters)
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
    }
    
    func testAgentRunWithSessionID() async throws {
        let sessionID = UUID().uuidString
        let response = try await agent.run("Hello", sessionID: sessionID)
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
    }
    
    func testAgentQueryRun() async throws {
        // Test single placeholder replacement
        var response = try await agent.run(query: "{{city}} population in 2020",
                                         content: ["city": "Rio de Janeiro"])
        
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
        
        // Test appending content when no placeholder exists
        response = try await agent.run(query: "population in 2020",
                                     content: ["city": "Rome"])
        XCTAssertEqual(response.completed, true)
        XCTAssertEqual(response.data.input, "population in 2020 Rome")
        XCTAssert(response.status == "SUCCESS")
        
        // Test multiple placeholders
        response = try await agent.run(
            query: "Compare {{city1}} and {{city2}} populations",
            content: [
                "city1": "Tokyo",
                "city2": "London"
            ]
        )
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
    }
    
    func testAgentURLQueryRun() async throws {
        let imageURL = "https://i.pinimg.com/736x/44/b6/71/44b671446b75d00c686625eb89fc6326.jpg"
        let agent = try await AgentProvider().get("673e0fda8b9e53f626c8fe1d")
        
        let response = try await agent.run(
            query: "What is the history of the text in the figure: {{image}}",
            content: ["image": imageURL]
        )
        
        XCTAssertEqual(response.completed, true)
        XCTAssertEqual(response.data.input, "What is the history of the text in the figure:  \(imageURL)")
        XCTAssert(response.status == "SUCCESS")
    }
    
    func testAgentDataRun() async throws {
        let dataDictionary = ["query": "Hello World"]
        let jsonData = try JSONSerialization.data(withJSONObject: dataDictionary)
        
        let response = try await agent.run(jsonData)
        
        XCTAssertEqual(response.completed, true)
        XCTAssertEqual(response.data.input, "Hello World")
        XCTAssert(response.status == "SUCCESS")
    }
    
    func testInvalidAgentID() async throws {
        do {
            _ = try await AgentProvider().get("invalid_id")
            XCTFail("Expected error for invalid agent ID")
        } catch {
            XCTAssertTrue(error is NetworkingError)
        }
    }
    
    func testMaxContentItems() async throws {
        do {
            _ = try await agent.run(
                query: "Test {{1}} {{2}} {{3}} {{4}}",
                content: [
                    "1": "One",
                    "2": "Two",
                    "3": "Three",
                    "4": "Four" // Should trigger assertion
                ]
            )
            XCTFail("Expected assertion failure for too many content items")
        } catch {
            // Assertion should prevent this from being reached
        }
    }
    
    func testEmptyQuery() async throws {
        do {
            _ = try await agent.run("")
            XCTFail("Expected assertion failure for empty query")
        } catch {
            // Assertion should prevent this from being reached
        }
    }
    
    
    func testAgentRunWithLargeInput() async throws {
        // Test with a large string input
        let largeString = String(repeating: "a", count: 1000000)
        do {
            let response = try await agent.run(largeString)
            XCTAssertEqual(response.completed, true)
            XCTAssert(response.status == "SUCCESS")
        } catch {
            XCTFail("Failed to handle large input: \(error)")
        }
    }
    
    func testAgentRunWithSpecialCharacters() async throws {
        let specialChars = "!@#$%^&*()_+{}[]|\\:;\"'<>,.?/~`"
        let response = try await agent.run(
            query: "Process this: {{text}}",
            content: ["text": specialChars]
        )
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
    }
    
    func testAgentRunWithUnicodeCharacters() async throws {
        let unicodeString = "Hello 世界! 👋 🌍"
        let response = try await agent.run(unicodeString)
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
    }
    
    func testAgentRunWithMissingPlaceholder() async throws {
        let response = try await agent.run(
            query: "Test {{missing}}",
            content: ["different": "value"]
        )
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
        XCTAssertEqual(response.data.input, "Test {{missing}} value")
    }
    
    func testAgentRunWithEmptyContent() async throws {
        let response = try await agent.run(
            query: "Test {{placeholder}}",
            content: [:]
        )
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
        XCTAssertEqual(response.data.input, "Test {{placeholder}}")
    }
    
    func testAgentRunWithMultipleURLs() async throws {
        let urls = [
            "https://example.com/image1.jpg",
            "https://example.com/image2.jpg"
        ]
        
        let response = try await agent.run(
            query: "Compare these images: {{url1}} and {{url2}}",
            content: [
                "url1": urls[0],
                "url2": urls[1]
            ]
        )
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
    }
    
    func testAgentRunWithTimeout() async throws {
        let parameters = AgentRunParameters(
            pollingWaitTimeInSeconds: 0.1, maxPollingRetries: 1
        )
        
        do {
            _ = try await agent.run("This should timeout", parameters: parameters)
            XCTFail("Expected timeout error")
        } catch {
            XCTAssertTrue(error is ModelError)
        }
    }
}
