# RFC-0005: Error Model and Contract Tests

| Field        | Value                                    |
|--------------|------------------------------------------|
| Status       | Implemented                              |
| Authors      |                                          |
| Created      | 2026-03-06                               |
| Depends on   | RFC-0001 (AuthError)                     |
| Depended by  | RFC-0002, RFC-0003, RFC-0006, RFC-0007, RFC-0008, RFC-0009 |
| Priority     | P1 -- Post-Agents                        |

## Context

### Current Swift SDK errors

The Swift SDK defines error enums per module with massive overlap:

- **`ModelError`** (16 cases) -- `missingAPIKey`, `missingBackendURL`, `missingModelRunURL`, `invalidURL`, `failToDecodeRunResponse`, `pollingTimeoutOnModelResponse`, `failToDecodeModelOutputDuringPollingPhase`, `supplierError`, `failToGenerateAFilePayload`, `typeNotRecognizedWhileCreatingACombinedInput`, `inputEncodingError`, `noResponse`, `missingModelUtilityID`, `modelUtilityCreationError`, `failToCallModelExecuteFromUtility`, `unableToUpdateModelUtility`.
- **`AgentsError`** -- mirrors most of `ModelError` plus `invalidInput`, `errorOnDelete`, `errorOnUpdate`, `teamOfAgentsHasNoAgents`.
- **`PipelineError`** -- mirrors most of `ModelError` (9 shared cases).
- **`NetworkingError`** (4 cases) -- `invalidHttpResponse`, `invalidStatusCode`, `invalidURL`, `maxRetryReached`.
- **`FileError`** (4 cases) -- `fileSizeExceedsLimit`, `payloadGenerationFailed`, `couldNotGetTheS3PreSignedURL`, `bucketNameNotFound`.
- **`IndexErrors`** (1 case) -- `failedToCreateIndex(reason:)`.

### How Python v2 structures errors (`exceptions.py`)

Python v2 has a clean, flat hierarchy with exactly 5 error types:

```python
class AixplainV2Error(Exception):
    """Base exception for all v2 errors."""
    def __init__(self, message, details=None):
        self.message = message      # Can be str or List[str]
        self.details = details or {}

class ResourceError(AixplainV2Error):
    """Raised when resource operations fail."""
    pass

class APIError(AixplainV2Error):
    """Raised when API calls fail."""
    def __init__(self, message, status_code=0, response_data=None, error=None):
        self.status_code = status_code
        self.response_data = response_data or {}
        self.error = error or message

class ValidationError(AixplainV2Error):
    """Raised when validation fails."""
    pass

class TimeoutError(AixplainV2Error):
    """Raised when operations timeout."""
    pass

class FileUploadError(AixplainV2Error):
    """Raised when file upload operations fail."""
    pass
```

**Error factory (`exceptions.py`):**

```python
def create_operation_failed_error(response: dict) -> APIError:
    """Create an operation failed error from API response."""
    error_msg = (
        response.get("supplierError")
        or response.get("supplier_error")
        or response.get("error_message")
        or response.get("error")
        or "Operation failed"
    )
    return APIError(
        f"Operation failed: {error_msg}",
        status_code=response.get("statusCode", 0),
        response_data=response,
        error=error_msg,
    )
```

**How errors are raised in Python v2:**

In `client.py` (HTTP errors):
```python
if not response.ok:
    error_obj = response.json()
    raise APIError(
        error_obj.get("message", error_obj.get("error", response.text)),
        status_code=error_obj.get("statusCode", response.status_code),
        response_data=error_obj,
        error=error_obj.get("error", response.text),
    )
```

In `resource.py` (polling errors):
```python
# sync_poll timeout
raise TimeoutError(f"Operation timed out after {timeout} seconds")

# poll failure
if status == "FAILED":
    raise create_operation_failed_error(response)

# Resource state validation
raise ValidationError(f"{resource_name} has been deleted and cannot be used")
raise ValidationError(f"{resource_name} has not been saved yet. Call .save() first")

# Context missing
raise ResourceError("Context is required for resource operations")
```

### Problems in the current Swift SDK

1. **16+ duplicated cases** -- `missingAPIKey`, `missingBackendURL`, `invalidURL`, etc. repeated across 3 error types.
2. **No shared base** -- error handling must catch module-specific errors even for the same root cause.
3. **Missing context** -- `invalidStatusCode(statusCode: Int)` carries no URL, method, or response body.
4. **No error factory** -- Python v2 has `create_operation_failed_error(response)` that uniformly handles supplier errors.
5. **No contract tests** -- mock responses exist but there's no systematic validation of API response shapes.

