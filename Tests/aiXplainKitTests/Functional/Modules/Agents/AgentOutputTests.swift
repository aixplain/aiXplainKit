//
//  AgentOutputTests.swift
//  aiXplainKitTests
//
//  Created by João Pedro on 26/03/2024.
//

import XCTest
@testable import aiXplainKit

final class AgentOutputTests: XCTestCase {
    
    func testDecodeBasicAgentOutput() throws {
        let json = """
        {
            "completed": true,
            "status": "SUCCESS",
            "data": {
                "input": "Hello World",
                "output": "Greetings!",
                "session_id": "123456",
                "intermediate_steps": []
            }
        }
        """
        
        let agentOutput = try AgentOutput(json)
        
        XCTAssertTrue(agentOutput.completed)
        XCTAssertEqual(agentOutput.status, "SUCCESS")
        XCTAssertEqual(agentOutput.data.input, "Hello World")
        XCTAssertEqual(agentOutput.data.output, "Greetings!")
        XCTAssertEqual(agentOutput.data.sessionID, "123456")
        XCTAssertTrue(agentOutput.data.intermediateSteps.isEmpty)
    }
    
    func testDecodeAgentOutputWithIntermediateSteps() throws {
        let json = """
        {
            "completed": true,
            "status": "SUCCESS",
            "data": {
                "input": "What's the weather?",
                "output": "It's sunny",
                "session_id": "789",
                "intermediate_steps": [
                    {
                        "agent": "weather-bot",
                        "input": "Check weather",
                        "output": "Sunny conditions",
                        "tool_steps": [
                            {
                                "tool": "weather-api",
                                "input": "get-current",
                                "output": "sunny",
                                "runTime": null,
                                "usedCredits": null
                            }
                        ],
                        "thought": "I should check the weather",
                        "runTime": 1.5,
                        "usedCredits": 0.1
                    }
                ]
            }
        }
        """
        
        let agentOutput = try AgentOutput(json)
        
        XCTAssertTrue(agentOutput.completed)
        XCTAssertEqual(agentOutput.status, "SUCCESS")
        XCTAssertEqual(agentOutput.data.input, "What's the weather?")
        XCTAssertEqual(agentOutput.data.output, "It's sunny")
        
        let step = try XCTUnwrap(agentOutput.data.intermediateSteps.first)
        XCTAssertEqual(step.agent, "weather-bot")
        XCTAssertEqual(step.input, "Check weather")
        XCTAssertEqual(step.output, "Sunny conditions")
        XCTAssertEqual(step.thought, "I should check the weather")
        XCTAssertEqual(step.runTime, 1.5)
        XCTAssertEqual(step.usedCredits, 0.1)
        
        let toolStep = try XCTUnwrap(step.toolSteps?.first)
        XCTAssertEqual(toolStep.tool, "weather-api")
        XCTAssertEqual(toolStep.input, "get-current")
        XCTAssertEqual(toolStep.output, "sunny")
    }
    
    func testDecodeInvalidJSON() {
        let invalidJSON = """
        {
            "completed": true,
            "status": "SUCCESS"
            "data": { // Missing comma
                "input": "Hello"
            }
        }
        """
        
        XCTAssertThrowsError(try AgentOutput(invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError || error is NSError)
        }
    }
    
    func testMissingRequiredFields() {
        let incompleteJSON = """
        {
            "completed": true,
            "data": {
                "input": "Hello",
                "output": "Hi",
                "session_id": "123",
                "intermediate_steps": []
            }
        }
        """
        
        XCTAssertThrowsError(try AgentOutput(incompleteJSON)) { error in
            guard case .keyNotFound? = error as? DecodingError else {
                XCTFail("Expected keyNotFound error")
                return
            }
        }
    }
    
