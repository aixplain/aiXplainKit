# RFC-0004: Resources and Tools Schema Alignment

| Field        | Value                                    |
|--------------|------------------------------------------|
| Status       | Implemented                              |
| Authors      |                                          |
| Created      | 2026-03-06                               |
| Depends on   | RFC-0002                                 |
| Depended by  | RFC-0003, RFC-0006, RFC-0007, RFC-0008, RFC-0009 |
| Priority     | P0 -- Shared foundation                  |

## Context

### Current Swift SDK

The Swift SDK has overlapping concepts for assets:

- **`Tool`** -- struct with `id`, `type` (`.model` or `.pipiline` [sic]), `function`, `supplier`, `description`, `version`.
- **`CreateAgentTool`** -- enum: `.model(Model)`, `.pipeline(Pipeline)`, `.asset(assetID, functionString)`, `.utility(UtilityModel)`, `.tool(toolID, functionString)`.
- **`AgentUsableTool`** -- protocol that `Model`, `Pipeline`, `UtilityModel` conform to.
- **`Asset`** -- base type with `id`, `name`, `description`, `supplier`, `version`, `privacy`, `pricing`, `license`.
- **`Model`** -- extends `Asset` with execution capabilities.
- **`UtilityModel`** -- subclass of `Model` for custom code functions.
- File naming typos: `Dictonary+AgentInputable.swift`, `Suplier.swift`.

### How Python v2 structures resources and tools

**`BaseResource` (`resource.py`)** is the foundation for all resources:

```python
@dataclass
class BaseResource:
    context: Any       # Aixplain instance (excluded from serialization)
    RESOURCE_PATH: str # e.g., "v2/agents", "sdk/models"
    _saved_state: Optional[dict] = None

    id: Optional[str] = None
    name: Optional[str] = None
    description: Optional[str] = None
    path: Optional[str] = None  # e.g., "openai/whisper-large/groq"

    @property
    def is_modified(self) -> bool  # diff current vs _saved_state
    @property
    def is_deleted(self) -> bool

    def save(self, **kwargs) -> BaseResource       # create or update
    def clone(self, **kwargs) -> BaseResource       # deep copy with id=None
    def _action(self, method, action_paths) -> Response
    def build_save_payload(self, **kwargs) -> dict
    def _create(self, resource_path, payload)
    def _update(self, resource_path, payload)
```

**Mixins** provide CRUD capabilities:

```python
class SearchResourceMixin(Generic[SearchParamsT, ResourceT]):
    PAGINATE_PATH = "paginate"        # POST {RESOURCE_PATH}/paginate
    PAGINATE_METHOD = "post"
    PAGINATE_ITEMS_KEY = "results"
    PAGINATE_DEFAULT_PAGE_SIZE = 20

    @classmethod
    def search(cls, **kwargs) -> Page[ResourceT]

class GetResourceMixin(Generic[GetParamsT, ResourceT]):
    @classmethod
    def get(cls, id, host=None, **kwargs) -> ResourceT

class DeleteResourceMixin(Generic[DeleteParamsT, DeleteResultT]):
    def delete(self, **kwargs) -> DeleteResultT

class RunnableResourceMixin(Generic[RunParamsT, ResultT]):
    RUN_ACTION_PATH = "run"
    RESPONSE_CLASS = Result

    def run(self, **kwargs) -> ResultT          # sync: run_async + sync_poll
    def run_async(self, **kwargs) -> ResultT    # just POST, return polling URL
    def poll(self, poll_url) -> ResultT         # single poll
    def sync_poll(self, poll_url, **kwargs) -> ResultT  # loop until complete
    def on_poll(self, response, **kwargs)       # hook for progress updates
```

**`ToolableMixin` (`mixins.py`)** defines the `as_tool()` interface:

```python
class ToolableMixin(ABC):
    @abstractmethod
    def as_tool(self) -> ToolDict:
        # Returns: id, name, description, supplier, parameters,
        #          function, type, version, assetId

class ToolDict(TypedDict):
    id: str
    name: str
    description: str
    supplier: str
    parameters: Optional[List[ParameterDefinition]]
    function: Literal["utilities", "text-generation", ...]
    type: Literal["model", "pipeline", "utility", "tool"]
    version: str
    assetId: str
```