## Decision

Introduce a unified `AixplainError` hierarchy aligned with the Python v2's 5-type system, plus a contract test framework.

## API Shape

### Error hierarchy (mirrors Python v2 `exceptions.py`)

```swift
/// Root error for all aiXplain SDK v2 operations.
/// Mirrors Python v2 `AixplainV2Error`.
public enum AixplainError: Error, Sendable, LocalizedError {
    case auth(AuthError)
    case api(APIError)
    case validation(ValidationError)
    case timeout(TimeoutError)
    case fileUpload(FileUploadError)
    case resource(ResourceError)

    /// User-facing message for display in UI.
    /// Distinct from `localizedDescription` which is developer-facing.
    public var userMessage: String {
        switch self {
        case .auth(let e): return e.errorDescription ?? "Authentication failed"
        case .api(let e): return e.userMessage
        case .validation(let e): return e.message
        case .timeout(let e): return e.message
        case .fileUpload(let e): return e.message
        case .resource(let e): return e.message
        }
    }
}

/// Mirrors Python v2 `APIError`.
/// Carries full HTTP context: status code, URL, response body, requestId.
public struct APIError: Error, Sendable {
    public let message: String
    public let statusCode: Int
    public let responseData: [String: Any]?
    public let error: String?
    public let requestId: String?  // For correlation with platform logs

    public init(
        message: String,
        statusCode: Int = 0,
        responseData: [String: Any]? = nil,
        error: String? = nil,
        requestId: String? = nil
    ) {
        self.message = message
        self.statusCode = statusCode
        self.responseData = responseData
        self.error = error ?? message
        self.requestId = requestId
    }

    /// User-facing message distinct from developer-facing localizedDescription.
    public var userMessage: String {
        if let err = error, !err.isEmpty { return err }
        return message
    }
}

/// AuthError is defined in RFC-0001 and re-exported here.
/// See RFC-0001 for the full definition.
/// case noCredentialFound, emptyKey, bothKeysProvided

/// Mirrors Python v2 `ValidationError`.
public struct ValidationError: Error, Sendable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }
}

/// Mirrors Python v2 `TimeoutError`.
public struct TimeoutError: Error, Sendable {
    public let message: String
    public let pollingURL: String?
    public let timeout: TimeInterval?

    public init(_ message: String, pollingURL: String? = nil, timeout: TimeInterval? = nil) {
        self.message = message
        self.pollingURL = pollingURL
        self.timeout = timeout
    }
}

/// Mirrors Python v2 `FileUploadError`.
public struct FileUploadError: Error, Sendable {
    public let message: String
    public let fileName: String?
}

/// Mirrors Python v2 `ResourceError`.
public struct ResourceError: Error, Sendable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }
}
```

### Error factory (mirrors Python v2 `create_operation_failed_error`)

```swift
/// Mirrors Python v2 `create_operation_failed_error(response)`.
/// Used when polling returns status == "FAILED".
extension APIError {
    public static func fromFailedOperation(_ response: [String: Any]) -> AixplainError {
        let errorMsg = (response["supplierError"] as? String)
            ?? (response["supplier_error"] as? String)
            ?? (response["error_message"] as? String)
            ?? (response["error"] as? String)
            ?? "Operation failed"

        return .api(APIError(
            message: "Operation failed: \(errorMsg)",
            statusCode: response["statusCode"] as? Int ?? 0,
            responseData: response,
            error: errorMsg
        ))
    }
}
```

### HTTP error construction (mirrors `client.py` error handling)

```swift
/// Mirrors Python v2 client.py error handling in request_raw().
extension APIError {
    public static func fromHTTPResponse(
        data: Data,
        statusCode: Int,
        url: URL,
        method: String
    ) -> AixplainError {
        if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return .api(APIError(
                message: errorObj["message"] as? String
                      ?? errorObj["error"] as? String
                      ?? "Request failed",
                statusCode: errorObj["statusCode"] as? Int ?? statusCode,
                responseData: errorObj,
                error: errorObj["error"] as? String
            ))
        }
        return .api(APIError(
            message: String(data: data, encoding: .utf8) ?? "Request failed",
            statusCode: statusCode,
            responseData: nil,
            error: nil
        ))
    }
}
```

### Mapping from old errors to new

