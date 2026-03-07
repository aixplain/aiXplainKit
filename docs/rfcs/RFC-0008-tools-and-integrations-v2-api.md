# RFC-0008: Tools and Integrations v2 API

| Field        | Value                                    |
|--------------|------------------------------------------|
| Status       | Implemented                              |
| Authors      |                                          |
| Created      | 2026-03-06                               |
| Depends on   | RFC-0002, RFC-0004, RFC-0005, RFC-0007   |
| Depended by  | RFC-0003 (agent operations depend on tools) |
| Priority     | **P0 -- Critical for Agents**            |

> Tools are the primary mechanism for extending agent capabilities. Without tools, agents cannot interact with external services, run models, or execute custom code. This RFC is tightly coupled with RFC-0003 (Agents).

## Context

### How Python v2 structures Tools (`tool.py`)

`Tool` extends `Model` and adds integration/action capabilities:

```python
@dataclass(repr=False)
class Tool(Model, DeleteResourceMixin, ActionMixin):
    RESOURCE_PATH = "v2/tools"
    RESPONSE_CLASS = ToolResult
    DEFAULT_INTEGRATION_ID = "686432941223092cb4294d3f"  # Script integration

    asset_id: Optional[str]
    integration: Optional[Union[Integration, str]]  # Integration object or ID
    config: Optional[dict]
    code: Optional[str]
    allowed_actions: Optional[List[str]] = []
```

Key capabilities:
- **Creation via Integration** -- `Tool._create()` calls `integration.connect()` instead of standard POST. The integration creates the tool and returns its ID.
- **Actions** -- tools expose named actions via `ActionMixin.list_actions()` and `list_inputs()`.
- **`allowed_actions`** -- restricts which actions the agent can use from this tool.
- **`as_tool()`** -- serializes for agent creation, including `actions` list.
- **Action-based validation** -- `_validate_params()` uses `ActionInputsProxy` instead of model parameter validation.
- **Run requires action** -- `Tool.run()` requires an `action` parameter (falls back to single allowed action).

### How Python v2 structures Integrations (`integration.py`)

`Integration` extends `Model` with `ActionMixin`:

```python
class Integration(Model, ActionMixin):
    RESOURCE_PATH = "v2/integrations"
    RESPONSE_CLASS = IntegrationResult
    AuthenticationScheme = AuthenticationScheme

    def connect(self, **kwargs) -> Tool:
        response = self.run(**kwargs)
        tool_id = response.data.id
        return self.context.Tool.get(tool_id)
```

**ActionMixin** provides the action infrastructure:

```python
class ActionMixin:
    actions_available: Optional[bool]

    def list_actions(self) -> List[Action]
        # POST to run_url with action="LIST_ACTIONS"

    def list_inputs(self, *actions) -> List[Action]
        # POST to run_url with action="LIST_INPUTS"

    @cached_property
    def actions(self) -> ActionsProxy
        # tool.actions['SLACK_SEND_MESSAGE'].channel = '#general'

    def set_inputs(self, inputs_dict)
        # Bulk-set action inputs
```

**Action data model:**

```python
@dataclass
class Action:
    name, description, displayName, slug
    available_versions, version, toolkit
    input_parameters, output_parameters
    scopes, tags, no_auth, deprecated
    inputs: Optional[List[Input]]

@dataclass
class Input:
    name, code, value, availableOptions
    datatype, allowMulti, supportsVariables
    defaultValue, required, fixed, description
```

**ActionInputsProxy** provides parameter access per action:

```python
class ActionInputsProxy:
    # Lazy-fetches action inputs from backend
    # Dict-like + dot notation access
    # Type validation against Input.datatype
    # Reset to defaults
```

**ActionsProxy** provides action access on the tool:

```python
class ActionsProxy:
    # tool.actions['ACTION_NAME'] returns ActionInputsProxy
    # Case-insensitive action name resolution
    # Caching of action proxies
```

### How tools are used with agents

When saving an agent, tools are serialized via `ToolableMixin.as_tool()`:

```python
# From agent.py build_save_payload
for tool in self.tools:
    if isinstance(tool, ToolableMixin):
        converted_assets.append(tool.as_tool())
```

`Tool.as_tool()` extends `Model.as_tool()` by adding `actions`:

```python
def as_tool(self) -> dict:
    tool_dict = super().as_tool()
    if self.allowed_actions:
        tool_dict["actions"] = self.allowed_actions
    return tool_dict
```

### Current Swift SDK

- `Tool` is a simple struct (id, type, function, supplier, description, version).
- `CreateAgentTool` enum wraps models/pipelines/utilities for agent creation.
- `AgentUsableTool` protocol with `convertToTool()` method.
- No concept of integrations, actions, or action inputs.

## Decision

Build a full `Tool` resource and `Integration` resource following the Python v2 architecture, including the `ActionMixin` pattern.

## API Shape

### Tool

