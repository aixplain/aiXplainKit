# RFC-0007: Models v2 API

| Field        | Value                                    |
|--------------|------------------------------------------|
| Status       | Implemented                              |
| Authors      |                                          |
| Created      | 2026-03-06                               |
| Depends on   | RFC-0002, RFC-0004, RFC-0005             |
| Depended by  | RFC-0003, RFC-0008, RFC-0009             |
| Priority     | P0 -- Core resource                      |

## Context

### How Python v2 structures Models (`model.py`)

`Model` is the most feature-rich resource after `Agent`:

```python
@dataclass(repr=False)
class Model(
    BaseResource,
    SearchResourceMixin[ModelSearchParams, "Model"],
    GetResourceMixin[BaseGetParams, "Model"],
    RunnableResourceMixin[ModelRunParams, ModelResult],
    ToolableMixin,                                     # as_tool() for agent usage
):
    RESOURCE_PATH = "v2/models"
    RESPONSE_CLASS = ModelResult
```

Key capabilities:
- **Get/Search** via mixins with rich filters (functions, vendors, languages, host, developer, path).
- **Run** with sync/async routing based on `connection_type`.
- **Streaming** via `run_stream()` returning a `ModelResponseStreamer` (SSE parsing).
- **InputsProxy** for dynamic parameter access (`model.inputs.temperature = 0.7`).
- **Parameter validation** against the model's declared parameter schema.
- **`as_tool()`** to serialize the model for agent tool usage.
- **`Utility`** subclass for custom Python code functions.

**Model fields (from `model.py`):**

```python
service_name, status, host, developer, vendor (VendorInfo)
function (Function enum), pricing (Pricing), version (Version)
function_type, type, created_at, updated_at
supports_streaming, supports_byoc
connection_type  # ["synchronous"], ["asynchronous"], or both
attributes (List[Attribute]), params (List[Parameter])
```

**ModelResult:**

```python
class ModelResult(Result):
    details: Optional[List[Detail]]   # message, role, finish_reason
    run_time: Optional[float]
    used_credits: Optional[float]
    usage: Optional[Usage]            # prompt_tokens, completion_tokens, total_tokens
```

**Streaming:**

```python
class ModelResponseStreamer(Iterator[StreamChunk]):
    # Parses SSE: "data: {json}" lines
    # Yields StreamChunk(status, data) for each token
    # Handles [DONE] marker
    # Context manager support for cleanup

class StreamChunk:
    status: ResponseStatus
    data: str
```

**InputsProxy:**

```python
class InputsProxy:
    # Dict-like + dot notation access to model parameters
    # model.inputs.temperature = 0.7
    # model.inputs['temperature'] = 0.7
    # Type validation against Parameter.data_type
    # Reset to backend defaults
```

**Sync vs Async routing:**

```python
def run(self, **kwargs):
    if self.is_sync_only:
        return self._run_sync_v2(**effective_params)  # V2 direct
    else:
        return super().run(**effective_params)         # run_async + poll

def run_async(self, **kwargs):
    if self.is_sync_only:
        return self._run_async_v1(**effective_params)  # V1 fallback
    else:
        return super().run_async(**effective_params)    # V2 endpoint
```

**ModelSearchParams:**

```python
class ModelSearchParams(BaseSearchParams):
    functions, vendors, source_languages, target_languages
    is_finetunable, saved, status, q, host, developer, path
```

**Utility (`utility.py`):**

```python
class Utility(BaseResource, SearchResourceMixin, GetResourceMixin,
              DeleteResourceMixin, RunnableResourceMixin):
    RESOURCE_PATH = "sdk/utilities"
    code: str = ""
    inputs: List[str] = []
    utility_id: str = "custom_python_code"

    def __post_init__(self):
        # Auto-parses code via parse_code_decorated()
        # Validates description length > 10
        # Auto-saves on creation
```

### Current Swift SDK