    func testEncodingAndDecoding() throws {
        // Create an AgentOutput instance
        let originalOutput = AgentOutput(
            completed: true,
            status: "SUCCESS",
            data: DataClass(
                input: "Test input",
                output: "Test output",
                sessionID: "test-123",
                intermediateSteps: [
                    IntermediateStep(
                        agent: "test-agent",
                        input: "step input",
                        output: "step output",
                        toolSteps: nil,
                        thought: "thinking",
                        runTime: 1.0,
                        usedCredits: 0.5
                    )
                ]
            )
        )
        
        // Encode to JSON data
        let encodedData = try originalOutput.jsonData()
        
        // Decode back to AgentOutput
        let decodedOutput = try AgentOutput(data: encodedData)
        
        // Verify the decoded output matches the original
        XCTAssertEqual(decodedOutput.completed, originalOutput.completed)
        XCTAssertEqual(decodedOutput.status, originalOutput.status)
        XCTAssertEqual(decodedOutput.data.input, originalOutput.data.input)
        XCTAssertEqual(decodedOutput.data.output, originalOutput.data.output)
        XCTAssertEqual(decodedOutput.data.sessionID, originalOutput.data.sessionID)
        XCTAssertEqual(decodedOutput.data.intermediateSteps.count, originalOutput.data.intermediateSteps.count)
    }
    
    func testDecodeAgentOutputWithNullValues() throws {
        let json = """
        {
            "completed": true,
            "status": "SUCCESS",
            "data": {
                "input": "Test input",
                "output": "Test output",
                "session_id": "123",
                "intermediate_steps": [
                    {
                        "agent": "test-agent",
                        "input": "step input",
                        "output": "step output",
                        "tool_steps": null,
                        "thought": null,
                        "runTime": 1.5,
                        "usedCredits": 0.1
                    }
                ]
            }
        }
        """
        
        let agentOutput = try AgentOutput(json)
        let step = try XCTUnwrap(agentOutput.data.intermediateSteps.first)
        
        XCTAssertNil(step.toolSteps)
        XCTAssertNil(step.thought)
        XCTAssertEqual(step.runTime, 1.5)
        XCTAssertEqual(step.usedCredits, 0.1)
    }
    
    func testDecodeAgentOutputWithEmptyStrings() throws {
        let json = """
        {
            "completed": true,
            "status": "SUCCESS",
            "data": {
                "input": "",
                "output": "",
                "session_id": "",
                "intermediate_steps": [
                    {
                        "agent": "",
                        "input": "",
                        "output": "",
                        "tool_steps": [],
                        "thought": "",
                        "runTime": 0.0,
                        "usedCredits": 0.0
                    }
                ]
            }
        }
        """
        
        let agentOutput = try AgentOutput(json)
        
        XCTAssertEqual(agentOutput.data.input, "")
        XCTAssertEqual(agentOutput.data.output, "")
        XCTAssertEqual(agentOutput.data.sessionID, "")
        
        let step = try XCTUnwrap(agentOutput.data.intermediateSteps.first)
        XCTAssertEqual(step.agent, "")
        XCTAssertEqual(step.input, "")
        XCTAssertEqual(step.output, "")
        XCTAssertEqual(step.thought, "")
    }
    
    func testDecodeAgentOutputWithMultipleToolSteps() throws {
        let json = """
        {
            "completed": true,
            "status": "SUCCESS",
            "data": {
                "input": "Complex query",
                "output": "Final result",
                "session_id": "789",
                "intermediate_steps": [
                    {
                        "agent": "multi-tool-agent",
                        "input": "Process query",
                        "output": "Processed result",
                        "tool_steps": [
                            {
                                "tool": "tool1",
                                "input": "input1",
                                "output": "output1",
                                "runTime": null,
                                "usedCredits": null
                            },
                            {
                                "tool": "tool2",
                                "input": "input2",
                                "output": "output2",
                                "runTime": null,
                                "usedCredits": null
                            }
                        ],
                        "thought": "Processing with multiple tools",
                        "runTime": 2.5,
                        "usedCredits": 0.2
                    }
                ]
            }
        }
        """
        
        let agentOutput = try AgentOutput(json)
        let step = try XCTUnwrap(agentOutput.data.intermediateSteps.first)
        let toolSteps = try XCTUnwrap(step.toolSteps)
        
        XCTAssertEqual(toolSteps.count, 2)
        XCTAssertEqual(toolSteps[0].tool, "tool1")
        XCTAssertEqual(toolSteps[0].input, "input1")
        XCTAssertEqual(toolSteps[0].output, "output1")
        XCTAssertEqual(toolSteps[1].tool, "tool2")
        XCTAssertEqual(toolSteps[1].input, "input2")
        XCTAssertEqual(toolSteps[1].output, "output2")
    }
    
