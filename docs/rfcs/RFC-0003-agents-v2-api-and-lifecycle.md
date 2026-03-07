# RFC-0003: Agents v2 API and Lifecycle

| Field        | Value                                    |
|--------------|------------------------------------------|
| Status       | Implemented                              |
| Authors      |                                          |
| Created      | 2026-03-06                               |
| Depends on   | RFC-0001, RFC-0002, RFC-0004, RFC-0005, RFC-0008 |
| Depended by  | --                                       |
| Priority     | **P0 -- Highest-priority domain RFC**    |

> This is the most important domain RFC in the v2 sequence. Agents are the primary product surface and the first resource type to be fully migrated after the Auth and Client foundations are in place.

## Context

### Current Swift SDK (what exists)

The agent surface is split across multiple files and types:

- **`Agent`** (`Agents.swift`) -- `Codable` class with `id`, `name`, `status`, `teamId`, `llmId`, `role`, `assets`. Owns its own `Networking` instance. Has two `run()` variants and private `polling()`.
- **`AgentProvider`** (`AgentProvider.swift`) -- separate class for `get()`, `list()`, `create()`.
- **`Agent+CRUD`** (`Agents+CRUD.swift`) -- `deploy()`, `appendTools()`, `update()`, `delete()` as instance methods.
- **`TeamAgent`** -- parallel hierarchy with its own provider.
- **Tools** -- `Tool` struct, `CreateAgentTool` enum, `AgentUsableTool` protocol.

### How Python v2 structures Agents (`agent.py` + `resource.py`)

The Python v2 `Agent` class is the most complex resource in the SDK. Understanding its architecture is critical.

**Inheritance chain:**

```python
@dataclass(repr=False)
class Agent(
    BaseResource,                                    # save(), clone(), _action()
    SearchResourceMixin[BaseSearchParams, "Agent"],  # search() with pagination
    GetResourceMixin[BaseGetParams, "Agent"],         # get() class method
    DeleteResourceMixin[BaseDeleteParams, "Agent"],   # delete() instance method
    RunnableResourceMixin[AgentRunParams, AgentRunResult],  # run(), run_async(), poll()
):
    RESOURCE_PATH = "v2/agents"
    RESPONSE_CLASS = AgentRunResult
```

**Key fields (from `agent.py`):**

```python
instructions: Optional[str] = None
status: AssetStatus = AssetStatus.DRAFT
team_id: Optional[int] = field(metadata=config(field_name="teamId"))
llm: Union[str, "Model"] = field(default=DEFAULT_LLM)
tools: Optional[List[Dict[str, Any]]] = field(default_factory=list)
tasks: Optional[List[Task]] = field(default_factory=list)
subagents: Optional[List[Union[str, "Agent"]]] = field(field_name="agents")
output_format: Optional[Union[str, OutputFormat]] = field(field_name="outputFormat")
expected_output: Optional[Union[str, dict, BaseModel]] = field(field_name="expectedOutput")
inspector_id, supervisor_id, planner_id  # agent orchestration
max_iterations: Optional[int] = 5
max_tokens: Optional[int] = 2048
```

**AgentRunParams (TypedDict):**

```python
class AgentRunParams(BaseRunParams):
    sessionId: NotRequired[Optional[Text]]
    query: NotRequired[Optional[Union[Dict, Text]]]
    variables: NotRequired[Optional[Dict[str, Any]]]      # {{var}} substitution
    allowHistoryAndSessionId: NotRequired[Optional[bool]]
    tasks: NotRequired[Optional[List[Any]]]
    prompt: NotRequired[Optional[Text]]
    history: NotRequired[Optional[List[ConversationMessage]]]
    executionParams: NotRequired[Optional[Dict[str, Any]]]
    criteria: NotRequired[Optional[Text]]
    evolve: NotRequired[Optional[Text]]
    inspectors: NotRequired[Optional[List[Dict]]]
    runResponseGeneration: NotRequired[Optional[bool]]
    progress_format: NotRequired[Optional[Text]]      # "status" or "logs"
    progress_verbosity: NotRequired[Optional[int]]     # 1, 2, or 3
    progress_truncate: NotRequired[Optional[bool]]
```