**`Model` (`model.py`)** is a `BaseResource` + `SearchResourceMixin` + `GetResourceMixin` + `RunnableResourceMixin` + `ToolableMixin`:

```python
@dataclass
class Model(BaseResource, SearchResourceMixin, GetResourceMixin,
            RunnableResourceMixin, ToolableMixin):
    RESOURCE_PATH = "sdk/models"

    function: Optional[str] = None
    supplier: Optional[str] = None
    version: Optional[str] = None
    # ... pricing, license, privacy, etc.

    def as_tool(self) -> ToolDict:
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "supplier": str(self.supplier_code),
            "parameters": self.get_parameters(),
            "function": str(self.function),
            "type": "model",
            "version": str(self.version),
            "assetId": self.id,
        }

    def run(self, *args, **kwargs) -> ModelResult:
        # Merges with dynamic attributes (InputsProxy)
        # Validates parameters
        # Dispatches via RunnableResourceMixin
```

**`Tool` (`tool.py`)** extends `Model` with integration/action support:

```python
@dataclass
class Tool(Model, DeleteResourceMixin, ActionMixin):
    RESOURCE_PATH = "v2/tools"
    RESPONSE_CLASS = ToolResult
    DEFAULT_INTEGRATION_ID = "686432941223092cb4294d3f"

    asset_id: Optional[str] = None
    integration: Optional[Union[Integration, str]] = None
    config: Optional[dict] = None
    code: Optional[str] = None
    allowed_actions: Optional[List[str]] = []

    def _create(self, resource_path, payload):
        # Creates via integration.connect(**payload) instead of standard POST
        self._ensure_integration(required=True)
        connection = self.integration.connect(**payload)
        self.id = connection.id

    def run(self, *args, **kwargs) -> ToolResult:
        # Requires action parameter
        # Falls back to single allowed action if only one
```

**`Page` (`resource.py`)** is a generic pagination container:

```python
class Page(Generic[ResourceT]):
    results: List[ResourceT]
    page_number: int
    page_total: int
    total: int
```

**`Result` (`resource.py`)** is the base run result:

```python
@dataclass
class Result:
    status: str
    completed: bool
    error_message: Optional[str]
    url: Optional[str]
    result: Optional[Any]
    supplier_error: Optional[str]
    data: Optional[Any]
    _raw_data: Optional[dict]
```

### Problems in the current Swift SDK

1. **No `BaseResource`** -- no shared protocol for CRUD, state tracking, or modification detection.
2. **No mixin pattern** -- each resource type implements its own fetch/save/delete logic.
3. **Vocabulary mismatch** -- `Tool`, `CreateAgentTool`, `AgentUsableTool`, `Asset` are related but named inconsistently.
4. **`ToolType` typo** -- `.pipiline` instead of `.pipeline`.
5. **No `as_tool()` pattern** -- Python v2 lets any `ToolableMixin` become a tool; Swift uses `CreateAgentTool` enum indirection.
6. **No `Page` type** -- list operations return raw arrays with no pagination metadata.
7. **No `Result` base type** -- each resource has its own output type with no shared structure.
8. **No modification tracking** -- no `is_modified`, `_saved_state`, or `clone()`.
9. **No `RESOURCE_PATH`** -- endpoints are defined in `Networking.Endpoint` instead of on the resource.
10. **File naming typos** -- `Suplier.swift`, `Dictonary+AgentInputable.swift`.

## Decision

Introduce a Swift protocol-based equivalent of Python v2's `BaseResource` + mixin system, adapted to Swift's type system (protocols instead of multiple inheritance).

## API Shape

### BaseResource class (mirrors Python v2 `BaseResource`)

