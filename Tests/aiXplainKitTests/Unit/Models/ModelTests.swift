import XCTest
@testable import aiXplainKit

final class ModelTests: XCTestCase {

    func test_model_resourcePath() {
        XCTAssertEqual(Model.resourcePath, "v2/models")
    }

    func test_model_from_dict() throws {
        let aix = try Aixplain(apiKey: "test-key")
        let dict: [String: Any] = [
            "id": "model-123",
            "name": "GPT-4o Mini",
            "description": "A small GPT model",
            "status": "onboarded",
            "host": "openai",
            "developer": "OpenAI",
            "functionType": "ai",
            "type": "model",
            "supportsStreaming": true,
            "connectionType": ["synchronous", "asynchronous"],
            "vendor": ["id": 42, "name": "OpenAI", "code": "openai"],
            "function": ["id": "TEXT_GENERATION"],
            "version": ["name": "1.0", "id": "v1"],
            "pricing": ["price": 0.001, "unitType": "token"]
        ]

        let model = try Model.from(dict: dict, context: aix)
        XCTAssertEqual(model.id, "model-123")
        XCTAssertEqual(model.name, "GPT-4o Mini")
        XCTAssertEqual(model.status, .onboarded)
        XCTAssertEqual(model.host, "openai")
        XCTAssertEqual(model.vendor?.code, "openai")
        XCTAssertEqual(model.function, .textGeneration)
        XCTAssertEqual(model.version?.id, "v1")
        XCTAssertEqual(model.supportsStreaming, true)
        XCTAssertFalse(model.isSyncOnly)
        XCTAssertTrue(model.isAsyncCapable)
    }

    func test_model_syncOnly() throws {
        let model = Model(id: "1")
        model.connectionType = ["synchronous"]
        XCTAssertTrue(model.isSyncOnly)
        XCTAssertFalse(model.isAsyncCapable)
    }

    func test_model_asyncCapable() throws {
        let model = Model(id: "1")
        model.connectionType = ["asynchronous"]
        XCTAssertFalse(model.isSyncOnly)
        XCTAssertTrue(model.isAsyncCapable)
    }

    func test_model_noConnectionType_defaultsAsync() {
        let model = Model(id: "1")
        XCTAssertFalse(model.isSyncOnly)
        XCTAssertTrue(model.isAsyncCapable)
    }

    func test_model_asAgentTool() throws {
        let aix = try Aixplain(apiKey: "test-key")
        let dict: [String: Any] = [
            "id": "model-abc",
            "name": "Test Model",
            "description": "A test model",
            "vendor": ["code": "openai"],
            "function": ["id": "TEXT_GENERATION"],
            "version": ["id": "v2"]
        ]
        let model = try Model.from(dict: dict, context: aix)
        let tool = model.asAgentTool()

        XCTAssertEqual(tool.id, "model-abc")
        XCTAssertEqual(tool.name, "Test Model")
        XCTAssertEqual(tool.type, .model)
        XCTAssertEqual(tool.supplier, "openai")
        XCTAssertEqual(tool.function, "TEXT_GENERATION")
        XCTAssertEqual(tool.assetId, "model-abc")
        XCTAssertNil(tool.actions)
    }

    func test_modelResult_from_dict() {
        let dict: [String: Any] = [
            "status": "SUCCESS",
            "completed": true,
            "data": "Hello, world!",
            "runTime": 1.5,
            "usedCredits": 0.001,
            "sessionId": "sess-123",
            "requestId": "req-456",
            "usage": [
                "prompt_tokens": 10,
                "completion_tokens": 20,
                "total_tokens": 30
            ]
        ]
        let result = ModelResult.from(dict)
        XCTAssertEqual(result.status, "SUCCESS")
        XCTAssertTrue(result.completed)
        XCTAssertEqual(result.runTime, 1.5)
        XCTAssertEqual(result.usedCredits, 0.001)
        XCTAssertEqual(result.sessionId, "sess-123")
        XCTAssertEqual(result.requestId, "req-456")
        XCTAssertEqual(result.usage?.totalTokens, 30)
    }
}
