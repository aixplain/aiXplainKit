//
//  AgentsProviderFunctionalTests.swift
//  aiXplainKit
//
//  Created by Joao Maia on 22/11/24.
//


import XCTest
import aiXplainKit


final class AgentsProviderFunctionalTests: XCTestCase {
    
    func testLoadAgent()  async throws{
        let agent = try await AgentProvider().get("673deab41fafaeceee8829c8")
        XCTAssertEqual(agent.id, "673deab41fafaeceee8829c8")
        XCTAssertEqual(agent.name, "Flight  v8  Swift SDK")
        XCTAssertEqual(agent.status, "draft")
        XCTAssertEqual(agent.teamId, 1)
        XCTAssertEqual(agent.description, "This is an agent about Flights")
        XCTAssertEqual(agent.llmId, "6646261c6eb563165658bbb1")
        XCTAssertEqual(agent.createdAt.timeIntervalSinceReferenceDate, 753803828.51)
        XCTAssertEqual(agent.updatedAt.timeIntervalSinceReferenceDate, 753803828.51)
    }
    
    func testLoadTeamOfAgents()  async throws{
        let agent = try await AgentProvider().get("673e0fda8b9e53f626c8fe1d")
        XCTAssertEqual(agent.id, "673e0fda8b9e53f626c8fe1d")
        XCTAssertEqual(agent.name, "Team of Agents for Text Audio and Image Processing test in SwiftSDK")
        XCTAssertEqual(agent.status, "draft")
        XCTAssertEqual(agent.teamId, 1)
        XCTAssertEqual(agent.description, "")
        XCTAssertEqual(agent.llmId, "6646261c6eb563165658bbb1")
        XCTAssertEqual(agent.createdAt.timeIntervalSinceReferenceDate, 753813338.1800001)
        XCTAssertEqual(agent.updatedAt.timeIntervalSinceReferenceDate, 753813338.1800001)
    }
    
}