```swift
/// Mirrors Python v2 `BaseResource`.
/// Base class -- all resources inherit from this.
/// Provides stored properties for state tracking that protocols can't.
public class BaseResource: @unchecked Sendable, Identifiable {
    public class var resourcePath: String { "" }

    public var id: String?
    public var name: String?
    public var description: String?
    public var context: Aixplain?

    // State tracking (mirrors Python v2 _saved_state)
    private var savedState: [String: Any]?
    private var _deleted: Bool = false

    public var isModified: Bool { /* diff current vs savedState */ }
    public var isDeleted: Bool { _deleted }

    public func save() async throws -> Self { ... }
    public func clone(name: String? = nil) -> Self { ... }
    public func buildSavePayload() throws -> [String: Any] { ... }

    func updateSavedState() { ... }
    func markAsDeleted() { ... }
}
```

### CRUD protocols (mirror Python v2 mixins)

```swift
/// Mirrors Python v2 `GetResourceMixin`.
public protocol Gettable: BaseResource {
    static func get(_ id: String, context: Aixplain) async throws -> Self
}

/// Mirrors Python v2 `SearchResourceMixin`.
public protocol Searchable: BaseResource {
    associatedtype SearchParams
    static var paginatePath: String { get }     // default: "paginate"
    static var paginateMethod: String { get }   // default: "post"
    static var paginateItemsKey: String { get } // default: "results"

    static func search(_ params: SearchParams, context: Aixplain) async throws -> Page<Self>
}

/// Mirrors Python v2 `DeleteResourceMixin`.
public protocol Deletable: BaseResource {
    func delete() async throws
}

/// Mirrors Python v2 `RunnableResourceMixin`.
public protocol Runnable: BaseResource {
    associatedtype RunParams
    associatedtype RunResult

    static var runActionPath: String { get }  // default: "run"

    func run(_ params: RunParams) async throws -> RunResult
    func runAsync(_ params: RunParams) async throws -> RunResult
    func poll(_ url: String) async throws -> RunResult
    func syncPoll(_ url: String, timeout: TimeInterval, waitTime: TimeInterval) async throws -> RunResult
    func onPoll(_ response: RunResult, params: RunParams)
    func buildRunPayload(_ params: RunParams) throws -> [String: Any]
}
```

### ToolableMixin (mirrors Python v2 `ToolableMixin`)

```swift
/// Mirrors Python v2 `ToolableMixin`.
/// Any resource conforming to this can be used as an agent tool.
public protocol AgentToolConvertible {
    func asAgentTool() -> AgentToolDict
}

/// Mirrors Python v2 `ToolDict`.
/// Used by RFC-0003 (Agents save payload), RFC-0007 (Model.asAgentTool),
/// RFC-0008 (Tool.asAgentTool with actions).
public struct AgentToolDict: Codable, Sendable {
    public var id: String
    public var name: String
    public var description: String
    public var supplier: String
    public var parameters: [AnyCodable]?
    public var function: String
    public var type: ToolType
    public var version: String
    public var assetId: String

    /// Tool-specific: which actions the agent is allowed to invoke.
    /// Set by RFC-0008 Tool.asAgentTool() when allowedActions is non-empty.
    public var actions: [String]?
}

/// Mirrors Python v2 ToolDict["type"] literal.
public enum ToolType: String, Codable, Sendable {
    case model
    case pipeline
    case utility
    case tool
}
```

### Page (mirrors Python v2 `Page`)

```swift
/// Generic pagination container.
/// Mirrors Python v2 `Page(Generic[ResourceT])`.
public struct Page<T>: Sendable {
    public let results: [T]
    public let pageNumber: Int
    public let pageTotal: Int
    public let total: Int
}
```

### Result (mirrors Python v2 `Result`)

```swift
/// Base result for all run operations.
/// Mirrors Python v2 `Result` dataclass.
public struct RunResult: Codable, Sendable {
    public let status: String
    public let completed: Bool
    public let errorMessage: String?
    public let url: String?
    public let result: AnyCodable?
    public let supplierError: String?
    public let data: AnyCodable?
}
```

### Shared types (owned by this RFC, consumed by others)

This RFC owns types that are used across multiple other RFCs. Ownership is defined here to avoid duplication.

