import XCTest
@testable import aiXplainKit

/// End-to-end tests for Model that hit the real aiXplain API.
final class ModelE2ETests: XCTestCase {

    private var aix: Aixplain!

    override func setUp() async throws {
        guard ProcessInfo.processInfo.environment["TEAM_API_KEY"] != nil else {
            throw XCTSkip("TEAM_API_KEY not set -- skipping E2E tests")
        }
        let backendURL = ProcessInfo.processInfo.environment["BACKEND_URL"]
            .flatMap { URL(string: $0) }
        let modelURL = ProcessInfo.processInfo.environment["MODELS_RUN_URL"]
            .flatMap { URL(string: $0) }
        aix = try Aixplain(backendURL: backendURL, modelURL: modelURL)
    }

    // MARK: - Search

    func test_model_search_returnsResults() async throws {
        let page = try await Model.search(pageSize: 5, context: aix)
        XCTAssertGreaterThan(page.total, 0, "There should be models in the platform")
        XCTAssertFalse(page.isEmpty)
        XCTAssertLessThanOrEqual(page.count, 5)

        let firstModel = page.results.first!
        XCTAssertNotNil(firstModel.id)
        XCTAssertNotNil(firstModel.name)
    }

    // MARK: - Get

    func test_model_get_byId() async throws {
        let page = try await Model.search(pageSize: 1, context: aix)
        guard let firstModel = page.results.first, let modelId = firstModel.id else {
            throw XCTSkip("No models found to test get()")
        }

        let fetched = try await Model.get(modelId, context: aix)
        XCTAssertEqual(fetched.id, modelId)
        XCTAssertNotNil(fetched.name)
        XCTAssertFalse(fetched.isModified, "Freshly fetched model should not be modified")
    }

    // MARK: - Run

    func test_model_run_textGeneration() async throws {
        // GPT-4o Mini (known model ID from Python v2 DEFAULT_LLM)
        let modelId = "669a63646eb56306647e1091"

        let model: Model
        do {
            model = try await Model.get(modelId, context: aix)
        } catch {
            throw XCTSkip("Default LLM model not available: \(error)")
        }

        let result = try await model.run(text: "Say hello in one word")
        XCTAssertEqual(result.status, "SUCCESS")
        XCTAssertTrue(result.completed)
        XCTAssertNotNil(result.data, "Model should return output data")
    }

    // MARK: - asAgentTool

    func test_model_asAgentTool_realModel() async throws {
        let page = try await Model.search(pageSize: 1, context: aix)
        guard let model = page.results.first else {
            throw XCTSkip("No models found")
        }

        let tool = model.asAgentTool()
        XCTAssertEqual(tool.id, model.id)
        XCTAssertEqual(tool.type, .model)
        XCTAssertFalse(tool.name.isEmpty)
    }
}
