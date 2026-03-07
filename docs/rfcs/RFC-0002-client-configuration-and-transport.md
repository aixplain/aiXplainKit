# RFC-0002: Client Configuration and Transport

| Field        | Value                                    |
|--------------|------------------------------------------|
| Status       | Implemented                              |
| Authors      |                                          |
| Created      | 2026-03-06                               |
| Depends on   | RFC-0001, RFC-0005 (errors)              |
| Depended by  | RFC-0003, RFC-0004, RFC-0007, RFC-0008, RFC-0009 |
| Priority     | P0 -- Foundation                         |

## Context

The current Swift SDK has a `Networking` class that provides raw HTTP methods (`get`, `post`, `put`, `delete`) with retry logic, and an `Endpoint` enum that builds URL paths. Each provider (`AgentProvider`, `ModelProvider`, etc.) creates its own `Networking` instance, manually builds headers via `buildHeader()`, and resolves base URLs through `APIKeyManager.shared`.

### How Python v2 structures client and entry point

**`AixplainClient` (`client.py`)** is the single HTTP client:

```python
class AixplainClient:
    def __init__(self, base_url, aixplain_api_key=None, team_api_key=None,
                 retry_total=5, retry_backoff_factor=0.1,
                 retry_status_forcelist=[500, 502, 503, 504]):
        self.base_url = base_url
        self.session = create_retry_session(...)
        self.session.headers.update(headers)

    def request_raw(self, method, path, **kwargs) -> requests.Response
    def request(self, method, path, **kwargs) -> dict     # auto .json()
    def get(self, path, **kwargs) -> dict
    def post(self, path, **kwargs) -> dict
    def request_stream(self, method, path, **kwargs) -> Response  # SSE
```

Key design decisions in Python v2:
- `request_raw` returns raw response; `request` auto-parses `.json()`.
- URL resolution: if `path` starts with `http://` or `https://`, use it directly (for polling URLs). Otherwise `urljoin(self.base_url, path)`.
- Error handling: non-OK responses are parsed into `APIError` with `status_code`, `response_data`, and `error` fields.
- Retry: uses `requests.adapters.Retry` with exponential backoff on `[500, 502, 503, 504]` for both GET and POST.
- Streaming: `request_stream` sets `stream=True` on the session request for SSE support.

**`Aixplain` (`core.py`)** is the entry point:

```python
class Aixplain:
    BACKEND_URL = "https://platform-api.aixplain.com"
    MODELS_RUN_URL = "https://models.aixplain.com/api/v2/execute"
    # PIPELINES_RUN_URL also exists but not used in Swift v2

    def __init__(self, api_key=None, backend_url=None, pipeline_url=None, model_url=None):
        self.api_key = api_key or os.getenv("TEAM_API_KEY") or ""
        self.backend_url = backend_url or os.getenv("BACKEND_URL") or self.BACKEND_URL
        self.init_client()
        self.init_resources()

    def init_client(self):
        self.client = AixplainClient(base_url=self.backend_url, team_api_key=self.api_key)

    def init_resources(self):
        # Dynamically creates bound subclasses so each resource has context
        self.Model = type("Model", (Model,), {"context": self})
        self.Agent = type("Agent", (Agent,), {"context": self})
        # ... Tool, Utility, Integration, Resource, Inspector, Debugger, APIKey
```

Key design decisions in Python v2 entry point:
- **One client, shared context** -- a single `AixplainClient` instance is created and injected into all resource types.
- **Resource binding** -- uses Python metaprogramming (`type()`) to create subclasses with `context` set as a class attribute. Each resource accesses `self.context.client` for HTTP calls.
- **Enums as attributes** -- `Function`, `Supplier`, `Language`, `License`, etc. are exposed on `Aixplain` for convenience (e.g., `aix.Function.TRANSLATION`).
- **Multiple URLs** -- `backend_url`, `model_url`, `pipeline_url` are separate configuration points, each with env var fallback.

### Problems in the current Swift SDK