```swift
/// Tool is a subclass of Model (matches Python v2 `class Tool(Model, ...)`).
/// Inherits all Model fields and capabilities.
public final class Tool: Model {
    public override class var resourcePath: String { "v2/tools" }
    static let defaultIntegrationId = "686432941223092cb4294d3f"

    // Tool-specific fields (Model fields inherited)
    public var assetId: String?
    public var integration: IntegrationRef?  // String ID or Integration
    public var config: [String: Any]?
    public var code: String?
    public var allowedActions: [String] = []
    public var actionsAvailable: Bool?

    // Action access (mirrors Python v2 ActionsProxy)
    public lazy var actions: ActionsProxy = ActionsProxy(container: self)

    weak var context: Aixplain?
}

/// Reference to an integration -- either an ID string or a resolved object.
public enum IntegrationRef: Sendable {
    case id(String)
    case resolved(Integration)
}
```

### Tool CRUD

```swift
extension Tool {
    /// Get a tool by ID.
    public static func get(_ id: String, context: Aixplain) async throws -> Tool

    /// Search tools.
    public static func search(_ params: ToolSearchParams, context: Aixplain) async throws -> Page<Tool>

    /// Delete this tool.
    public func delete() async throws

    /// Save/create this tool.
    /// Creation goes through integration.connect() -- mirrors Python v2 _create.
    public func save() async throws -> Tool
}
```

### Tool Run

```swift
extension Tool {
    /// Run the tool. Requires an `action` parameter.
    /// Falls back to single allowed action if only one exists.
    /// Mirrors Python v2 `Tool.run()`.
    public func run(action: String? = nil, data: Any? = nil) async throws -> RunResult
}
```

### Tool as_tool()

```swift
extension Tool: AgentToolConvertible {
    public func asAgentTool() -> AgentToolDict {
        var dict = AgentToolDict(
            id: id ?? "",
            name: name ?? "",
            description: description ?? "",
            supplier: vendor?.code ?? "aixplain",
            parameters: getParameters(),
            function: function?.rawValue ?? "",
            type: .tool,
            version: version?.id ?? "",
            assetId: id ?? ""
        )
        if !allowedActions.isEmpty {
            dict.actions = allowedActions
        }
        return dict
    }
}
```

### Integration

```swift
public final class Integration: @unchecked Sendable {
    public static let resourcePath = "v2/integrations"

    public var id: String?
    public var name: String?
    public var description: String?
    public var actionsAvailable: Bool?

    // Action access
    public lazy var actions: ActionsProxy = ActionsProxy(container: self)

    weak var context: Aixplain?

    /// Connect the integration, creating a Tool.
    /// Mirrors Python v2 `integration.connect()`.
    public func connect(name: String? = nil, description: String? = nil,
                        config: [String: Any]? = nil) async throws -> Tool
}

extension Integration {
    public static func get(_ id: String, context: Aixplain) async throws -> Integration
}
```

### ActionMixin (Swift protocol)

```swift
/// Mirrors Python v2 `ActionMixin`.
public protocol ActionCapable: AnyObject {
    var actionsAvailable: Bool? { get }
    var context: Aixplain? { get }
    func buildRunURL() throws -> String

    /// List available actions.
    func listActions() async throws -> [Action]

    /// List inputs for specified actions.
    func listInputs(_ actionNames: String...) async throws -> [Action]
}
```

### Action data model

```swift
/// Mirrors Python v2 `Action` dataclass.
public struct Action: Codable, Sendable {
    public let name: String?
    public let description: String?
    public let displayName: String?
    public let slug: String?
    public let inputs: [ActionInput]?
}

/// Mirrors Python v2 `Input` dataclass.
public struct ActionInput: Codable, Sendable {
    public let name: String
    public var code: String?
    public var datatype: String = "string"
    public var allowMulti: Bool = false
    public var supportsVariables: Bool = false
    public var defaultValue: [AnyCodable]?
    public var required: Bool = false
    public var fixed: Bool = false
    public var description: String = ""
}
```

### ActionsProxy

```swift
/// Mirrors Python v2 `ActionsProxy`.
/// Uses `@dynamicMemberLookup` for `tool.actions.slackSendMessage` syntax.
@dynamicMemberLookup
public class ActionsProxy {
    private weak var container: (any ActionCapable)?
    private var cache: [String: ActionInputsProxy] = [:]

    public subscript(actionName: String) -> ActionInputsProxy {
        get async throws { ... }
    }

    /// Dot-notation: `tool.actions.slackSendMessage`
    public subscript(dynamicMember member: String) -> ActionInputsProxy {
        get async throws { try await self[member] }
    }

    public func availableActions() async throws -> [String]
}

/// Mirrors Python v2 `ActionInputsProxy`.
/// Actor for thread-safe concurrent access to action input values.
@dynamicMemberLookup
public actor ActionInputsProxy {
    public subscript(inputCode: String) -> Any? { get set }

    /// Dot-notation: `proxy.channel = "#general"`
    public subscript(dynamicMember member: String) -> Any? {
        get { self[member] }
        set { self[member] = newValue }
    }

    public func validate(_ data: [String: Any]) -> [String]
    public func reset()
}
```

## Shared Contracts

### Consumes from other RFCs