    func testDecodeAgentOutputWithMultipleIntermediateSteps() throws {
        let json = """
        {
            "completed": true,
            "status": "SUCCESS",
            "data": {
                "input": "Multi-step query",
                "output": "Final output",
                "session_id": "abc123",
                "intermediate_steps": [
                    {
                        "agent": "agent1",
                        "input": "step1 input",
                        "output": "step1 output",
                        "tool_steps": null,
                        "thought": "first thought",
                        "runTime": 1.0,
                        "usedCredits": 0.1
                    },
                    {
                        "agent": "agent2",
                        "input": "step2 input",
                        "output": "step2 output",
                        "tool_steps": null,
                        "thought": "second thought",
                        "runTime": 1.5,
                        "usedCredits": 0.15
                    }
                ]
            }
        }
        """
        
        let agentOutput = try AgentOutput(json)
        
        XCTAssertEqual(agentOutput.data.intermediateSteps.count, 2)
        XCTAssertEqual(agentOutput.data.intermediateSteps[0].agent, "agent1")
        XCTAssertEqual(agentOutput.data.intermediateSteps[0].thought, "first thought")
        XCTAssertEqual(agentOutput.data.intermediateSteps[1].agent, "agent2")
        XCTAssertEqual(agentOutput.data.intermediateSteps[1].thought, "second thought")
    }
    
    func testJSONNullBehavior() {
        let jsonNull1 = JSONNull()
        let jsonNull2 = JSONNull()
        
        XCTAssertEqual(jsonNull1, jsonNull2)
        XCTAssertEqual(jsonNull1.hashValue, 0)
        
        var hasher = Hasher()
        jsonNull1.hash(into: &hasher)
        // No assertion needed for hash(into:) as it's a no-op function
    }
    