- `Model` is a `Codable` class with `run()` and `polling()` that owns its own `Networking`.
- `UtilityModel` is a subclass with `update()`, `delete()`, `deploy()`.
- `ModelProvider` handles `get()`, `list()`, `listFunctions()`.
- `ModelInput` protocol with conformances on `String`, `URL`, `Data`, `Dictionary`.

## Decision

Replace `Model`, `UtilityModel`, and `ModelProvider` with a v2 `Model` resource following the Python v2 mixin architecture, including streaming and InputsProxy.

## API Shape

### Model

```swift
public final class Model: @unchecked Sendable {
    public override class var resourcePath: String { "v2/models" }

    // Core fields
    public var id: String?
    public var name: String?
    public var description: String?
    public var serviceName: String?
    public var status: AssetStatus?
    public var host: String?
    public var developer: String?
    public var vendor: VendorInfo?
    public var function: AIFunction?
    public var pricing: ModelPricing?
    public var version: ModelVersion?
    public var functionType: String?
    public var type: String? = "model"

    // Timestamps
    public private(set) var createdAt: String?
    public private(set) var updatedAt: String?

    // Capabilities
    public var supportsStreaming: Bool?
    public var supportsBYOC: Bool?
    public var connectionType: [String]?

    // Parameters
    public var attributes: [ModelAttribute]?
    public var params: [ModelParameter]?

    // Dynamic parameter proxy (mirrors Python v2 InputsProxy)
    public lazy var inputs: InputsProxy = InputsProxy(model: self)

    // Context
    weak var context: Aixplain?

    // Computed properties for sync/async routing
    public var isSyncOnly: Bool {
        guard let ct = connectionType else { return false }
        return ct.contains("synchronous") && !ct.contains("asynchronous")
    }

    public var isAsyncCapable: Bool {
        guard let ct = connectionType else { return true }
        return ct.contains("asynchronous")
    }
}
```

### Supporting types

```swift
public struct VendorInfo: Codable, Sendable {
    public let id: String?
    public let name: String?
    public let code: String?
}

public struct ModelPricing: Codable, Sendable {
    public let price: Double?
    public let unitType: String?
    public let unitTypeScale: String?
}

public struct ModelVersion: Codable, Sendable {
    public let name: String?
    public let id: String?
}

public struct ModelAttribute: Codable, Sendable {
    public let name: String
    public let code: String?
    public let value: AnyCodable?
}

public struct ModelParameter: Codable, Sendable {
    public let name: String
    public var required: Bool = false
    public var multipleValues: Bool = false
    public var isFixed: Bool = false
    public var dataType: String?
    public var dataSubType: String?
    public var values: [AnyCodable] = []
    public var defaultValues: [AnyCodable] = []
    public var availableOptions: [AnyCodable] = []
}
```

### ModelResult

```swift
public struct ModelResult: Sendable {
    public let status: String
    public let completed: Bool
    public let data: AnyCodable?
    public let url: String?
    public let errorMessage: String?
    public let supplierError: String?
    public let details: [ModelDetail]?
    public let runTime: Double?
    public let usedCredits: Double?
    public let usage: TokenUsage?
}

public struct TokenUsage: Codable, Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
}

public struct ModelDetail: Codable, Sendable {
    public let index: Int
    public let message: ModelMessage
    public let finishReason: String?
}

public struct ModelMessage: Codable, Sendable {
    public let role: String
    public let content: String
}
```

### Streaming

```swift
/// Mirrors Python v2 `ModelResponseStreamer`.
/// Parses SSE lines from the response stream.
public struct StreamChunk: Sendable {
    public let status: ResponseStatus
    public let data: String
}

extension Model {
    /// Stream model responses as an AsyncSequence.
    /// Mirrors Python v2 `model.run_stream(text="...")`.
    public func runStream(_ params: ModelRunParams) -> AsyncThrowingStream<StreamChunk, Error>
}
```

### InputsProxy