| Type | From RFC | How it's used |
|------|----------|---------------|
| `AixplainClient` | RFC-0002 | Via `context.client` for HTTP calls (CRUD, run, list_actions) |
| `Aixplain` | RFC-0002 | `context` reference; `context.Tool.get()` in `Integration.connect()` |
| `BaseResource` | RFC-0004 | Tool conforms for save/clone |
| `Gettable` | RFC-0004 | Tool/Integration conform for `.get()` |
| `Searchable` | RFC-0004 | Tool conforms for `.search()` |
| `Deletable` | RFC-0004 | Tool conforms for `.delete()` |
| `Runnable` | RFC-0004 | Tool/Integration conform for `.run()` |
| `AgentToolConvertible` | RFC-0004 | Tool conforms; `asAgentTool()` returns `AgentToolDict` |
| `AgentToolDict` | RFC-0004 | Return type of `asAgentTool()`; includes `actions` field |
| `Page<T>` | RFC-0004 | Return type of `Tool.search()` |
| `AssetStatus` | RFC-0004 | Tool status field |
| `AIFunction` | RFC-0004 | Tool function field |
| `AnyCodable` | RFC-0004 | Tool config, action input values |
| `AixplainError` | RFC-0005 | Thrown on HTTP failures |
| `ValidationError` | RFC-0005 | Thrown by action input validation |
| `Model` | RFC-0007 | Tool extends Model conceptually; shares `VendorInfo`, `ModelVersion` |
| `VendorInfo` | RFC-0007 | Tool vendor metadata |

### Produces for other RFCs

| Type | Consumed by | How it's used |
|------|-------------|---------------|
| `Tool` | RFC-0003 (agent tools list) | Agents hold tools; serialized via `asAgentTool()` during save |
| `Tool.asAgentTool()` | RFC-0003 (save payload) | Returns `AgentToolDict` with `actions` for allowed actions |
| `Integration` | -- | Used to create Tools via `connect()` |
| `ActionCapable` | -- | Protocol for action-capable resources |
| `Action` | -- | Action metadata; could be used by agent progress tracking |
| `ActionsProxy` | -- | Action parameter access on tools |

### Key interaction: Tool → Agent flow

```
Agent.save()
  └── buildSavePayload()
        └── for tool in self.tools:
              └── tool.asAgentTool() → AgentToolDict
                    ├── Model: {id, name, type:"model", parameters, ...}
                    └── Tool:  {id, name, type:"tool", actions:["ACTION1","ACTION2"], ...}
```

### Key interaction: Integration → Tool creation flow

```
Integration.connect(name: "My Slack", config: {...})
  └── integration.run(**kwargs)    // POST to v2/integrations/{id}/run
        └── response.data.id       // new tool ID
              └── context.Tool.get(toolId)  // fetch created Tool
```

## Implementation

### Files to delete

- `Sources/aiXplainKit/Modules/Agents/Tools/` (entire directory -- Tool, CreateAgentTool, AgentUsable conformances)

### Files to create

| File | Content |
|------|---------|
| `Sources/aiXplainKit/Tools/Tool.swift` | Tool resource with CRUD, run, as_tool |
| `Sources/aiXplainKit/Tools/ToolSearchParams.swift` | Search parameters |
| `Sources/aiXplainKit/Tools/Integration.swift` | Integration resource with connect() |
| `Sources/aiXplainKit/Tools/ActionCapable.swift` | ActionMixin protocol |
| `Sources/aiXplainKit/Tools/Action.swift` | Action + ActionInput data models |
| `Sources/aiXplainKit/Tools/ActionsProxy.swift` | ActionsProxy for action access |
| `Sources/aiXplainKit/Tools/ActionInputsProxy.swift` | Per-action parameter proxy |

## Testing

- Unit: `Tool.get()` dispatches GET to `v2/tools/{id}`.
- Unit: `Tool.save()` resolves integration and calls `connect()`.
- Unit: `Tool.run()` requires action parameter; falls back to single allowed action.
- Unit: `Tool.asAgentTool()` includes `actions` list when `allowedActions` is set.
- Unit: `Integration.connect()` calls `run()` and returns `Tool.get(responseId)`.
- Unit: `listActions()` posts `LIST_ACTIONS` and parses `Action` list.
- Unit: `listInputs()` posts `LIST_INPUTS` and parses `Action` with inputs.
- Unit: `ActionsProxy` caches action proxies; case-insensitive lookup.
- Unit: `ActionInputsProxy` validates input types against `ActionInput.datatype`.
- Contract: tool GET response fixture.
- Contract: integration connect response fixture.

## Out of Scope

- OAuth flow for integrations (handled by platform).
- Custom integration creation (only connecting existing integrations).
- Action execution monitoring / progress tracking.

## Resolved Questions

1. **`Tool` is a subclass of `Model`** -- matches Python v2 `class Tool(Model, ...)`. Inherits model fields and `run()`/`asAgentTool()`.
2. **`ActionsProxy` uses `@dynamicMemberLookup`** -- enables `tool.actions.slackSendMessage.channel = "#general"` syntax.
3. **Lazy integration resolution uses async** -- `_ensureIntegration()` is `async throws`, resolves integration ID to `Integration` object on first access.
4. **`ActionInputsProxy` is an actor** -- thread-safe concurrent access to action input values.
