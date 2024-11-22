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
    
    //TODO: Team of agents function all
    
    
    func testAgentRun() async throws {
        let agent = try await AgentProvider().get("6734ea202a37811479ff2513")
        let response = try await agent.run("Brazil population in 2020")
        XCTAssertEqual(response.completed, true)
        XCTAssert(response.status == "SUCCESS")
    }
    
    
    func testAgentQueryRun() async throws {
        let agent = try await AgentProvider().get("6734ea202a37811479ff2513")
        
        var response = try await agent.run(query: "{{city}}population in 2020",
                                           content: [
                                            "city" : "Rio de Janeiro"
                                           ])
        
        
        XCTAssertEqual(response.completed, true)
        XCTAssertEqual(response.data.input , "Rio de Janeiro population in 2020")
        XCTAssert(response.status == "SUCCESS")
        
        response = try await agent.run(query: "population in 2020",
                                       content: [
                                        "city" : "Rome"
                                       ])
        XCTAssertEqual(response.completed, true)
        XCTAssertEqual(response.data.input , "population in 2020 Rome")
        XCTAssert(response.status == "SUCCESS")
    }
    
    //TODO: URL Input in query
    func testAgentURLQueryRun() async throws {
        let agent = try await AgentProvider().get("673e0fda8b9e53f626c8fe1d")
        
        var response = try await agent.run(query: "What is the history of the text in the figure: {{image}}",
                                           content: [
                                            "image" : "https://i.pinimg.com/736x/44/b6/71/44b671446b75d00c686625eb89fc6326.jpg"
                                           ])
        
        
        XCTAssertEqual(response.completed, true)
        XCTAssertEqual(response.data.input , "What is the history of the text in the figure:  https://i.pinimg.com/736x/44/b6/71/44b671446b75d00c686625eb89fc6326.jpg")
        XCTAssert(response.status == "SUCCESS")
        dump(response)
       
    }
    
    
    func testAgentDataRun() async throws {
        let agent = try await AgentProvider().get("6734ea202a37811479ff2513")
        
        let dataDictionary = ["query": "Hello World"]
        let jsonData = try JSONSerialization.data(withJSONObject: dataDictionary, options: [])
        
        var response = try await agent.run(jsonData)
        
        
        XCTAssertEqual(response.completed, true)
        XCTAssertEqual(response.data.input , "Hello World")
        XCTAssert(response.status == "SUCCESS")
    }
    
}