```swift
/// Type-erased Codable wrapper for heterogeneous JSON values.
/// Used by: RFC-0004 (RunResult.data), RFC-0007 (ModelResult), RFC-0008 (Tool config).
public struct AnyCodable: Codable, Sendable { ... }

/// AI functions supported by the platform.
/// Used by: RFC-0007 (Model.function), RFC-0008 (Tool.function).
public enum AIFunction: String, Codable, Sendable {
    case search, translation, textGeneration, classification
    case speechRecognition, imageClassification, objectDetection
    case utilities
    // ...
}

/// AI model suppliers.
/// Used by: RFC-0007 (Model.vendor), RFC-0008 (Tool).
public enum Supplier: String, Codable, Sendable {
    case openai, anthropic, google, meta, huggingface, cohere, aixplain
    // ...
}

/// Response status for polling operations.
/// Used by: RFC-0003 (AgentRunResult), RFC-0007 (StreamChunk, ModelResult).
public enum ResponseStatus: String, Codable, Sendable {
    case inProgress = "IN_PROGRESS"
    case success = "SUCCESS"
    case failed = "FAILED"
}

/// Asset status values shared across all resources.
/// Used by: RFC-0003 (Agent), RFC-0007 (Model), RFC-0008 (Tool).
public enum AssetStatus: String, Codable, Sendable {
    case draft, hidden, scheduled, onboarding, onboarded
    case pending, failed, training, rejected
    case enabling, deleting, disabled, deleted
    case inProgress = "in_progress"
    case completed, canceling, canceled
}
```

### Model conformance (mirrors Python v2 `Model` class)

```swift
extension Model: Gettable, Searchable, Runnable, AgentToolConvertible {
    static let resourcePath = "sdk/models"
    static let runActionPath = "run"

    public func asAgentTool() -> AgentToolDict {
        AgentToolDict(
            id: id ?? "",
            name: name ?? "",
            description: description ?? "",
            supplier: supplier?.rawValue ?? "",
            parameters: getParameters(),
            function: function?.rawValue ?? "",
            type: .model,
            version: version ?? "",
            assetId: id ?? ""
        )
    }
}
```

### Tool resource (mirrors Python v2 `Tool` class)

```swift
/// Mirrors Python v2 `Tool(Model, DeleteResourceMixin, ActionMixin)`.
public final class Tool: @unchecked Sendable {
    public static let resourcePath = "v2/tools"
    static let defaultIntegrationId = "686432941223092cb4294d3f"

    // Inherits model fields + tool-specific:
    public var assetId: String?
    public var integration: IntegrationRef?  // String ID or Integration object
    public var config: [String: Any]?
    public var code: String?
    public var allowedActions: [String] = []

    // Tool creation goes through integration.connect()
    // instead of standard POST (mirrors Python v2 _create)
}

extension Tool: Gettable, Searchable, Deletable, Runnable, AgentToolConvertible {
    public func asAgentTool() -> AgentToolDict {
        var dict = super.asAgentTool()
        if !allowedActions.isEmpty {
            dict.actions = allowedActions
        }
        return dict
    }
}
```

## Implementation

Clean-slate: delete all v1 asset/tool types and build the unified resource system from scratch.

### Files to delete

- `Sources/aiXplainKit/Modules/Asset/` (entire directory, including `Suplier.swift`)
- `Sources/aiXplainKit/Modules/Agents/Tools/` (entire directory)

### Files to create

| File | Content |
|------|---------|
| `Sources/aiXplainKit/Resources/BaseResource.swift` | Protocol definition |
| `Sources/aiXplainKit/Resources/Protocols/Gettable.swift` | Get mixin |
| `Sources/aiXplainKit/Resources/Protocols/Searchable.swift` | Search/paginate mixin |
| `Sources/aiXplainKit/Resources/Protocols/Deletable.swift` | Delete mixin |
| `Sources/aiXplainKit/Resources/Protocols/Runnable.swift` | Run mixin |
| `Sources/aiXplainKit/Resources/AgentToolConvertible.swift` | Tool conversion protocol |
| `Sources/aiXplainKit/Resources/AgentToolDict.swift` | Tool dict struct |
| `Sources/aiXplainKit/Resources/Page.swift` | Pagination container |
| `Sources/aiXplainKit/Resources/RunResult.swift` | Base run result |
| `Sources/aiXplainKit/Enums/AnyCodable.swift` | Type-erased Codable wrapper |
| `Sources/aiXplainKit/Enums/AIFunction.swift` | AI function enum |
| `Sources/aiXplainKit/Enums/Supplier.swift` | Supplier enum |
| `Sources/aiXplainKit/Enums/AssetStatus.swift` | Asset status enum |
| `Sources/aiXplainKit/Enums/ResponseStatus.swift` | Response status enum |