1. **No unified client** -- each provider independently constructs networking, headers, and URLs.
2. **Endpoint fragmentation** -- `BACKEND_URL` and `MODELS_RUN_URL` live on `APIKeyManager`, while endpoint paths live on `Networking.Endpoint`.
3. **No dependency injection** -- providers use `APIKeyManager.shared` directly.
4. **Basic retry strategy** -- fixed delay, no exponential backoff, no status-code-aware retry list.
5. **No streaming support** -- Python v2 has `request_stream()` for SSE; Swift has none.
6. **No context injection** -- Python v2 binds resources to a context; Swift resources are unconnected.
7. **URL construction is manual** -- each provider manually concatenates `url.absoluteString + endpoint.path`.

## Decision

Introduce `AixplainClient` and `Aixplain` entry point that mirror the Python v2 architecture, adapted to Swift idioms (protocols, async/await, Sendable).

## API Shape

### AixplainClient (mirrors `client.py`)

```swift
/// Central HTTP client for the aiXplain platform.
/// Mirrors Python v2 `AixplainClient`: single session, shared headers, retry logic.
public final class AixplainClient: @unchecked Sendable {
    public let credential: Credential
    public let configuration: ClientConfiguration
    private let session: URLSession

    public init(credential: Credential, configuration: ClientConfiguration = .default) {
        self.credential = credential
        self.configuration = configuration
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfig.httpAdditionalHeaders = credential.authHeaders()
        self.session = URLSession(configuration: sessionConfig)
    }

    /// Mirrors Python `request_raw` -- returns raw response.
    public func requestRaw(
        method: HTTPMethod,
        path: String,
        body: Data? = nil,
        additionalHeaders: [String: String] = [:]
    ) async throws -> Response

    /// Mirrors Python `request` -- auto-decodes JSON dict.
    /// If path starts with "http://" or "https://", uses it directly (for polling URLs).
    /// Otherwise joins with `configuration.backendURL`.
    public func request(
        method: HTTPMethod,
        path: String,
        body: Data? = nil,
        additionalHeaders: [String: String] = [:]
    ) async throws -> [String: Any]

    /// Convenience: GET request. Mirrors Python `get()`.
    public func get(_ path: String) async throws -> [String: Any]

    /// Convenience: POST request. Mirrors Python `post()`.
    public func post(_ path: String, json: Encodable) async throws -> [String: Any]

    /// Streaming request for SSE. Mirrors Python `request_stream()`.
    public func requestStream(
        method: HTTPMethod,
        path: String,
        body: Data? = nil
    ) -> AsyncThrowingStream<Data, Error>
}

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
```

### URL resolution (mirrors Python v2 `request_raw`)

```swift
/// Mirrors Python v2: if path starts with http, use directly; else urljoin with base.
private func resolveURL(_ path: String) throws -> URL {
    if path.hasPrefix("http://") || path.hasPrefix("https://") {
        guard let url = URL(string: path) else { throw ClientError.invalidURL(path) }
        return url
    }
    guard let url = URL(string: path, relativeTo: configuration.backendURL) else {
        throw ClientError.invalidURL(path)
    }
    return url
}
```

### Retry strategy (mirrors Python v2 `create_retry_session`)

```swift
/// Retry configuration matching Python v2 defaults.
public struct RetryPolicy: Sendable {
    public var maxRetries: Int           // Python default: 5
    public var backoffFactor: Double     // Python default: 0.1
    public var retryableStatusCodes: Set<Int>  // Python default: [500, 502, 503, 504]

    public static let `default` = RetryPolicy(
        maxRetries: 5,
        backoffFactor: 0.1,
        retryableStatusCodes: [500, 502, 503, 504]
    )
}
```

Retry logic: on retryable status codes, wait `backoffFactor * 2^attempt` seconds, retry up to `maxRetries` times. Only GET and POST are retried (matching Python v2 `allowed_methods=frozenset({"GET", "POST"})`).

### Error handling (mirrors Python v2 `request_raw` error path)

```swift
// Mirrors Python v2:
// if not response.ok:
//     error_obj = response.json()
//     raise APIError(error_obj.get("message", ...), status_code=..., response_data=...)
private func handleErrorResponse(_ response: Response, url: URL, method: HTTPMethod) throws -> Never {
    if let errorDict = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
        throw AixplainError.api(APIError(
            message: errorDict["message"] as? String
                  ?? errorDict["error"] as? String
                  ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
            statusCode: errorDict["statusCode"] as? Int ?? response.statusCode,
            responseData: errorDict,
            error: errorDict["error"] as? String
        ))
    }
    throw AixplainError.api(APIError(
        message: String(data: response.data, encoding: .utf8) ?? "Unknown error",
        statusCode: response.statusCode,
        responseData: nil,
        error: nil
    ))
}
```