```swift
/// Mirrors Python v2 `InputsProxy`.
/// Uses `@dynamicMemberLookup` for dot-notation access: `model.inputs.temperature = 0.7`
@dynamicMemberLookup
public class InputsProxy {
    private weak var model: Model?
    private var values: [String: Any] = [:]

    public subscript(key: String) -> Any? {
        get { values[key] }
        set { values[key] = newValue }
    }

    /// Dot-notation access: `model.inputs.temperature`
    public subscript(dynamicMember member: String) -> Any? {
        get { values[member] }
        set { values[member] = newValue }
    }

    public func getAll() -> [String: Any]
    public func reset()
    public func resetParameter(_ name: String)
}
```

### Search

```swift
public struct ModelSearchParams {
    public var query: String?
    public var functions: [String]?
    public var vendors: [String]?
    public var sourceLanguages: [String]?
    public var targetLanguages: [String]?
    public var isFinetunable: Bool?
    public var host: String?
    public var developer: String?
    public var path: String?
    public var pageNumber: Int = 0
    public var pageSize: Int = 20
}

extension Model {
    public static func get(_ id: String, context: Aixplain) async throws -> Model
    public static func search(_ params: ModelSearchParams, context: Aixplain) async throws -> Page<Model>
}
```

### Run

```swift
extension Model {
    /// Run the model. Routes sync vs async based on connectionType.
    public func run(_ params: ModelRunParams) async throws -> ModelResult

    /// Run async -- returns polling URL.
    public func runAsync(_ params: ModelRunParams) async throws -> ModelResult

    /// as_tool() for agent usage.
    public func asAgentTool() -> AgentToolDict
}
```

### Utility

```swift
/// Mirrors Python v2 `Utility`.
public final class Utility: @unchecked Sendable {
    public static let resourcePath = "sdk/utilities"

    public var id: String?
    public var name: String?
    public var description: String?
    public var code: String = ""
    public var inputs: [String] = []

    weak var context: Aixplain?
}

extension Utility {
    public static func get(_ id: String, context: Aixplain) async throws -> Utility
    public static func search(_ params: UtilitySearchParams, context: Aixplain) async throws -> Page<Utility>
    public func save() async throws -> Utility
    public func delete() async throws
    public func run(_ data: String) async throws -> RunResult
}
```

## Shared Contracts

### Consumes from other RFCs

| Type | From RFC | How it's used |
|------|----------|---------------|
| `AixplainClient` | RFC-0002 | Via `context.client` for all HTTP calls |
| `Aixplain` | RFC-0002 | `context` reference; also provides `context.model_url` for run URL |
| `ClientConfiguration` | RFC-0002 | `modelsRunURL` used in `buildRunURL()` |
| `BaseResource` | RFC-0004 | Model conforms for save/clone/modification tracking |
| `Gettable` | RFC-0004 | Model conforms for `Model.get()` |
| `Searchable` | RFC-0004 | Model conforms for `Model.search()` returning `Page<Model>` |
| `Runnable` | RFC-0004 | Model conforms for `run()`/`runAsync()`/`poll()`/`syncPoll()` |
| `AgentToolConvertible` | RFC-0004 | Model conforms for `model.asAgentTool()` |
| `AgentToolDict` | RFC-0004 | Return type of `asAgentTool()` |
| `Page<T>` | RFC-0004 | Return type of `Model.search()` |
| `RunResult` | RFC-0004 | `ModelResult` extends `RunResult` with model-specific fields |
| `AssetStatus` | RFC-0004 | Model status field |
| `AIFunction` | RFC-0004 | Model function field |
| `Supplier` | RFC-0004 | Model vendor code |
| `ResponseStatus` | RFC-0004 | Used in `StreamChunk.status` |
| `AnyCodable` | RFC-0004 | Used in `ModelResult.data`, `ModelParameter.values` |
| `AixplainError` | RFC-0005 | Thrown on HTTP failures, validation errors |
| `ValidationError` | RFC-0005 | Thrown by parameter validation |
| `TimeoutError` | RFC-0005 | Thrown by `syncPoll()` |

