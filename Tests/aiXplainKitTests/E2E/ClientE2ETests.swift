import XCTest
@testable import aiXplainKit

/// End-to-end tests that hit the real aiXplain API.
/// Requires TEAM_API_KEY environment variable to be set.
final class ClientE2ETests: XCTestCase {

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

    // MARK: - Credential resolution E2E

    func test_credentialResolvesFromEnvironment() throws {
        let cred = try Credential.resolve()
        let headers = cred.authHeaders()
        XCTAssertNotNil(headers["x-api-key"], "TEAM_API_KEY should produce x-api-key header")
    }

    // MARK: - AixplainClient.get E2E

    func test_client_get_agentsList() async throws {
        let response = try await aix.client.requestRaw(method: .get, path: "sdk/agents")
        XCTAssertTrue(response.isSuccess, "GET /sdk/agents should return 2xx, got \(response.statusCode)")
        XCTAssertFalse(response.data.isEmpty)
    }

    func test_client_get_invalidEndpoint_throws() async {
        do {
            _ = try await aix.client.get("v2/nonexistent-endpoint-xyz")
            XCTFail("Should have thrown for invalid endpoint")
        } catch let error as AixplainError {
            if case .api(let apiErr) = error {
                XCTAssertTrue(apiErr.statusCode >= 400)
            }
        } catch {
            // Network or other errors are also acceptable
        }
    }

    // MARK: - Retry behavior E2E (indirect: confirm non-retryable errors throw immediately)

    func test_client_nonRetryableError_throwsImmediately() async {
        do {
            _ = try await aix.client.requestRaw(method: .delete, path: "v2/agents/nonexistent-id-xyz")
            XCTFail("DELETE nonexistent should throw")
        } catch {
            // 404 or 405 is expected and should NOT be retried (DELETE is not retryable)
        }
    }

    // MARK: - URL resolution E2E

    func test_client_absoluteURL_passesThrough() async throws {
        let url = aix.client.configuration.backendURL.absoluteString + "/sdk/agents"
        let response = try await aix.client.requestRaw(method: .get, path: url)
        XCTAssertTrue(response.isSuccess)
    }

    // MARK: - Response parsing E2E

    func test_client_post_modelsSearch() async throws {
        let body: [String: Any] = [
            "pageSize": 1,
            "pageNumber": 0,
            "sort": [[:]]
        ]
        let result = try await aix.client.post("v2/models/paginate", json: body)
        XCTAssertNotNil(result["results"], "Model search should return 'results' key")
        XCTAssertNotNil(result["total"], "Model search should return 'total' key")
    }
}