| Old Swift Error | Python v2 Equivalent | New Swift v2 |
|-----------------|----------------------|------------|
| `ModelError.missingAPIKey` | `assert self.api_key` | `AixplainError.auth(.noCredentialFound)` |
| `ModelError.missingBackendURL` | N/A (config validation) | `AixplainError.validation("Backend URL not configured")` |
| `ModelError.invalidURL(url:)` | N/A (URL construction) | `AixplainError.validation("Invalid URL: ...")` |
| `ModelError.failToDecodeRunResponse` | `APIError(...)` | `AixplainError.resource("Failed to decode run response")` |
| `ModelError.pollingTimeoutOnModelResponse` | `TimeoutError(...)` | `AixplainError.timeout(TimeoutError(...))` |
| `ModelError.supplierError(error:)` | `create_operation_failed_error()` | `APIError.fromFailedOperation(response)` |
| `AgentsError.invalidInput(error:)` | `ValueError(...)` | `AixplainError.validation(ValidationError(...))` |
| `AgentsError.errorOnDelete` | `ResourceError(...)` | `AixplainError.resource(ResourceError(...))` |
| `NetworkingError.invalidStatusCode` | `APIError(status_code=...)` | `AixplainError.api(APIError(statusCode:...))` |
| `NetworkingError.maxRetryReached` | `TimeoutError(...)` | `AixplainError.timeout(TimeoutError("Max retries"))` |
| `FileError.fileSizeExceedsLimit` | `FileUploadError(...)` | `AixplainError.fileUpload(FileUploadError(...))` |

### Contract test pattern

```swift
/// Contract fixtures namespace for API response validation.
enum ContractFixtures {
    /// Known-good agent GET response from the API.
    static let agentGetResponse: Data = """
    {
        "id": "abc123",
        "name": "Test Agent",
        "status": "onboarded",
        "teamId": 42,
        "llmId": "669a63646eb56306647e1091",
        "createdAt": "2026-01-01T00:00:00.000Z",
        "updatedAt": "2026-01-01T00:00:00.000Z",
        "tools": [],
        "instructions": "You are a helpful assistant."
    }
    """.data(using: .utf8)!

    /// Known-good agent run result from polling.
    static let agentRunResult: Data = """
    {
        "status": "SUCCESS",
        "completed": true,
        "data": {
            "input": "Hello",
            "output": "Hi there!",
            "steps": [],
            "sessionId": "abc123_20260101120000"
        },
        "sessionId": "abc123_20260101120000",
        "usedCredits": 0.001,
        "runTime": 1.5
    }
    """.data(using: .utf8)!

    /// Known-good error response.
    static let errorResponse: Data = """
    {
        "message": "Agent not found",
        "statusCode": 404,
        "error": "Not Found"
    }
    """.data(using: .utf8)!

    /// Known-good supplier error during polling.
    static let supplierErrorResponse: Data = """
    {
        "status": "FAILED",
        "completed": true,
        "supplierError": "Model capacity exceeded",
        "errorMessage": "Supplier returned error"
    }
    """.data(using: .utf8)!
}

/// Contract tests validate that known API response shapes decode correctly.
final class AgentContractTests: XCTestCase {
    func test_agent_get_response_decodes() throws {
        let agent = try JSONDecoder().decode(Agent.self, from: ContractFixtures.agentGetResponse)
        XCTAssertEqual(agent.id, "abc123")
        XCTAssertEqual(agent.name, "Test Agent")
        XCTAssertEqual(agent.status, .onboarded)
    }

    func test_agent_run_result_decodes() throws {
        let result = try JSONDecoder().decode(AgentRunResult.self, from: ContractFixtures.agentRunResult)
        XCTAssertTrue(result.completed)
        XCTAssertEqual(result.sessionId, "abc123_20260101120000")
        XCTAssertEqual(result.usedCredits, 0.001)
    }

    func test_error_response_maps_to_api_error() throws {
        let json = try JSONSerialization.jsonObject(with: ContractFixtures.errorResponse) as! [String: Any]
        let error = APIError.fromHTTPResponse(
            data: ContractFixtures.errorResponse,
            statusCode: 404,
            url: URL(string: "https://api.example.com")!,
            method: "GET"
        )
        if case .api(let apiError) = error {
            XCTAssertEqual(apiError.statusCode, 404)
            XCTAssertEqual(apiError.message, "Agent not found")
        }
    }

    func test_supplier_error_maps_to_api_error() throws {
        let json = try JSONSerialization.jsonObject(with: ContractFixtures.supplierErrorResponse) as! [String: Any]
        let error = APIError.fromFailedOperation(json)
        if case .api(let apiError) = error {
            XCTAssertTrue(apiError.message.contains("Model capacity exceeded"))
        }
    }
}
```