## Shared Contracts

This RFC is the **interface hub** for the entire SDK. Every other RFC consumes types defined here.

| Type | Defined in | Consumed by |
|------|-----------|-------------|
| `BaseResource` | `Resources/BaseResource.swift` | RFC-0003 (Agent), RFC-0007 (Model), RFC-0008 (Tool), RFC-0009 (Index) |
| `Gettable` | `Resources/Protocols/Gettable.swift` | RFC-0003, RFC-0007, RFC-0008, RFC-0009 |
| `Searchable` | `Resources/Protocols/Searchable.swift` | RFC-0003, RFC-0007, RFC-0008 |
| `Deletable` | `Resources/Protocols/Deletable.swift` | RFC-0003, RFC-0007, RFC-0008 |
| `Runnable` | `Resources/Protocols/Runnable.swift` | RFC-0003, RFC-0007, RFC-0008 |
| `AgentToolConvertible` | `Resources/AgentToolConvertible.swift` | RFC-0007 (Model), RFC-0008 (Tool) |
| `AgentToolDict` | `Resources/AgentToolDict.swift` | RFC-0003 (save payload), RFC-0007, RFC-0008 |
| `Page<T>` | `Resources/Page.swift` | RFC-0003, RFC-0007, RFC-0008, RFC-0009 |
| `RunResult` | `Resources/RunResult.swift` | RFC-0007 (ModelResult extends), RFC-0003 (AgentRunResult extends) |
| `AnyCodable` | `Enums/AnyCodable.swift` | RFC-0003, RFC-0007, RFC-0008, RFC-0009 |
| `AssetStatus` | `Enums/AssetStatus.swift` | RFC-0003, RFC-0007, RFC-0008 |
| `AIFunction` | `Enums/AIFunction.swift` | RFC-0007, RFC-0008 |
| `Supplier` | `Enums/Supplier.swift` | RFC-0007, RFC-0008 |
| `ResponseStatus` | `Enums/ResponseStatus.swift` | RFC-0003, RFC-0007 |
| `ToolType` | `Resources/AgentToolDict.swift` | RFC-0007, RFC-0008 |

## Testing

- Unit: `Model.asAgentTool()` produces correct `AgentToolDict` with all fields.
- Unit: `Page<Agent>` correctly holds results, pageNumber, pageTotal, total.
- Unit: `RunResult` decoding from fixture JSON with all field variants.
- Unit: `BaseResource.isModified` detects changes after property mutation.
- Unit: `BaseResource.clone()` produces copy with `id = nil`.
- Unit: `ToolType` decoding handles all valid values (`model`, `pipeline`, `utility`, `tool`).

## Out of Scope

- Tool actions and integration resolution (`ActionMixin`, `Integration.connect()`) -- separate RFC.
- Dynamic parameter inputs (`InputsProxy` equivalent) -- deferred.
- Index/search resource alignment -- deferred.
- File/Resource upload (`file.py`) -- deferred.

## Resolved Questions

1. **`BaseResource` is a base class** (not a protocol) -- provides `_saved_state`, `isModified`, `isDeleted`, `save()`/`clone()` with stored properties. All resources (`Agent`, `Model`, `Tool`, `Index`) inherit from it.
2. **Protocol extensions with default implementations** -- `Gettable`, `Searchable`, `Deletable`, `Runnable` provide default behavior via extensions. Resources override only what differs (e.g., `buildRunPayload`, `buildSavePayload`). Lowest maintenance burden.
3. **Simple `AnyCodable` wrapper** -- no third-party dependency. A lightweight struct wrapping `Any` with `Codable` conformance via `JSONSerialization`.
