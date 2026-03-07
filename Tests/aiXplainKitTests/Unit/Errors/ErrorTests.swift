import XCTest
@testable import aiXplainKit

final class ErrorTests: XCTestCase {

    // MARK: - AixplainError pattern matching

    func test_authError_patternMatches() {
        let error: AixplainError = .auth(.noCredentialFound)
        if case .auth(let authErr) = error {
            XCTAssertEqual(authErr, .noCredentialFound)
        } else {
            XCTFail("Expected .auth case")
        }
    }

    func test_apiError_patternMatches() {
        let error: AixplainError = .api(APIError(message: "Not found", statusCode: 404))
        if case .api(let apiErr) = error {
            XCTAssertEqual(apiErr.statusCode, 404)
            XCTAssertEqual(apiErr.message, "Not found")
        } else {
            XCTFail("Expected .api case")
        }
    }

    func test_validationError_patternMatches() {
        let error: AixplainError = .validation(ValidationError("bad input"))
        if case .validation(let valErr) = error {
            XCTAssertEqual(valErr.message, "bad input")
        } else {
            XCTFail("Expected .validation case")
        }
    }

    func test_timeoutError_patternMatches() {
        let error: AixplainError = .timeout(TimeoutError("timed out", pollingURL: "https://poll.url", timeout: 300))
        if case .timeout(let toErr) = error {
            XCTAssertEqual(toErr.message, "timed out")
            XCTAssertEqual(toErr.pollingURL, "https://poll.url")
            XCTAssertEqual(toErr.timeout, 300)
        } else {
            XCTFail("Expected .timeout case")
        }
    }

    func test_fileUploadError_patternMatches() {
        let error: AixplainError = .fileUpload(FileUploadError("too large", fileName: "big.mp4"))
        if case .fileUpload(let fuErr) = error {
            XCTAssertEqual(fuErr.message, "too large")
            XCTAssertEqual(fuErr.fileName, "big.mp4")
        } else {
            XCTFail("Expected .fileUpload case")
        }
    }

    func test_resourceError_patternMatches() {
        let error: AixplainError = .resource(ResourceError("context missing"))
        if case .resource(let resErr) = error {
            XCTAssertEqual(resErr.message, "context missing")
        } else {
            XCTFail("Expected .resource case")
        }
    }

    // MARK: - userMessage

    func test_userMessage_returnsReadableText() {
        let error: AixplainError = .api(APIError(message: "developer detail", error: "User-friendly error"))
        XCTAssertEqual(error.userMessage, "User-friendly error")
    }

    func test_userMessage_fallsBackToMessage() {
        let error: AixplainError = .api(APIError(message: "fallback msg", error: nil))
        XCTAssertEqual(error.userMessage, "fallback msg")
    }

    func test_userMessage_auth() {
        let error: AixplainError = .auth(.emptyKey)
        XCTAssertEqual(error.userMessage, "API key must not be empty.")
    }

    // MARK: - APIError factories

    func test_fromFailedOperation_extractsSupplierError() {
        let response: [String: Any] = [
            "status": "FAILED",
            "supplierError": "Model capacity exceeded",
            "statusCode": 500
        ]
        let error = APIError.fromFailedOperation(response)
        if case .api(let apiErr) = error {
            XCTAssertTrue(apiErr.message.contains("Model capacity exceeded"))
            XCTAssertEqual(apiErr.statusCode, 500)
            XCTAssertEqual(apiErr.error, "Model capacity exceeded")
        } else {
            XCTFail("Expected .api case")
        }
    }

    func test_fromFailedOperation_fallbackChain() {
        let response: [String: Any] = [
            "error_message": "secondary error",
            "statusCode": 422
        ]
        let error = APIError.fromFailedOperation(response)
        if case .api(let apiErr) = error {
            XCTAssertTrue(apiErr.message.contains("secondary error"))
        } else {
            XCTFail("Expected .api case")
        }
    }

    func test_fromFailedOperation_ultimateFallback() {
        let response: [String: Any] = ["status": "FAILED"]
        let error = APIError.fromFailedOperation(response)
        if case .api(let apiErr) = error {
            XCTAssertTrue(apiErr.message.contains("Operation failed"))
        } else {
            XCTFail("Expected .api case")
        }
    }

    func test_fromHTTPResponse_parsesJSON() {
        let json = """
        {"message": "Agent not found", "statusCode": 404, "error": "Not Found"}
        """.data(using: .utf8)!

        let error = APIError.fromHTTPResponse(data: json, statusCode: 404)
        if case .api(let apiErr) = error {
            XCTAssertEqual(apiErr.message, "Agent not found")
            XCTAssertEqual(apiErr.statusCode, 404)
            XCTAssertEqual(apiErr.error, "Not Found")
        } else {
            XCTFail("Expected .api case")
        }
    }

    func test_fromHTTPResponse_handlesNonJSON() {
        let body = "Internal Server Error".data(using: .utf8)!
        let error = APIError.fromHTTPResponse(data: body, statusCode: 500)
        if case .api(let apiErr) = error {
            XCTAssertEqual(apiErr.statusCode, 500)
            XCTAssertEqual(apiErr.message, "Internal Server Error")
        } else {
            XCTFail("Expected .api case")
        }
    }

    func test_fromHTTPResponse_extractsRequestId() {
        let json = """
        {"message": "error", "requestId": "req-abc-123"}
        """.data(using: .utf8)!

        let error = APIError.fromHTTPResponse(data: json, statusCode: 400)
        if case .api(let apiErr) = error {
            XCTAssertEqual(apiErr.requestId, "req-abc-123")
        } else {
            XCTFail("Expected .api case")
        }
    }

    // MARK: - APIError properties

    func test_apiError_requestId() {
        let err = APIError(message: "test", requestId: "rid-42")
        XCTAssertEqual(err.requestId, "rid-42")
    }

    func test_apiError_responseData() {
        let data: [String: Any] = ["key": "value"]
        let err = APIError(message: "test", responseData: data)
        XCTAssertEqual(err.responseData?["key"] as? String, "value")
    }

    func test_apiError_description() {
        let err = APIError(message: "test error", statusCode: 500, requestId: "rid")
        XCTAssertTrue(err.description.contains("500"))
        XCTAssertTrue(err.description.contains("rid"))
    }
}