    func testJSONDecodingErrors() throws {
        // Test invalid JSON format
        let malformedJSON = "{ this is not valid json }"
        XCTAssertThrowsError(try AgentOutput(malformedJSON)) { error in
            XCTAssertTrue(error is DecodingError || error is NSError)
        }
        
        // Test wrong type for boolean field
        let invalidBooleanJSON = """
        {
            "completed": "true",
            "status": "SUCCESS",
            "data": {
                "input": "test",
                "output": "test",
                "session_id": "123",
                "intermediate_steps": []
            }
        }
        """
        XCTAssertThrowsError(try AgentOutput(invalidBooleanJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
        
        // Test wrong type for numeric field
        let invalidNumericJSON = """
        {
            "completed": true,
            "status": "SUCCESS",
            "data": {
                "input": "test",
                "output": "test",
                "session_id": "123",
                "intermediate_steps": [{
                    "agent": "test",
                    "input": "test",
                    "output": "test",
                    "runTime": "not a number",
                    "usedCredits": 0.1
                }]
            }
        }
        """
        XCTAssertThrowsError(try AgentOutput(invalidNumericJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testWithFunctions() throws {
        // Test AgentOutput.with()
        let originalOutput = AgentOutput(
            completed: false,
            status: "PENDING",
            data: DataClass(
                input: "original",
                output: "original",
                sessionID: "123",
                intermediateSteps: []
            )
        )
        
        let modifiedOutput = originalOutput.with(
            completed: true,
            status: "SUCCESS"
        )
        
        XCTAssertTrue(modifiedOutput.completed)
        XCTAssertEqual(modifiedOutput.status, "SUCCESS")
        
        // Test DataClass.with()
        let originalData = DataClass(
            input: "original",
            output: "original",
            sessionID: "123",
            intermediateSteps: []
        )
        
        let modifiedData = originalData.with(
            input: "modified",
            output: "modified",
            sessionID: "456",
            intermediateSteps: [
                IntermediateStep(
                    agent: "test",
                    input: "test",
                    output: "test",
                    toolSteps: nil,
                    thought: nil,
                    runTime: 1.0,
                    usedCredits: 0.1
                )
            ]
        )
        
        XCTAssertEqual(modifiedData.input, "modified")
        XCTAssertEqual(modifiedData.output, "modified")
        XCTAssertEqual(modifiedData.sessionID, "456")
        XCTAssertEqual(modifiedData.intermediateSteps.count, 1)
        
        // Test IntermediateStep.with()
        let originalStep = IntermediateStep(
            agent: "original",
            input: "original",
            output: "original",
            toolSteps: nil,
            thought: nil,
            runTime: 1.0,
            usedCredits: 0.1
        )
        
        let modifiedStep = originalStep.with(
            agent: "modified",
            input: "modified",
            output: "modified",
            toolSteps: [
                ToolStep(
                    tool: "test",
                    input: "test",
                    output: "test",
                    runTime: nil,
                    usedCredits: nil
                )
            ],
            thought: "modified thought",
            runTime: 2.0,
            usedCredits: 0.2
        )
        
        XCTAssertEqual(modifiedStep.agent, "modified")
        XCTAssertEqual(modifiedStep.input, "modified")
        XCTAssertEqual(modifiedStep.output, "modified")
        XCTAssertEqual(modifiedStep.toolSteps?.count, 1)
        XCTAssertEqual(modifiedStep.thought, "modified thought")
        XCTAssertEqual(modifiedStep.runTime, 2.0)
        XCTAssertEqual(modifiedStep.usedCredits, 0.2)
        
        // Test ToolStep.with()
        let originalToolStep = ToolStep(
            tool: "original",
            input: "original",
            output: "original",
            runTime: nil,
            usedCredits: nil
        )
        
        let modifiedToolStep = originalToolStep.with(
            tool: "modified",
            input: "modified",
            output: "modified"
        )
        
        XCTAssertEqual(modifiedToolStep.tool, "modified")
        XCTAssertEqual(modifiedToolStep.input, "modified")
        XCTAssertEqual(modifiedToolStep.output, "modified")
        XCTAssertNil(modifiedToolStep.runTime)
        XCTAssertNil(modifiedToolStep.usedCredits)
    }
    
    func testJSONEncodingAndStringConversion() throws {
        let agentOutput = AgentOutput(
            completed: true,
            status: "SUCCESS",
            data: DataClass(
                input: "test",
                output: "test",
                sessionID: "123",
                intermediateSteps: []
            )
        )
        
        // Test jsonData() function
        let jsonData = try agentOutput.jsonData()
        XCTAssertNoThrow(try AgentOutput(data: jsonData))
        
        // Test jsonString() function
        let jsonString = try agentOutput.jsonString()
        XCTAssertNotNil(jsonString)
        if let jsonString = jsonString {
            XCTAssertNoThrow(try AgentOutput(jsonString))
        }
        
        // Test DataClass JSON conversion
        let dataClass = agentOutput.data
        XCTAssertNoThrow(try dataClass.jsonData())
        XCTAssertNotNil(try dataClass.jsonString())
        
        // Test IntermediateStep JSON conversion
        let step = IntermediateStep(
            agent: "test",
            input: "test",
            output: "test",
            toolSteps: nil,
            thought: nil,
            runTime: 1.0,
            usedCredits: 0.1
        )
        XCTAssertNoThrow(try step.jsonData())
        XCTAssertNotNil(try step.jsonString())
    }
}