### ClientConfiguration (mirrors `Aixplain` class-level URLs in `core.py`)

```swift
/// Configurable transport settings.
/// Default URLs match Python v2 `Aixplain` class attributes in core.py.
public struct ClientConfiguration: Sendable {
    public var backendURL: URL
    public var modelsRunURL: URL
    public var timeoutInterval: TimeInterval
    public var retryPolicy: RetryPolicy
    public var userAgent: String

    public static let `default` = ClientConfiguration(
        backendURL: URL(string: "https://platform-api.aixplain.com")!,
        modelsRunURL: URL(string: "https://models.aixplain.com/api/v2/execute")!,
        timeoutInterval: 30,
        retryPolicy: .default,
        userAgent: "aiXplainKit-Swift/2.0"
    )
}
```

### Response wrapper

```swift
/// Unified response from the client.
public struct Response: Sendable {
    public let data: Data
    public let httpResponse: HTTPURLResponse
    public var statusCode: Int { httpResponse.statusCode }
    public var isSuccess: Bool { (200..<300).contains(statusCode) }

    public func decode<T: Decodable>(_ type: T.Type, using decoder: JSONDecoder = .init()) throws -> T {
        try decoder.decode(type, from: data)
    }

    public func json() throws -> [String: Any] {
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClientError.invalidJSON
        }
        return dict
    }
}
```

### Aixplain entry point (mirrors `core.py`)

```swift
/// Main entry point for the aiXplain Swift SDK v2.
/// Mirrors Python v2 `Aixplain` class in core.py.
///
/// Usage:
///   let aix = try Aixplain(apiKey: "your-team-key")
///   let agent = try await aix.Agent.get("agent-id")
///   let result = try await agent.run("Hello!")
public final class Aixplain: @unchecked Sendable {
    public let client: AixplainClient

    /// Resource types bound to this context (mirrors Python v2 init_resources).
    /// Each resource type holds a reference to this Aixplain instance.
    public let Agent: AgentResourceAccessor
    public let Model: ModelResourceAccessor
    // ... Tool, Utility, Integration, etc.

    // Enum conveniences (mirrors Python v2 `aix.Function.TRANSLATION`)
    public typealias Function = AIFunction
    public typealias Supplier = Supplier

    /// Convenience init matching Python v2:
    ///   `Aixplain(api_key=None, backend_url=None, ...)`
    public init(
        apiKey: String? = nil,
        backendURL: URL? = nil,
        modelURL: URL? = nil
    ) throws {
        let credential = try Credential.resolve(apiKey: apiKey)
        var config = ClientConfiguration.default
        if let url = backendURL { config.backendURL = url }
        if let url = modelURL { config.modelsRunURL = url }

        self.client = AixplainClient(credential: credential, configuration: config)

        // Bind resource accessors to this context
        self.Agent = AgentResourceAccessor(context: self)
        self.Model = ModelResourceAccessor(context: self)
    }
}

/// Mirrors Python v2 pattern where resources access `self.context.client`.
/// In Swift, each resource accessor holds a reference to the Aixplain context.
public struct AgentResourceAccessor {
    let context: Aixplain

    public func get(_ id: String) async throws -> Agent { ... }
    public func search(...) async throws -> Page<Agent> { ... }
    // ... create, list
}
```

### RESOURCE_PATH convention (mirrors Python v2)

Python v2 resources define their API path as a class-level constant:

```python
class Agent(BaseResource, ...):
    RESOURCE_PATH = "v2/agents"

class Model(BaseResource, ...):
    RESOURCE_PATH = "sdk/models"

class Tool(Model, ...):
    RESOURCE_PATH = "v2/tools"
```

Swift v2 will follow the same pattern:

```swift
protocol ResourcePathProviding {
    static var resourcePath: String { get }
}

extension Agent: ResourcePathProviding {
    static let resourcePath = "v2/agents"
}
```

