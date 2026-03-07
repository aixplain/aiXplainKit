import XCTest
@testable import aiXplainKit

final class ClientConfigurationTests: XCTestCase {

    func test_defaultConfiguration_hasCorrectURLs() {
        let config = ClientConfiguration.default
        XCTAssertEqual(config.backendURL.absoluteString, "https://platform-api.aixplain.com")
        XCTAssertEqual(config.modelsRunURL.absoluteString, "https://models.aixplain.com/api/v2/execute")
    }

    func test_defaultConfiguration_hasCorrectTimeout() {
        let config = ClientConfiguration.default
        XCTAssertEqual(config.timeoutInterval, 30)
    }

    func test_defaultConfiguration_hasCorrectRetryPolicy() {
        let config = ClientConfiguration.default
        XCTAssertEqual(config.retryPolicy.maxRetries, 5)
        XCTAssertEqual(config.retryPolicy.backoffFactor, 0.1)
        XCTAssertEqual(config.retryPolicy.retryableStatusCodes, [500, 502, 503, 504])
    }

    func test_customConfiguration() {
        let config = ClientConfiguration(
            backendURL: URL(string: "https://custom.api.com")!,
            modelsRunURL: URL(string: "https://custom.models.com/v2")!,
            timeoutInterval: 60,
            retryPolicy: RetryPolicy(maxRetries: 3),
            userAgent: "TestAgent/1.0"
        )
        XCTAssertEqual(config.backendURL.absoluteString, "https://custom.api.com")
        XCTAssertEqual(config.timeoutInterval, 60)
        XCTAssertEqual(config.retryPolicy.maxRetries, 3)
        XCTAssertEqual(config.userAgent, "TestAgent/1.0")
    }
}

final class RetryPolicyTests: XCTestCase {

    func test_defaultPolicy() {
        let policy = RetryPolicy.default
        XCTAssertEqual(policy.maxRetries, 5)
        XCTAssertEqual(policy.backoffFactor, 0.1)
        XCTAssertEqual(policy.retryableStatusCodes, [500, 502, 503, 504])
    }

    func test_delay_exponentialBackoff() {
        let policy = RetryPolicy(backoffFactor: 0.1)
        XCTAssertEqual(policy.delay(for: 0), 0.1, accuracy: 0.001)
        XCTAssertEqual(policy.delay(for: 1), 0.2, accuracy: 0.001)
        XCTAssertEqual(policy.delay(for: 2), 0.4, accuracy: 0.001)
        XCTAssertEqual(policy.delay(for: 3), 0.8, accuracy: 0.001)
    }

    func test_delay_customBackoff() {
        let policy = RetryPolicy(backoffFactor: 1.0)
        XCTAssertEqual(policy.delay(for: 0), 1.0, accuracy: 0.001)
        XCTAssertEqual(policy.delay(for: 1), 2.0, accuracy: 0.001)
        XCTAssertEqual(policy.delay(for: 2), 4.0, accuracy: 0.001)
    }
}

final class HTTPMethodTests: XCTestCase {

    func test_retryable_getAndPost() {
        XCTAssertTrue(HTTPMethod.get.isRetryable)
        XCTAssertTrue(HTTPMethod.post.isRetryable)
    }

    func test_notRetryable_putAndDelete() {
        XCTAssertFalse(HTTPMethod.put.isRetryable)
        XCTAssertFalse(HTTPMethod.delete.isRetryable)
    }

    func test_rawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
    }
}

final class ResponseTests: XCTestCase {

    private func makeResponse(json: String, statusCode: Int) -> Response {
        let data = json.data(using: .utf8)!
        let url = URL(string: "https://test.com")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return Response(data: data, httpResponse: httpResponse)
    }

    func test_isSuccess_200() {
        let response = makeResponse(json: "{}", statusCode: 200)
        XCTAssertTrue(response.isSuccess)
    }

    func test_isSuccess_201() {
        let response = makeResponse(json: "{}", statusCode: 201)
        XCTAssertTrue(response.isSuccess)
    }

    func test_isNotSuccess_404() {
        let response = makeResponse(json: "{}", statusCode: 404)
        XCTAssertFalse(response.isSuccess)
    }

    func test_isNotSuccess_500() {
        let response = makeResponse(json: "{}", statusCode: 500)
        XCTAssertFalse(response.isSuccess)
    }

    func test_json_parsesObject() throws {
        let response = makeResponse(json: #"{"key": "value"}"#, statusCode: 200)
        let dict = try response.json()
        XCTAssertEqual(dict["key"] as? String, "value")
    }

    func test_json_throwsOnArray() {
        let response = makeResponse(json: "[1,2,3]", statusCode: 200)
        XCTAssertThrowsError(try response.json())
    }

    func test_decode_success() throws {
        struct TestModel: Decodable { let name: String }
        let response = makeResponse(json: #"{"name": "test"}"#, statusCode: 200)
        let model = try response.decode(TestModel.self)
        XCTAssertEqual(model.name, "test")
    }

    func test_decode_failure() {
        struct TestModel: Decodable { let name: String }
        let response = makeResponse(json: #"{"wrong": "field"}"#, statusCode: 200)
        XCTAssertThrowsError(try response.decode(TestModel.self))
    }
}

final class AixplainInitTests: XCTestCase {

    func test_init_withExplicitKey() throws {
        let aix = try Aixplain(apiKey: "test-key-12345")
        XCTAssertEqual(aix.apiKey, "test-key-12345")
    }

    func test_init_defaultURLs() throws {
        let aix = try Aixplain(apiKey: "test-key")
        XCTAssertTrue(aix.backendURL.absoluteString.contains("platform-api.aixplain.com"))
        XCTAssertTrue(aix.modelURL.absoluteString.contains("api/v2/execute"))
    }

    func test_init_customURLs() throws {
        let aix = try Aixplain(
            apiKey: "test-key",
            backendURL: URL(string: "https://custom.api.com"),
            modelURL: URL(string: "https://custom.models.com/v2")
        )
        XCTAssertTrue(aix.backendURL.absoluteString.contains("custom.api.com"))
        XCTAssertTrue(aix.modelURL.absoluteString.contains("custom.models.com"))
    }

    func test_init_noKey_usesEnvironment() throws {
        // When TEAM_API_KEY is set in env, init succeeds without explicit key.
        // When no env key, it throws. Both are valid.
        if ProcessInfo.processInfo.environment["TEAM_API_KEY"] != nil
            || ProcessInfo.processInfo.environment["AIXPLAIN_API_KEY"] != nil {
            let aix = try Aixplain()
            XCTAssertFalse(aix.apiKey.isEmpty)
        } else {
            XCTAssertThrowsError(try Aixplain())
        }
    }
}

final class AixplainClientTests: XCTestCase {

    func test_client_createdWithCredential() throws {
        let cred = try Credential(scheme: .teamKey("test-key"))
        let client = AixplainClient(credential: cred)
        XCTAssertEqual(client.credential, cred)
    }

    func test_client_customConfiguration() throws {
        let cred = try Credential(scheme: .teamKey("test-key"))
        let config = ClientConfiguration(timeoutInterval: 60)
        let client = AixplainClient(credential: cred, configuration: config)
        XCTAssertEqual(client.configuration.timeoutInterval, 60)
    }
}
