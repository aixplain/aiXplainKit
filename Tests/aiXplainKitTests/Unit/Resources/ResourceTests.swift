import XCTest
@testable import aiXplainKit

final class PageTests: XCTestCase {

    func test_page_properties() {
        let page = Page(results: ["a", "b", "c"], pageNumber: 0, pageTotal: 2, total: 5)
        XCTAssertEqual(page.count, 3)
        XCTAssertEqual(page.total, 5)
        XCTAssertEqual(page.pageNumber, 0)
        XCTAssertEqual(page.pageTotal, 2)
        XCTAssertFalse(page.isEmpty)
    }

    func test_page_empty() {
        let page = Page<String>(results: [], pageNumber: 0, pageTotal: 0, total: 0)
        XCTAssertTrue(page.isEmpty)
        XCTAssertEqual(page.count, 0)
    }
}

final class RunResultTests: XCTestCase {

    func test_from_dict_completed() {
        let dict: [String: Any] = [
            "status": "SUCCESS",
            "completed": true,
            "data": ["output": "hello"]
        ]
        let result = RunResult.from(dict)
        XCTAssertEqual(result.status, "SUCCESS")
        XCTAssertTrue(result.completed)
        XCTAssertNotNil(result.data)
    }

    func test_from_dict_inProgress() {
        let dict: [String: Any] = [
            "status": "IN_PROGRESS",
            "completed": false,
            "url": "https://poll.url/123"
        ]
        let result = RunResult.from(dict)
        XCTAssertEqual(result.status, "IN_PROGRESS")
        XCTAssertFalse(result.completed)
        XCTAssertEqual(result.url, "https://poll.url/123")
    }

    func test_from_dict_withErrors() {
        let dict: [String: Any] = [
            "status": "FAILED",
            "completed": true,
            "errorMessage": "Something went wrong",
            "supplierError": "Model overloaded"
        ]
        let result = RunResult.from(dict)
        XCTAssertEqual(result.errorMessage, "Something went wrong")
        XCTAssertEqual(result.supplierError, "Model overloaded")
    }
}

final class AgentToolDictTests: XCTestCase {

    func test_codable_roundTrip() throws {
        let tool = AgentToolDict(
            id: "t1",
            name: "Test Tool",
            description: "A test",
            supplier: "aixplain",
            function: "text-generation",
            type: .model,
            version: "1.0",
            assetId: "t1"
        )

        let data = try JSONEncoder().encode(tool)
        let decoded = try JSONDecoder().decode(AgentToolDict.self, from: data)
        XCTAssertEqual(decoded.id, "t1")
        XCTAssertEqual(decoded.name, "Test Tool")
        XCTAssertEqual(decoded.type, .model)
        XCTAssertNil(decoded.actions)
    }

    func test_codable_withActions() throws {
        var tool = AgentToolDict(
            id: "t2",
            name: "Slack Tool",
            description: "Slack integration",
            supplier: "aixplain",
            function: "utilities",
            type: .tool,
            version: "1.0",
            assetId: "t2",
            actions: ["send_message", "upload_file"]
        )

        let data = try JSONEncoder().encode(tool)
        let decoded = try JSONDecoder().decode(AgentToolDict.self, from: data)
        XCTAssertEqual(decoded.actions, ["send_message", "upload_file"])
    }
}

final class AnyCodableTests: XCTestCase {

    func test_string() throws {
        let value = AnyCodable("hello")
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? String, "hello")
    }

    func test_int() throws {
        let value = AnyCodable(42)
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? Int, 42)
    }

    func test_double() throws {
        let value = AnyCodable(3.14)
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? Double, 3.14)
    }

    func test_bool() throws {
        let value = AnyCodable(true)
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? Bool, true)
    }

    func test_null() throws {
        let json = "null".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: json)
        XCTAssertTrue(decoded.value is NSNull)
    }

    func test_array() throws {
        let json = "[1, 2, 3]".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: json)
        let arr = decoded.value as? [Any]
        XCTAssertEqual(arr?.count, 3)
    }

    func test_dict() throws {
        let json = #"{"key": "value"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: json)
        let dict = decoded.value as? [String: Any]
        XCTAssertEqual(dict?["key"] as? String, "value")
    }
}

