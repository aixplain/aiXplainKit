import XCTest
@testable import aiXplainKit

final class RecordTests: XCTestCase {

    func test_textRecord() {
        let record = Record(text: "Hello world", attributes: ["lang": "en"], id: "r1")
        XCTAssertEqual(record.id, "r1")
        XCTAssertEqual(record.dataType, .text)
        XCTAssertEqual(record.value, "Hello world")
        XCTAssertEqual(record.attributes["lang"], "en")
        XCTAssertNil(record.uri)
    }

    func test_imageRecord() {
        let url = URL(string: "https://example.com/image.png")!
        let record = Record(imageURL: url, id: "r2")
        XCTAssertEqual(record.dataType, .image)
        XCTAssertEqual(record.uri, "https://example.com/image.png")
        XCTAssertEqual(record.value, "")
    }

    func test_record_codable_roundTrip() throws {
        let original = Record(text: "Test content", attributes: ["key": "value"], id: "r3")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Record.self, from: data)
        XCTAssertEqual(decoded.id, "r3")
        XCTAssertEqual(decoded.value, "Test content")
        XCTAssertEqual(decoded.dataType, .text)
        XCTAssertEqual(decoded.attributes["key"], "value")
    }

    func test_record_toDictionary() {
        let record = Record(text: "Hello", attributes: ["a": "b"], id: "r4")
        let dict = record.toDictionary()
        XCTAssertEqual(dict["data"] as? String, "Hello")
        XCTAssertEqual(dict["dataType"] as? String, "text")
        XCTAssertEqual(dict["document_id"] as? String, "r4")
    }
}

final class IndexFilterTests: XCTestCase {

    func test_filter_toDict() {
        let filter = IndexFilter(fieldName: "author", operation: .equals("Woolf"))
        let dict = filter.toDict()
        XCTAssertEqual(dict["field"], "author")
        XCTAssertEqual(dict["value"], "Woolf")
        XCTAssertEqual(dict["operator"], "==")
    }

    func test_filter_subscript() {
        let filter = IndexFilter["year", .greaterThan("1920")]
        XCTAssertEqual(filter.fieldName, "year")
        XCTAssertEqual(filter.operation.operatorString, ">")
    }

    func test_filter_allOperators() {
        let ops: [(FieldOperator, String)] = [
            (.equals("v"), "=="),
            (.notEquals("v"), "!="),
            (.contains("v"), "in"),
            (.notContains("v"), "not in"),
            (.greaterThan("v"), ">"),
            (.lessThan("v"), "<"),
            (.greaterThanOrEquals("v"), ">="),
            (.lessThanOrEquals("v"), "<="),
        ]
        for (op, expected) in ops {
            XCTAssertEqual(op.operatorString, expected)
        }
    }

    func test_filter_builder() {
        let filters = IndexFilter.builder()
            .where("author", .equals("Woolf"))
            .where("year", .greaterThan("1920"))
            .build()
        XCTAssertEqual(filters.count, 2)
        XCTAssertEqual(filters[0].fieldName, "author")
        XCTAssertEqual(filters[1].fieldName, "year")
    }
}

final class EmbeddingModelTests: XCTestCase {

    func test_predefinedModels_haveIds() {
        XCTAssertFalse(EmbeddingModel.openaiAda002.id.isEmpty)
        XCTAssertFalse(EmbeddingModel.bgeM3.id.isEmpty)
        XCTAssertFalse(EmbeddingModel.snowflakeArcticEmbedMLong.id.isEmpty)
    }

    func test_customModel() {
        let custom = EmbeddingModel.custom(id: "my-custom-model")
        XCTAssertEqual(custom.id, "my-custom-model")
    }

    func test_equality() {
        XCTAssertEqual(EmbeddingModel.openaiAda002, EmbeddingModel.openaiAda002)
        XCTAssertNotEqual(EmbeddingModel.openaiAda002, EmbeddingModel.bgeM3)
    }
}

final class IndexEngineTests: XCTestCase {

    func test_air_hasId() {
        XCTAssertFalse(IndexEngine.air.id.isEmpty)
    }

    func test_custom() {
        XCTAssertEqual(IndexEngine.custom(id: "abc").id, "abc")
    }
}

final class SearchHitTests: XCTestCase {

    func test_from_dict() {
        let dict: [String: Any] = [
            "document_id": "doc1",
            "score": 0.95,
            "data": "Hello world",
            "attributes": ["lang": "en"]
        ]
        let hit = SearchHit.from(dict)
        XCTAssertNotNil(hit)
        XCTAssertEqual(hit?.documentId, "doc1")
        XCTAssertEqual(hit?.score, 0.95)
        XCTAssertEqual(hit?.data, "Hello world")
    }

    func test_from_dict_missingId_returnsNil() {
        let dict: [String: Any] = ["score": 0.5]
        XCTAssertNil(SearchHit.from(dict))
    }
}

final class IndexUnitTests: XCTestCase {

    func test_index_init() {
        let index = Index(id: "idx-1", name: "Test Index")
        XCTAssertEqual(index.id, "idx-1")
        XCTAssertEqual(index.name, "Test Index")
    }

    func test_index_noContext_throws() async {
        let index = Index(id: "idx-1")
        do {
            _ = try await index.count()
            XCTFail("Should throw without context")
        } catch {
            // Expected
        }
    }
}