## Shared Contracts

### Consumes from other RFCs

| Type | From RFC | How it's used |
|------|----------|---------------|
| `Credential` | RFC-0001 | Stored on `AixplainClient`; provides auth headers for every request |
| `AuthError` | RFC-0001 | Thrown by `Credential.resolve()` during `Aixplain` init |
| `AixplainError` | RFC-0005 | Thrown by `handleErrorResponse()` on non-2xx HTTP responses |
| `APIError` | RFC-0005 | Wrapped in `AixplainError.api()` for HTTP failures |

### Produces for other RFCs

| Type | Consumed by | How it's used |
|------|-------------|---------------|
| `AixplainClient` | RFC-0003 (Agent), RFC-0007 (Model), RFC-0008 (Tool), RFC-0009 (Index) | All resources call `context.client.get/post/request` for HTTP |
| `ClientConfiguration` | All resource RFCs | Provides `backendURL`, `modelsRunURL` for URL resolution |
| `Response` | All resource RFCs | Returned by client methods; decoded into resource-specific types |
| `Aixplain` | All resource RFCs | Entry point; holds `client` and resource accessors; set as `context` on resources |
| `HTTPMethod` | All resource RFCs | Used by `Runnable.buildRunPayload`, `Deletable.delete`, etc. |

## Implementation

Clean-slate: delete all v1 networking and provider code, replace with new client and entry point.

### Files to delete

- `Sources/aiXplainKit/Networking/Networking.swift`
- `Sources/aiXplainKit/Networking/Networking+Endpoint.swift`
- `Sources/aiXplainKit/Networking/Networking+Metadata.swift`
- `Sources/aiXplainKit/aiXplainKit.swift` (the `AiXplainKit.shared` singleton)
- All providers under `Sources/aiXplainKit/Provider/`

### Files to create

| File | Content |
|------|---------|
| `Sources/aiXplainKit/Client/AixplainClient.swift` | Core client with request/get/post/stream |
| `Sources/aiXplainKit/Client/ClientConfiguration.swift` | Configuration + RetryPolicy |
| `Sources/aiXplainKit/Client/Response.swift` | Response wrapper with decode/json |
| `Sources/aiXplainKit/Client/HTTPMethod.swift` | HTTP method enum |
| `Sources/aiXplainKit/Client/ClientError.swift` | Client-level errors |
| `Sources/aiXplainKit/Aixplain.swift` | Top-level entry point |

## Testing

- Unit: `AixplainClient` attaches correct auth headers from `Credential`.
- Unit: URL resolution -- relative paths join with `backendURL`, absolute URLs pass through.
- Unit: retry logic -- mock transport returning 500s retried up to `maxRetries`, then throws.
- Unit: retry logic -- only GET and POST are retried (matching Python v2).
- Unit: exponential backoff timing -- `backoffFactor * 2^attempt`.
- Unit: non-retryable status codes (400, 401, 403, 404) throw immediately.
- Unit: error response parsing -- JSON body with `message`/`error` fields mapped to `APIError`.
- Unit: `Response.decode()` success and failure paths.
- Unit: `Aixplain` init resolves credential and creates client.
- Unit: `Aixplain` init with explicit URLs overrides defaults.
- Integration: end-to-end GET to a health endpoint through `Aixplain`.

## Out of Scope

- WebSocket transport (no current platform need).
- Request interceptors / middleware chain (may revisit post-v2).
- Certificate pinning (platform uses standard TLS).
- Multipart upload support (handled by dedicated file upload utilities).

## Resolved Questions

1. **`AixplainClient` uses `URLSession` directly** -- simplest approach. Testability via `URLProtocol` stubbing.
2. **No environment variable overrides for URLs** -- only explicit parameters on `Aixplain.init()`. Credentials still resolve from env via `Credential.resolve()`.
3. **Switch to `/api/v2/execute`** -- confirmed. Default `modelsRunURL` is `https://models.aixplain.com/api/v2/execute`.
4. **`Aixplain` exposes enum conveniences** -- e.g., `aix.Function.translation`, `aix.Supplier.openai`, mirroring Python v2 `aix.Function.TRANSLATION`.
