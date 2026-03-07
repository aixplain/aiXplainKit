import XCTest
@testable import aiXplainKit

final class CredentialTests: XCTestCase {

    // MARK: - Credential.resolve (explicit key)

    func test_resolve_explicitKey_returnsTeamKey() throws {
        let cred = try Credential.resolve(apiKey: "abc123")
        XCTAssertEqual(cred.scheme, .teamKey("abc123"))
    }

    func test_resolve_explicitKey_ignoresEnvironment() throws {
        let env = ["TEAM_API_KEY": "env-key", "AIXPLAIN_API_KEY": "aix-key"]
        let cred = try Credential.resolve(apiKey: "explicit", environment: env)
        XCTAssertEqual(cred.scheme, .teamKey("explicit"))
    }

    // MARK: - Credential.resolve (environment)

    func test_resolve_teamKeyFromEnv() throws {
        let env = ["TEAM_API_KEY": "team-env-key"]
        let cred = try Credential.resolve(environment: env)
        XCTAssertEqual(cred.scheme, .teamKey("team-env-key"))
    }

    func test_resolve_aixplainKeyFromEnv() throws {
        let env = ["AIXPLAIN_API_KEY": "aix-env-key"]
        let cred = try Credential.resolve(environment: env)
        XCTAssertEqual(cred.scheme, .aixplainKey("aix-env-key"))
    }

    func test_resolve_teamKeyTakesPrecedenceOverAixplainKey() throws {
        let env = ["TEAM_API_KEY": "team", "AIXPLAIN_API_KEY": "aix"]
        let cred = try Credential.resolve(environment: env)
        XCTAssertEqual(cred.scheme, .teamKey("team"))
    }

    func test_resolve_noKey_throwsNoCredentialFound() {
        XCTAssertThrowsError(try Credential.resolve(environment: [:])) { error in
            XCTAssertEqual(error as? AuthError, .noCredentialFound)
        }
    }

    func test_resolve_emptyExplicitKey_fallsToEnv() throws {
        let env = ["TEAM_API_KEY": "fallback"]
        let cred = try Credential.resolve(apiKey: "", environment: env)
        XCTAssertEqual(cred.scheme, .teamKey("fallback"))
    }

    func test_resolve_emptyEnvKeys_throwsNoCredentialFound() {
        let env = ["TEAM_API_KEY": "", "AIXPLAIN_API_KEY": ""]
        XCTAssertThrowsError(try Credential.resolve(environment: env)) { error in
            XCTAssertEqual(error as? AuthError, .noCredentialFound)
        }
    }

    // MARK: - Credential init validation

    func test_init_emptyKey_throws() {
        XCTAssertThrowsError(try Credential(scheme: .teamKey(""))) { error in
            XCTAssertEqual(error as? AuthError, .emptyKey)
        }
    }

    func test_init_whitespaceOnlyKey_throws() {
        XCTAssertThrowsError(try Credential(scheme: .teamKey("   "))) { error in
            XCTAssertEqual(error as? AuthError, .emptyKey)
        }
    }

    func test_init_validKey_succeeds() throws {
        let cred = try Credential(scheme: .teamKey("valid-key"))
        XCTAssertEqual(cred.scheme, .teamKey("valid-key"))
    }

    // MARK: - authHeaders

    func test_teamKey_producesCorrectHeaders() throws {
        let cred = try Credential(scheme: .teamKey("my-team-key"))
        let headers = cred.authHeaders()
        XCTAssertEqual(headers["x-api-key"], "my-team-key")
        XCTAssertNil(headers["x-aixplain-key"])
        XCTAssertEqual(headers["Content-Type"], "application/json")
    }

    func test_aixplainKey_producesCorrectHeaders() throws {
        let cred = try Credential(scheme: .aixplainKey("my-aix-key"))
        let headers = cred.authHeaders()
        XCTAssertEqual(headers["x-aixplain-key"], "my-aix-key")
        XCTAssertNil(headers["x-api-key"])
        XCTAssertEqual(headers["Content-Type"], "application/json")
    }

    func test_headers_alwaysIncludeContentType() throws {
        let cred = try Credential(scheme: .teamKey("key"))
        let headers = cred.authHeaders()
        XCTAssertEqual(headers["Content-Type"], "application/json")
    }

    // MARK: - Codable

    func test_credential_roundTrips_via_codable() throws {
        let original = try Credential(scheme: .teamKey("codable-test"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Credential.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_credential_aixplainKey_roundTrips_via_codable() throws {
        let original = try Credential(scheme: .aixplainKey("aix-codable"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Credential.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - Equatable

    func test_sameCredentials_areEqual() throws {
        let a = try Credential(scheme: .teamKey("same"))
        let b = try Credential(scheme: .teamKey("same"))
        XCTAssertEqual(a, b)
    }

    func test_differentCredentials_areNotEqual() throws {
        let a = try Credential(scheme: .teamKey("one"))
        let b = try Credential(scheme: .teamKey("two"))
        XCTAssertNotEqual(a, b)
    }

    func test_differentSchemes_areNotEqual() throws {
        let a = try Credential(scheme: .teamKey("key"))
        let b = try Credential(scheme: .aixplainKey("key"))
        XCTAssertNotEqual(a, b)
    }
}