### Produces for other RFCs

| Type | Consumed by | How it's used |
|------|-------------|---------------|
| `Model` | RFC-0003 (`agent.llmId` references a model), RFC-0008 (`Tool` extends `Model`), RFC-0009 (`Index` wraps a model) | Core AI model resource |
| `Model.asAgentTool()` | RFC-0003 (agent save payload) | Serializes model for agent tool list |
| `VendorInfo` | RFC-0008 (Tool inherits vendor info) | Supplier metadata |
| `ModelParameter` | RFC-0008 (Tool parameter validation) | Parameter schema |
| `InputsProxy` | RFC-0008 could reuse pattern | Dynamic parameter access pattern |
| `StreamChunk` | -- | Self-contained streaming type |
| `Utility` | -- | Self-contained custom code resource |

## Implementation

### Files to delete

- `Sources/aiXplainKit/Modules/Model/Model.swift`
- `Sources/aiXplainKit/Modules/Model/Utility.swift`
- `Sources/aiXplainKit/Modules/Model/Input/` (entire directory)
- `Sources/aiXplainKit/Modules/Model/Query/`
- `Sources/aiXplainKit/Provider/Model/` (entire directory)
- `Sources/aiXplainKit/Networking/ResponseDecoders/ModelExecuteResponse.swift`
- `Sources/aiXplainKit/Networking/ResponseDecoders/ModelOutput.swift`
- `Sources/aiXplainKit/Modules/Parameters/Model/`

### Files to create

| File | Content |
|------|---------|
| `Sources/aiXplainKit/Models/Model.swift` | Model class with get/search/run/runStream/asAgentTool |
| `Sources/aiXplainKit/Models/ModelResult.swift` | ModelResult, TokenUsage, ModelDetail |
| `Sources/aiXplainKit/Models/ModelSearchParams.swift` | Search parameters |
| `Sources/aiXplainKit/Models/ModelRunParams.swift` | Run parameters |
| `Sources/aiXplainKit/Models/InputsProxy.swift` | Dynamic parameter proxy |
| `Sources/aiXplainKit/Models/StreamChunk.swift` | SSE stream chunk |
| `Sources/aiXplainKit/Models/ModelTypes.swift` | VendorInfo, ModelPricing, ModelVersion, etc. |
| `Sources/aiXplainKit/Models/Utility.swift` | Utility resource |

## Testing

- Unit: `Model.get()` dispatches GET to `v2/models/{id}`.
- Unit: `Model.search()` builds correct filter payload with functions, vendors, languages.
- Unit: `Model.run()` routes to sync path when `isSyncOnly`.
- Unit: `Model.run()` routes to async+poll when `isAsyncCapable`.
- Unit: `InputsProxy` subscript get/set.
- Unit: `InputsProxy` type validation against `ModelParameter.dataType`.
- Unit: `Model.asAgentTool()` produces correct `AgentToolDict`.
- Unit: `ModelResult` decoding with `details`, `usage`, `runTime`, `usedCredits`.
- Unit: streaming SSE parsing -- `data: {json}`, `data: [DONE]`, blank line separators.
- Unit: `Utility` auto-save on creation.
- Contract: model GET response fixture.
- Contract: model run result fixture.

## Out of Scope

- Pipeline resource (separate RFC candidate).
- Fine-tuning API.
- BYOC (Bring Your Own Compute) configuration.

## Resolved Questions

1. **`InputsProxy` uses `@dynamicMemberLookup`** -- enables `model.inputs.temperature = 0.7` syntax.
2. **Streaming uses `AsyncThrowingStream<StreamChunk, Error>`** -- native Swift concurrency primitive. Returned by `model.runStream()`.
3. **Resource path is `"v2/models"`** -- matches Python v2. The old `"sdk/models"` path is dropped.