**AgentRunResult:**

```python
@dataclass
class AgentRunResult(Result):
    data: Optional[Union[AgentResponseData, Text]] = None
    session_id: Optional[Text] = field(field_name="sessionId")
    request_id: Optional[Text] = field(field_name="requestId")
    used_credits: float = field(field_name="usedCredits")
    run_time: float = field(field_name="runTime")
    _context: Optional[Any] = None  # for debug() method

    def debug(self, prompt=None, execution_id=None) -> DebugResult:
        # convenience method to debug this response
```

**Lifecycle hooks (from `resource.py` `with_hooks` decorator + agent overrides):**

```python
def before_run(self, **kwargs):
    # 1. Validate all dependencies are saved
    self._validate_run_dependencies()
    # 2. Auto-save draft agents
    if self.status in [AssetStatus.DRAFT, None] and self.is_modified:
        self.save(as_draft=True)
    # 3. Initialize progress tracker if progress_format is provided

def after_run(self, result, **kwargs):
    # 1. Finish progress tracking
    # 2. Set result._context for debug() support

def before_save(self, **kwargs):
    as_draft = kwargs.pop("as_draft", False)
    self.status = AssetStatus.DRAFT if as_draft else AssetStatus.ONBOARDED
    self._validate_expected_output()

def build_save_payload(self, **kwargs):
    payload = self.to_dict()
    # Convert tools via ToolableMixin.as_tool()
    # Convert {{var}} to {var} for backend
    # Set payload["model"] = {"id": self.llm}
    # Resolve subagent IDs

def build_run_payload(self, **kwargs):
    # Build executionParams with defaults (outputFormat, maxTokens, maxIterations, maxTime)
    # Handle BaseModel expectedOutput conversion
    # Process variables for {{placeholder}} substitution
    # Build final payload with id, executionParams, runResponseGeneration, query
```

**Session management:**

```python
def generate_session_id(self, history=None) -> str:
    # Format: "{agent_id}_{timestamp}"
    # If history provided, validate and initialize via run_async
    session_id = f"{self.id}_{timestamp}"
    if history:
        validate_history(history)
        self.run_async(query="/", sessionId=session_id, history=history, ...)
    return session_id
```

**Task dependencies:**

```python
@dataclass
class Task:
    name: str
    instructions: Optional[str] = field(field_name="description")
    expected_output: Optional[str] = field(field_name="expectedOutput")
    dependencies: List[Union[str, "Task"]] = field(default_factory=list)

    def __post_init__(self):
        # Resolve Task references to name strings
        self.dependencies = [d if isinstance(d, str) else d.name for d in self.dependencies]
```

**Conversation history:**

```python
class ConversationMessage(TypedDict):
    role: Literal["user", "assistant"]
    content: str

def validate_history(history):
    # Must be list of dicts with "role" and "content"
    # role must be "user" or "assistant"
    # content must be string
```

### Problems in the current Swift SDK

1. **Split responsibilities** -- CRUD on `Agent`, fetching on `AgentProvider`, creation on `AgentProvider+BuildAgents`.
2. **Each agent owns networking** -- `Agent` creates `Networking()` in `init(from:)`.
3. **No session model** -- `sessionID` is a pass-through string with no lifecycle.
4. **No conversation history** -- Python v2 has `ConversationMessage` and `validate_history()`.
5. **No output format** -- Python v2 has `OutputFormat` (markdown, text, json).
6. **No progress tracking** -- Python v2 has `AgentProgressTracker`.
7. **No tasks/dependencies** -- Python v2 supports `Task` objects.
8. **No hook system** -- Python v2 has `before_run`, `after_run`, `before_save` hooks via `@with_hooks`.
9. **No auto-save** -- Python v2 auto-saves draft agents before run.
10. **No modification tracking** -- Python v2 tracks `is_modified` via saved state diffing.
11. **No variables/placeholder substitution** -- Python v2 supports `{{var}}` in instructions.
12. **No expected output / structured output** -- Python v2 supports Pydantic BaseModel schemas.
13. **TeamAgent is separate** -- Python v2 models team agents as agents with `subagents` field.
14. **Tool type typo** -- `ToolType.pipiline`.
15. **`list(ModelQuery)` returns `[]`** -- unfinished.

