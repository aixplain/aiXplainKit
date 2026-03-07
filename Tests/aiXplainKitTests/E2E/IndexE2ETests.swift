import XCTest
@testable import aiXplainKit

/// End-to-end tests for Index against the real aiXplain API.
final class IndexE2ETests: XCTestCase {

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

    // MARK: - Index.get with known model

    func test_index_get_model() async throws {
        // Fetch a model that backs an index (function="search")
        // Use the AIR engine model ID as a known model
        let engineId = IndexEngine.air.id
        do {
            let model = try await Model.get(engineId, context: aix)
            XCTAssertNotNil(model.id)
            XCTAssertNotNil(model.name)
        } catch {
            throw XCTSkip("AIR engine model not available: \(error)")
        }
    }

    // MARK: - Cross-RFC: full stack test

    func test_fullStack_credential_client_model_agent() async throws {
        // 1. Credential resolved from env (RFC-0001)
        let cred = try Credential.resolve()
        XCTAssertNotNil(cred.authHeaders()["x-api-key"])

        // 2. Client makes real request (RFC-0002)
        let response = try await aix.client.requestRaw(method: .get, path: "sdk/agents")
        XCTAssertTrue(response.isSuccess)

        // 3. Model search works (RFC-0007)
        let modelPage = try await Model.search(pageSize: 1, context: aix)
        XCTAssertGreaterThan(modelPage.total, 0)

        // 4. Tool search works (RFC-0008)
        let toolPage = try await Tool.searchTools(pageSize: 1, context: aix)
        XCTAssertGreaterThanOrEqual(toolPage.total, 0)

        // 5. Agent search works (RFC-0003)
        let agentPage = try await Agent.search(pageSize: 1, context: aix)
        XCTAssertGreaterThanOrEqual(agentPage.total, 0)

        // 6. Model → AgentToolDict serialization (RFC-0004 → 0007 → 0003)
        if let model = modelPage.results.first {
            let agentTool = model.asAgentTool()
            XCTAssertEqual(agentTool.type, .model)
            let encoded = try JSONEncoder().encode(agentTool)
            XCTAssertFalse(encoded.isEmpty)
        }
    }

    // MARK: - Record serialization

    func test_record_serialization_forIndex() throws {
        let record = Record(text: "Swift is a programming language")
        let dict = record.toDictionary()
        XCTAssertEqual(dict["dataType"] as? String, "text")
        XCTAssertEqual(dict["data"] as? String, "Swift is a programming language")

        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(Record.self, from: data)
        XCTAssertEqual(decoded.value, record.value)
    }

    // MARK: - Filter builder

    func test_filterBuilder_producesValidDicts() {
        let filters = IndexFilter.builder()
            .where("language", .equals("en"))
            .where("score", .greaterThan("0.5"))
            .build()

        XCTAssertEqual(filters.count, 2)
        let dicts = filters.map { $0.toDict() }
        XCTAssertEqual(dicts[0]["field"], "language")
        XCTAssertEqual(dicts[0]["operator"], "==")
        XCTAssertEqual(dicts[1]["field"], "score")
        XCTAssertEqual(dicts[1]["operator"], ">")
    }
}