final class BaseResourceTests: XCTestCase {

    func test_isModified_newResource() {
        let resource = BaseResource(name: "test")
        XCTAssertTrue(resource.isModified)
    }

    func test_isModified_afterSaveState() {
        let resource = BaseResource(id: "1", name: "test")
        resource.updateSavedState()
        XCTAssertFalse(resource.isModified)
    }

    func test_isModified_afterMutation() {
        let resource = BaseResource(id: "1", name: "test")
        resource.updateSavedState()
        resource.name = "changed"
        XCTAssertTrue(resource.isModified)
    }

    func test_markAsDeleted() {
        let resource = BaseResource(id: "1", name: "test")
        resource.markAsDeleted()
        XCTAssertTrue(resource.isDeleted)
        XCTAssertNil(resource.id)
    }

    func test_ensureValidState_deletedThrows() {
        let resource = BaseResource(id: "1")
        resource.markAsDeleted()
        XCTAssertThrowsError(try resource.ensureValidState())
    }

    func test_ensureValidState_noIdThrows() {
        let resource = BaseResource()
        XCTAssertThrowsError(try resource.ensureValidState())
    }

    func test_ensureValidState_validPasses() {
        let resource = BaseResource(id: "123")
        XCTAssertNoThrow(try resource.ensureValidState())
    }

    func test_ensureContext_missingThrows() {
        let resource = BaseResource(id: "1")
        XCTAssertThrowsError(try resource.ensureContext())
    }

    func test_ensureContext_presentPasses() throws {
        let aix = try Aixplain(apiKey: "test-key")
        let resource = BaseResource(id: "1", context: aix)
        XCTAssertNoThrow(try resource.ensureContext())
    }

    func test_buildSavePayload() throws {
        let resource = BaseResource(id: "1", name: "Test", description: "Desc")
        let payload = try resource.buildSavePayload()
        XCTAssertEqual(payload["id"] as? String, "1")
        XCTAssertEqual(payload["name"] as? String, "Test")
        XCTAssertEqual(payload["description"] as? String, "Desc")
    }

    func test_clone_resetsId() throws {
        let aix = try Aixplain(apiKey: "test-key")
        let resource = BaseResource(id: "original", name: "Original", context: aix)
        let cloned = resource.clone(name: "Cloned")
        XCTAssertNil(cloned.id)
        XCTAssertEqual(cloned.name, "Cloned")
        XCTAssertNotNil(cloned.context)
    }

    func test_encodedId() {
        let resource = BaseResource(id: "abc/def")
        XCTAssertEqual(resource.encodedId, "abc%2Fdef")
    }
}

final class AssetStatusTests: XCTestCase {

    func test_decode_draft() throws {
        let json = #""draft""#.data(using: .utf8)!
        let status = try JSONDecoder().decode(AssetStatus.self, from: json)
        XCTAssertEqual(status, .draft)
    }

    func test_decode_onboarded() throws {
        let json = #""onboarded""#.data(using: .utf8)!
        let status = try JSONDecoder().decode(AssetStatus.self, from: json)
        XCTAssertEqual(status, .onboarded)
    }

    func test_decode_inProgress() throws {
        let json = #""in_progress""#.data(using: .utf8)!
        let status = try JSONDecoder().decode(AssetStatus.self, from: json)
        XCTAssertEqual(status, .inProgress)
    }
}

final class ResponseStatusTests: XCTestCase {

    func test_values() {
        XCTAssertEqual(ResponseStatus.inProgress.rawValue, "IN_PROGRESS")
        XCTAssertEqual(ResponseStatus.success.rawValue, "SUCCESS")
        XCTAssertEqual(ResponseStatus.failed.rawValue, "FAILED")
    }
}

final class ToolTypeTests: XCTestCase {

    func test_allCases() throws {
        for type in [ToolType.model, .pipeline, .utility, .tool] {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(ToolType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }
}