## Shared Contracts

### Consumes from other RFCs

| Type | From RFC | How it's used |
|------|----------|---------------|
| `AuthError` | RFC-0001 | Wrapped as `AixplainError.auth(AuthError)` |

### Produces for other RFCs

| Type | Consumed by | How it's used |
|------|-------------|---------------|
| `AixplainError` | RFC-0002 (client error handling), RFC-0003 (agent run/poll), RFC-0007 (model run), RFC-0008 (tool run), RFC-0009 (index ops) | Root error type for all SDK operations |
| `APIError` | RFC-0002 (`handleErrorResponse`), RFC-0003 (`poll` failure), RFC-0007/0008 (run failures) | HTTP-level errors with status code and response body |
| `ValidationError` | RFC-0003 (`validateHistory`, `beforeRun`), RFC-0007 (`_validate_params`), RFC-0008 (action input validation) | Client-side validation before requests |
| `TimeoutError` | RFC-0003 (`syncPoll` timeout), RFC-0007 (model polling timeout) | Polling exceeded timeout budget |
| `ResourceError` | RFC-0003 (context missing), RFC-0004 (state validation) | Resource-level operation failures |
| `FileUploadError` | RFC-0009 (image record upload) | File upload failures |
| `APIError.fromFailedOperation()` | RFC-0003, RFC-0007 | Factory for supplier error responses during polling |
| `APIError.fromHTTPResponse()` | RFC-0002 | Factory for non-2xx HTTP responses |

## Implementation

Clean-slate: delete all v1 error types and build the unified error hierarchy from scratch.

### Files to delete

- `Sources/aiXplainKit/Errors/Agents+error.swift`
- `Sources/aiXplainKit/Errors/Model+Error.swift`
- `Sources/aiXplainKit/Errors/Pipeline+Error.swift`
- `Sources/aiXplainKit/Errors/Networking+Error.swift`
- `Sources/aiXplainKit/Errors/File+Error.swift`

### Files to create

| File | Content |
|------|---------|
| `Sources/aiXplainKit/Errors/AixplainError.swift` | Unified error enum |
| `Sources/aiXplainKit/Errors/APIError.swift` | HTTP error struct + factories |
| `Sources/aiXplainKit/Errors/ValidationError.swift` | Validation error |
| `Sources/aiXplainKit/Errors/TimeoutError.swift` | Timeout error |
| `Sources/aiXplainKit/Errors/FileUploadError.swift` | File upload error |
| `Sources/aiXplainKit/Errors/ResourceError.swift` | Resource error |
| `Tests/aiXplainKitTests/Contract/ContractFixtures.swift` | JSON fixtures |
| `Tests/aiXplainKitTests/Contract/AgentContractTests.swift` | Agent contract tests |
| `Tests/aiXplainKitTests/Contract/ErrorContractTests.swift` | Error mapping tests |

## Testing

- Unit: every `AixplainError` case can be constructed and pattern-matched.
- Unit: `APIError.fromHTTPResponse` correctly parses JSON error bodies.
- Unit: `APIError.fromHTTPResponse` handles non-JSON response bodies.
- Unit: `APIError.fromFailedOperation` extracts `supplierError` first, then fallbacks.
- Unit: `ValidationError` stores message string.
- Unit: `TimeoutError` stores polling URL and timeout value.
- Contract: `Agent` decoding from fixture JSON.
- Contract: `AgentRunResult` decoding from fixture JSON.
- Contract: error response → `APIError` mapping.
- Contract: supplier error response → `APIError` mapping.

## Out of Scope

- Error reporting / telemetry integration.
- Localized error descriptions beyond `LocalizedError` conformance.
- Rate-limiting (429) retry-after logic.
- Error recovery strategies.

## Resolved Questions

1. **`AixplainError` is an enum** -- exhaustive pattern matching over extensibility. All error cases are known at compile time.
2. **Contract test fixtures are auto-generated** from live API recordings. A test helper records real API responses and saves them as fixture JSON files.
3. **Errors carry `requestId`** -- `APIError` includes `requestId: String?` for correlation with platform logs.
4. **`AixplainError` provides `userMessage`** -- computed property returning a user-facing message distinct from `localizedDescription`.
