//
//  AgentBuildingTests.swift
//  aiXplainKit
//
//  Created by Joao Maia on 10/01/25.
//

import XCTest
@testable import aiXplainKit

final class AgentBuildingTests: XCTestCase {
    
    // MARK: - Properties
    
    private let defaultAgentName = "Swift Functional Test Agent"
    private let defaultAgentDescription = "This agent has been created for functional testing purposes"
    
    
    // MARK: - Tests
    
    func testBuildAgent() async throws {
        // Given
        let tools = createDefaultTools()
        
        // When
        let agent = try await AgentProvider().create(
            name: defaultAgentName,
            description: defaultAgentDescription,
            tools: tools
        )
        
        // Then
        validateAgent(agent, expectedToolCount: 4)
    }
    
    func testBuildAgentWithAssetsAndModelsAndTools() async throws {
        // Given
        let utilityModel = try await createRandomNumberUtilityModel()
        let textToSpeechTool = try await ModelProvider().get("6171efa5159531495cadefbc")
        let tools = try await createComplexTools(utilityModel: utilityModel, tool: textToSpeechTool)
        
        // When
        let agent = try await AgentProvider().create(
            name: defaultAgentName,
            description: defaultAgentDescription,
            tools: tools
        )
        
        // Then
        validateAgent(agent, expectedToolCount: 4)
    }
    
    func testUpdateAgent() async throws {
        // Given
        let initialTools: [CreateAgentTool] = [
            .asset(id: "65c51c556eb563350f6e1bb1", description: "Allows the agent to perform web searches to find up-to-date information on any topic. Use this tool to access the most recent and relevant online content.")
        ]
        
        // When
        let agent = try await AgentProvider().create(
            name: defaultAgentName,
            description: defaultAgentDescription,
            tools: initialTools
        )
        
        // Then
        validateAgent(agent, expectedToolCount: 1)
        
        // When updating
        try await agent.appendTools([
            .asset(id: "6633fd59821ee31dd914e232", description: "Allows the agent to perform web searches to find up-to-date information on any topic. Use this tool to access the most recent and relevant online content.")
        ])
        
        // Then after update
        XCTAssertEqual(agent.assets.count, 2, "Agent should have 2 tools after appending")
    }
    
    func testUpdateAndDeleteAgent() async throws {
        // Given
        let initialTools: [CreateAgentTool] = [
            .asset(id: "65c51c556eb563350f6e1bb1", description: "Allows the agent to perform web searches to find up-to-date information on any topic. Use this tool to access the most recent and relevant online content.")
        ]
        
        // When
        let agent = try await AgentProvider().create(
            name: defaultAgentName,
            description: defaultAgentDescription,
            tools: initialTools
        )
        
        // Then
        validateAgent(agent, expectedToolCount: 1)
        
        // When deleting
        try await agent.delete()
    }
    
    // MARK: - Helper Methods
    
    private func createDefaultTools() -> [CreateAgentTool] {
        [
            .asset(id: "65c51c556eb563350f6e1bb1", description: "Allows the agent to perform web searches to find up-to-date information on any topic. Use this tool to access the most recent and relevant online content."),
            .asset(id: "6633fd59821ee31dd914e232", description: "Allows the agent to perform web searches to find up-to-date information on any topic. Use this tool to access the most recent and relevant online content."),
            .asset(id: "64aee5824d34b1221e70ac07", description: "Generates high-quality images from detailed text prompts. Use this tool to create visual representations or artistic renderings based on user input."),
            .asset(id: "6171efa5159531495cadefbc", description: "Converts text to spoken audio in natural-sounding voices. Useful for generating audible output or creating voice responses for interactive applications")
        ]
    }
    
    private func createRandomNumberUtilityModel() async throws -> UtilityModel {
        let code = """
        def main(number):
            import random
            return random.randint(1, number)
        """
        
        return try await ModelProvider().createUtilityModel(
            name: "Random Number Generator",
            code: code,
            inputs: [.number(name: "number", description: "max random integer to be used")],
            description: "generate random numbers"
        )
    }
    
    private func createComplexTools(utilityModel: UtilityModel, tool: Model) async throws -> [CreateAgentTool] {
        [
            .asset(id: "65c51c556eb563350f6e1bb1", description: "Allows the agent to perform web searches to find up-to-date information on any topic. Use this tool to access the most recent and relevant online content."),
            .model(try await ModelProvider().get("6633fd59821ee31dd914e232"), description: "Allows the agent to perform web searches to find up-to-date information on any topic. Use this tool to access the most recent and relevant online content."),
            .utility(utilityModel, description: "generation of random numbers"),
            .tool(tool, description: "Text to speech")
        ]
    }
    
    private func validateAgent(_ agent: Agent, expectedToolCount: Int) {
        XCTAssertFalse(agent.id.isEmpty, "Agent ID should not be empty")
        XCTAssertEqual(agent.name, defaultAgentName, "Agent name should match the provided name")
        XCTAssertEqual(agent.status, "draft", "Initial agent status should be draft")
        XCTAssertEqual(agent.description, defaultAgentDescription, "Agent description should match the provided description")
        XCTAssertEqual(agent.assets.count, expectedToolCount, "Agent should have \(expectedToolCount) tools")
    }
}