## Decision

Unify the agent surface into a single `Agent` resource type that uses the v2 `AixplainClient` (RFC-0002), following the Python v2 mixin pattern adapted to Swift protocols.

## API Shape

### Agent (mirrors Python v2 `Agent` dataclass)

```swift
/// Agent resource.
/// Mirrors Python v2: `class Agent(BaseResource, SearchResourceMixin, GetResourceMixin,
/// DeleteResourceMixin, RunnableResourceMixin)`.
public final class Agent: @unchecked Sendable {
    /// Python v2: `RESOURCE_PATH = "v2/agents"`
    public static let resourcePath = "v2/agents"

    // Core fields (mirrors Python v2 agent.py fields)
    public var id: String?
    public var name: String?
    public var description: String?
    public var instructions: String?
    public var status: AssetStatus = .draft
    public var teamId: Int?
    public var llmId: String = Agent.defaultLLM

    // Tools and subagents
    public var tools: [Any] = []           // Tool, Model, or dict
    public var subagents: [Any] = []       // Agent or String IDs
    public var tasks: [AgentTask] = []

    // Output control
    public var outputFormat: OutputFormat = .text
    public var expectedOutput: ExpectedOutput? = nil
    public var maxIterations: Int = 5
    public var maxTokens: Int = 2048

    // Metadata (read-only from API)
    public private(set) var createdAt: Date?
    public private(set) var updatedAt: Date?

    // Inspector/supervisor IDs
    public var inspectorId: String?
    public var supervisorId: String?
    public var plannerId: String?

    // Strong context reference (mirrors Python v2 `context` class attribute)
    // Decision: strong ref, not weak -- agent always needs its context.
    var context: Aixplain?

    // Modification tracking (mirrors Python v2 `_saved_state` + `is_modified`)
    private var savedState: [String: Any]?

    public var isModified: Bool { /* diff current vs savedState */ }

    static let defaultLLM = "669a63646eb56306647e1091"
}

public enum AssetStatus: String, Codable, Sendable {
    case draft, hidden, scheduled, onboarding, onboarded
    case pending, failed, training, rejected
    case enabling, deleting, disabled, deleted
    case inProgress = "in_progress"
    case completed, canceling, canceled
    case deprecatedDraft = "deprecated_draft"
}

public enum OutputFormat: String, Codable, Sendable {
    case markdown, text, json
}
```

### CRUD (mirrors Python v2 mixins)

```swift
// Mirrors Python v2 GetResourceMixin.get()
extension Agent {
    /// Get agent by ID.
    /// Python v2: `Agent.get(id)` → `context.client.get(f"{RESOURCE_PATH}/{id}")`
    public static func get(_ id: String, context: Aixplain) async throws -> Agent
}

// Mirrors Python v2 SearchResourceMixin.search()
extension Agent {
    /// Search/list agents with pagination.
    /// Python v2: `Agent.search(**kwargs)` → POST to `{RESOURCE_PATH}/paginate`
    public static func search(
        query: String? = nil,
        pageNumber: Int = 0,
        pageSize: Int = 20,
        context: Aixplain
    ) async throws -> Page<Agent>
}

// Mirrors Python v2 BaseResource.save()
extension Agent {
    /// Save the agent. Creates if no ID, updates if ID exists.
    /// Python v2: `agent.save(as_draft=True)` → POST/PUT to RESOURCE_PATH
    public func save(asDraft: Bool = false) async throws -> Agent

    /// Clone the agent (deep copy with id=nil).
    /// Python v2: `agent.clone(name="new")`
    public func clone(name: String? = nil) -> Agent
}

// Mirrors Python v2 DeleteResourceMixin.delete()
extension Agent {
    /// Delete this agent.
    /// Python v2: `agent.delete()` → DELETE to `{RESOURCE_PATH}/{id}`
    public func delete() async throws
}
```

### Run / Execution (mirrors Python v2 `RunnableResourceMixin`)

```swift
/// Run parameters matching Python v2 `AgentRunParams`.
public struct AgentRunParams: Sendable {
    public var query: QueryInput?
    public var sessionId: String?
    public var variables: [String: Any]?
    public var history: [ConversationMessage]?
    public var tasks: [AgentTask]?
    public var prompt: String?
    public var executionParams: ExecutionParams?
    public var runResponseGeneration: Bool = true

    // Progress tracking (mirrors Python v2)
    public var progressFormat: ProgressFormat?
    public var progressVerbosity: Int = 1
    public var progressTruncate: Bool = true

    public var timeout: TimeInterval = 300
    public var waitTime: TimeInterval = 0.5
}

public enum QueryInput: Sendable {
    case text(String)
    case structured([String: Any])
}

public struct ExecutionParams: Codable, Sendable {
    public var outputFormat: OutputFormat = .text
    public var maxTokens: Int = 2048
    public var maxIterations: Int = 5
    public var maxTime: Int = 300
    public var expectedOutput: ExpectedOutput?
}

/// Conversation message matching Python v2 `ConversationMessage`.
public struct ConversationMessage: Codable, Sendable {
    public let role: MessageRole
    public let content: String
}

public enum MessageRole: String, Codable, Sendable {
    case user, assistant
}

/// Task with dependencies matching Python v2 `Task`.
public struct AgentTask: Codable, Sendable {
    public let name: String
    public let instructions: String?
    public let expectedOutput: String?
    public var dependencies: [String] = []
}

/// Run result matching Python v2 `AgentRunResult`.
public struct AgentRunResult: Sendable {
    public let status: String
    public let completed: Bool
    public let data: AgentResponseData?
    public let sessionId: String?
    public let requestId: String?
    public let usedCredits: Double
    public let runTime: Double
    public let errorMessage: String?
    public let supplierError: String?

    // For polling
    public let url: String?
}

public struct AgentResponseData: Codable, Sendable {
    public let input: String?
    public let output: String?
    public let steps: [[String: Any]]?
    public let sessionId: String?
    public let executionStats: [String: Any]?
}

public enum ProgressFormat: String, Sendable {
    case status   // single line
    case logs     // timeline
}

/// Progress tracking via delegate/closure pattern (not AsyncStream).
public protocol AgentProgressDelegate: AnyObject {
    func agent(_ agent: Agent, didUpdateProgress step: AgentProgressStep)
    func agent(_ agent: Agent, didCompleteWithResult result: AgentRunResult)
}

public struct AgentProgressStep: Sendable {
    public let status: String
    public let message: String?
    public let stepIndex: Int?
    public let totalSteps: Int?
}

/// TeamAgent is just an Agent with subagents.
/// Kept as typealias for discoverability.
public typealias TeamAgent = Agent
```

### Run methods (mirrors Python v2 `RunnableResourceMixin.run()` / `run_async()`)

```swift
extension Agent {
    /// Run synchronously with automatic polling.
    /// Mirrors Python v2: `agent.run(query="Hello")` which internally calls
    /// `run_async()` then `sync_poll()`.
    /// Uses `self.context.client` for HTTP -- no need to pass client.
    public func run(_ query: String, sessionId: String? = nil) async throws -> AgentRunResult

    /// Run with full params.
    public func run(_ params: AgentRunParams) async throws -> AgentRunResult

    /// Run asynchronously -- returns immediately with polling URL.
    /// Mirrors Python v2: `agent.run_async(query="Hello")`
    public func runAsync(_ params: AgentRunParams) async throws -> AgentRunResult

    /// Poll a URL for completion.
    /// Mirrors Python v2: `agent.poll(poll_url)`
    public func poll(_ url: String) async throws -> AgentRunResult

    /// Poll until completion with exponential backoff.
    /// Mirrors Python v2: `agent.sync_poll(url, timeout=300, wait_time=0.5)`
    public func syncPoll(
        _ url: String,
        timeout: TimeInterval = 300,
        waitTime: TimeInterval = 0.5
    ) async throws -> AgentRunResult

    /// Generate a unique session ID.
    /// Mirrors Python v2: `agent.generate_session_id(history=None)`
    /// Format: "{agent_id}_{timestamp}"
    public func generateSessionId(history: [ConversationMessage]? = nil) async throws -> String
}
```

### Hook system (mirrors Python v2 `@with_hooks` + before/after methods)

```swift
extension Agent {
    /// Called before run. Mirrors Python v2 `before_run`:
    /// 1. Validate dependencies are saved
    /// 2. Auto-save draft agents if modified
    /// 3. Initialize progress tracker
    func beforeRun(_ params: AgentRunParams) async throws

    /// Called after run. Mirrors Python v2 `after_run`:
    /// 1. Finish progress tracking
    /// 2. Set context on result for debug support
    func afterRun(_ result: AgentRunResult) -> AgentRunResult

    /// Called before save. Mirrors Python v2 `before_save`:
    /// 1. Set status to draft or onboarded
    /// 2. Validate expected output
    func beforeSave(asDraft: Bool) throws

    /// Build the save payload. Mirrors Python v2 `build_save_payload`:
    /// 1. Serialize to dict
    /// 2. Convert tools via as_tool()
    /// 3. Convert {{var}} to {var}
    /// 4. Set model.id
    /// 5. Resolve subagent IDs
    func buildSavePayload() throws -> [String: Any]

    /// Build the run payload. Mirrors Python v2 `build_run_payload`:
    /// 1. Build executionParams with defaults
    /// 2. Process variables
    /// 3. Build final payload
    func buildRunPayload(_ params: AgentRunParams) throws -> [String: Any]
}
```

### Save payload construction (mirrors Python v2 `build_save_payload`)

The Python v2 save payload has specific transformations:

```
payload = self.to_dict()

# 1. Convert tools via ToolableMixin
for tool in self.tools:
    if isinstance(tool, ToolableMixin):
        converted_assets.append(tool.as_tool())

# 2. Template variables: {{var}} → {var}
payload["instructions"] = re.sub(r"\{\{(\w+)\}\}", r"{\1}", payload["instructions"])

# 3. LLM reference
payload["model"] = {"id": self.llm}

# 4. Subagent IDs
for agent in self._original_subagents:
    converted_agents.append({"id": agent.id, "inspectors": []})
```

### Conversation history validation (mirrors Python v2 `validate_history`)

```swift
/// Validates conversation history for agent sessions.
/// Mirrors Python v2 `validate_history()` exactly.
public static func validateHistory(_ history: [ConversationMessage]) throws {
    for (index, message) in history.enumerated() {
        guard !message.content.isEmpty else {
            throw ValidationError("'content' at index \(index) must not be empty.")
        }
        // role is already constrained by MessageRole enum
    }
}
```

### TeamAgent (mirrors Python v2 `subagents` field)

In Python v2, team agents are just agents with `subagents` populated:

```python
subagents: Optional[List[Union[str, "Agent"]]] = field(field_name="agents")
```

Swift v2 should follow the same pattern -- `Agent` has an optional `subagents` field. The v1 `TeamAgent` class is deleted.

```swift
// An agent with subagents is a team agent.
// Python v2 does not have a separate TeamAgent class.
extension Agent {
    public var isTeamAgent: Bool { !subagents.isEmpty }
}
```

## Lifecycle Flow

```
┌────────────┐                ┌────────────┐
│ Agent(...)  │──save(draft)──▶│   draft    │
└────────────┘                └─────┬──────┘
                                    │
                              save()/clone()
                                    │
                        ┌───────────┼──────────┐
                        │           │          │
                  save(onboard)  delete()   save(draft)
                        │           │          │
                        ▼           ▼          ▼
                  ┌──────────┐ ┌────────┐ ┌────────┐
                  │onboarded │ │deleted │ │ draft  │
                  └────┬─────┘ └────────┘ └────────┘
                       │
              run() / runAsync()
                       │
           ┌───────────┼──────────┐
           │                      │
     [auto-save if              poll()
      draft+modified]              │
           │                      ▼
           ▼              ┌──────────────┐
    AgentRunResult        │sync_poll loop│
                          │  on_poll()   │
                          └──────┬───────┘
                                 │
                                 ▼
                          AgentRunResult
```

## Shared Contracts

### Consumes from other RFCs

| Type | From RFC | How it's used |
|------|----------|---------------|
| `Credential` | RFC-0001 | Via `context.client` for all HTTP calls |
| `AixplainClient` | RFC-0002 | Via `context.client` -- `get()`, `post()`, `request()` for CRUD and run |
| `Aixplain` | RFC-0002 | Stored as `weak var context`; provides client and configuration |
| `ClientConfiguration` | RFC-0002 | `context.client.configuration.backendURL` for URL resolution |
| `BaseResource` | RFC-0004 | Agent conforms to `BaseResource` protocol for `save()`/`clone()` |
| `Gettable` | RFC-0004 | Agent conforms for `Agent.get()` |
| `Searchable` | RFC-0004 | Agent conforms for `Agent.search()` returning `Page<Agent>` |
| `Deletable` | RFC-0004 | Agent conforms for `agent.delete()` |
| `Runnable` | RFC-0004 | Agent conforms for `run()`/`runAsync()`/`poll()`/`syncPoll()` |
| `Page<T>` | RFC-0004 | Return type of `Agent.search()` |
| `AgentToolConvertible` | RFC-0004 | Used in `buildSavePayload()` to serialize tools via `asAgentTool()` |
| `AgentToolDict` | RFC-0004 | The serialized form of tools in the agent save payload |
| `AssetStatus` | RFC-0004 | Agent status field (draft, onboarded, deleted, etc.) |
| `ResponseStatus` | RFC-0004 | Used in polling to check for SUCCESS/FAILED |
| `AixplainError` | RFC-0005 | Thrown by `poll()` on failure, `syncPoll()` on timeout |
| `APIError` | RFC-0005 | Thrown via `APIError.fromFailedOperation()` when polling returns FAILED |
| `TimeoutError` | RFC-0005 | Thrown by `syncPoll()` when timeout exceeded |
| `ValidationError` | RFC-0005 | Thrown by `validateHistory()` and `beforeRun()` |
| `Tool` (as `AgentToolConvertible`) | RFC-0008 | Tools in `agent.tools` are serialized via `tool.asAgentTool()` |
| `Model` (as `AgentToolConvertible`) | RFC-0007 | Models can be used as agent tools via `model.asAgentTool()` |

### Produces for other RFCs

| Type | Consumed by | How it's used |
|------|-------------|---------------|
| `Agent` | RFC-0008 (subagents) | Agent instances can be subagents of other agents |
| `AgentRunResult` | RFC-0005 (contract tests) | Decoded from polling responses; validated by contract fixtures |
| `ConversationMessage` | -- | Self-contained; used in agent sessions |
| `AgentTask` | -- | Self-contained; used in agent task workflows |
| `OutputFormat` | -- | Self-contained; used in execution params |

### Key interaction: Agent → Tool serialization flow

```
Agent.save()
  └── buildSavePayload()
        └── for tool in self.tools:
              └── if tool conforms to AgentToolConvertible (RFC-0004):
                    └── tool.asAgentTool() → AgentToolDict (RFC-0004)
                          └── Model.asAgentTool() (RFC-0007)
                          └── Tool.asAgentTool() (RFC-0008) with actions list
```

## Implementation

Clean-slate: delete all v1 agent code and build from scratch following the Python v2 architecture.

### Files to delete

- `Sources/aiXplainKit/Modules/Agents/Agents.swift`
- `Sources/aiXplainKit/Modules/Agents/Agents+CRUD.swift`
- `Sources/aiXplainKit/Modules/Agents/Input/` (entire directory)
- `Sources/aiXplainKit/Modules/Agents/Tools/` (entire directory)
- `Sources/aiXplainKit/Modules/TeamAgents/` (entire directory)
- `Sources/aiXplainKit/Modules/Parameters/Agent/`
- `Sources/aiXplainKit/Provider/Agent/` (entire directory)
- `Sources/aiXplainKit/Provider/TeamAgent/` (entire directory)
- `Sources/aiXplainKit/Networking/ResponseDecoders/AgentOutput.swift`
- `Sources/aiXplainKit/Networking/ResponseDecoders/AgentExecuteResponse.swift`

### Files to create

| File | Content |
|------|---------|
| `Sources/aiXplainKit/Modules/Agents/Agent.swift` | `Agent` class with all fields, save/clone/delete/run |
| `Sources/aiXplainKit/Modules/Agents/AgentRunParams.swift` | Run parameters |
| `Sources/aiXplainKit/Modules/Agents/AgentRunResult.swift` | Run result with session metadata |
| `Sources/aiXplainKit/Modules/Agents/ConversationMessage.swift` | History model + validation |
| `Sources/aiXplainKit/Modules/Agents/AgentTask.swift` | Task with dependencies |
| `Sources/aiXplainKit/Modules/Agents/OutputFormat.swift` | Output format enum |
| `Sources/aiXplainKit/Modules/Agents/AssetStatus.swift` | Shared status enum |

## Testing

- Unit: `Agent.get()` dispatches GET to `v2/agents/{id}`.
- Unit: `Agent.search()` dispatches POST to `v2/agents/paginate` with filters.
- Unit: `Agent.save()` dispatches POST (create) or PUT (update) based on `id`.
- Unit: `Agent.save(asDraft: true)` sets status to `.draft`.
- Unit: `Agent.save(asDraft: false)` sets status to `.onboarded`.
- Unit: `beforeRun` auto-saves draft agents that are modified.
- Unit: `beforeRun` validates all tool/subagent dependencies are saved.
- Unit: `buildSavePayload` converts tools via `asAgentTool()`.
- Unit: `buildSavePayload` converts `{{var}}` to `{var}` in instructions.
- Unit: `buildSavePayload` sets `model.id` from `llmId`.
- Unit: `buildRunPayload` builds `executionParams` with defaults.
- Unit: `buildRunPayload` processes `variables` into query dict.
- Unit: `run()` calls `runAsync()` then `syncPoll()`.
- Unit: `syncPoll` loops with exponential backoff until `completed == true`.
- Unit: `syncPoll` throws `TimeoutError` after timeout.
- Unit: `poll()` raises `APIError` on `status == "FAILED"`.
- Unit: `generateSessionId` returns `"{id}_{timestamp}"` format.
- Unit: `generateSessionId` with history validates and initializes session.
- Unit: `validateHistory` rejects non-dict, missing role/content, invalid roles.
- Unit: `AgentRunResult` decodes from fixture JSON with all fields.
- Unit: `AgentTask` resolves Task references to name strings in dependencies.
- Unit: `clone()` produces copy with `id = nil`.
- Integration: create → save(draft) → save(onboard) → run → delete lifecycle.

## Out of Scope

- Inspector / Debugger integration (separate RFC candidate; Python v2 has `inspector.py`, `meta_agents.py`).
- Agent progress tracker implementation (will use the hook system; `agent_progress.py` is complex).
- Custom LLM provider integration (provider-level concern).
- Code interpreter support (Python v2 has `CodeInterpreterModel` enum).
- Integration / Action system (Python v2 `integration.py` -- separate RFC).
- `result.debug()` method (requires Debugger meta-agent; separate RFC).

## Resolved Questions

1. **`Agent` holds a strong reference to `Aixplain` context** -- matches Python v2 `context` class attribute. No need to pass `using: client` on every call. `var context: Aixplain` (strong, not weak).
2. **Fully unify Agent and TeamAgent** -- no separate class. Keep a `public typealias TeamAgent = Agent` for discoverability. An agent with non-empty `subagents` is a team agent.
3. **`as_tool()` via protocol conformance** -- `AgentToolConvertible` protocol from RFC-0004.
4. **`Codable` with custom `CodingKeys`** -- use Swift's native serialization. Map API field names (e.g., `teamId`, `createdAt`) via `CodingKeys`.
5. **Auto-save draft agents in `beforeRun` is acceptable** -- matches Python v2 behavior. Implicit save for convenience.
6. **Progress tracking uses delegate/closure pattern** -- `AgentProgressDelegate` protocol with `didUpdateProgress(_:)`. Not `AsyncStream`.
