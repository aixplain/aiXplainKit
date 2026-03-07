# RFC-0006: Clean-Slate Implementation Plan

| Field        | Value                                    |
|--------------|------------------------------------------|
| Status       | Implemented                              |
| Authors      |                                          |
| Created      | 2026-03-06                               |
| Depends on   | RFC-0004, RFC-0005                       |
| Depended by  | --                                       |
| Priority     | P2 -- Final phase                        |

## Context

The existing v1 Swift SDK is being replaced entirely. There is no backward compatibility requirement -- the v1 code is non-functional and will be deleted. This RFC defines the implementation order, directory structure, and what gets deleted vs created.

## Decision

Erase the entire `Sources/aiXplainKit/` directory (except DocC docs) and rebuild from scratch following the Python v2 architecture defined in RFCs 0001-0005.

## v1 Code Deletion

### Delete entirely

```
Sources/aiXplainKit/
├── aiXplainKit.swift                          # DELETE (AiXplainKit.shared singleton)
├── Manager/
│   └── APIKeyManager.swift                    # DELETE
├── Networking/
│   ├── Networking.swift                       # DELETE
│   ├── Networking+Endpoint.swift              # DELETE
│   ├── Networking+Metadata.swift              # DELETE
│   └── ResponseDecoders/                      # DELETE (entire directory)
├── Errors/
│   ├── Agents+error.swift                     # DELETE
│   ├── File+Error.swift                       # DELETE
│   ├── Model+Error.swift                      # DELETE
│   ├── Networking+Error.swift                 # DELETE
│   └── Pipeline+Error.swift                   # DELETE
├── Modules/
│   ├── Asset/                                 # DELETE (entire directory)
│   ├── Agents/                                # DELETE (entire directory)
│   ├── Model/                                 # DELETE (entire directory)
│   ├── Pipeline/                              # DELETE (no pipelines in v2)
│   ├── TeamAgents/                            # DELETE (unified into Agent)
│   ├── Parameters/                            # DELETE (entire directory)
│   └── Index/                                 # DELETE (entire directory)
├── Provider/                                  # DELETE (entire directory)
├── Extensions/                                # DELETE (entire directory)
└── Manager/FileManager/                       # DELETE (entire directory)
```

### Keep

```
Sources/aiXplainKit/
└── aiXplainKit.docc/                          # KEEP (DocC documentation bundle)
```

### Delete tests

```
Tests/aiXplainKitTests/                        # DELETE (entire directory -- rewrite)
```

## v2 Directory Structure

```
Sources/aiXplainKit/
├── Aixplain.swift                             # Entry point (RFC-0002)
├── Auth/
│   ├── AuthenticationScheme.swift             # RFC-0001
│   └── Credential.swift                       # RFC-0001
├── Client/
│   ├── AixplainClient.swift                   # RFC-0002
│   ├── ClientConfiguration.swift              # RFC-0002
│   ├── RetryPolicy.swift                      # RFC-0002
│   ├── Response.swift                         # RFC-0002
│   └── HTTPMethod.swift                       # RFC-0002
├── Resources/
│   ├── BaseResource.swift                     # RFC-0004
│   ├── Page.swift                             # RFC-0004
│   ├── RunResult.swift                        # RFC-0004
│   ├── AgentToolConvertible.swift             # RFC-0004
│   ├── AgentToolDict.swift                    # RFC-0004
│   └── Protocols/
│       ├── Gettable.swift                     # RFC-0004
│       ├── Searchable.swift                   # RFC-0004
│       ├── Deletable.swift                    # RFC-0004
│       └── Runnable.swift                     # RFC-0004
├── Agents/
│   ├── Agent.swift                            # RFC-0003
│   ├── AgentRunParams.swift                   # RFC-0003
│   ├── AgentRunResult.swift                   # RFC-0003
│   ├── AgentTask.swift                        # RFC-0003
│   ├── ConversationMessage.swift              # RFC-0003
│   └── OutputFormat.swift                     # RFC-0003
├── Models/
│   ├── Model.swift                            # RFC-0007
│   ├── ModelResult.swift                      # RFC-0007
│   ├── ModelSearchParams.swift                # RFC-0007
│   ├── ModelRunParams.swift                   # RFC-0007
│   ├── InputsProxy.swift                      # RFC-0007
│   ├── StreamChunk.swift                      # RFC-0007
│   ├── ModelTypes.swift                       # RFC-0007
│   └── Utility.swift                          # RFC-0007
├── Tools/
│   ├── Tool.swift                             # RFC-0008
│   ├── ToolSearchParams.swift                 # RFC-0008
│   ├── Integration.swift                      # RFC-0008
│   ├── ActionCapable.swift                    # RFC-0008
│   ├── Action.swift                           # RFC-0008
│   ├── ActionsProxy.swift                     # RFC-0008
│   └── ActionInputsProxy.swift               # RFC-0008
├── Index/
│   ├── Index.swift                            # RFC-0009
│   ├── Record.swift                           # RFC-0009 (adapted from v1)
│   ├── IndexFilter.swift                      # RFC-0009 (adapted from v1)
│   ├── EmbeddingModel.swift                   # RFC-0009 (adapted from v1)
│   ├── IndexEngine.swift                      # RFC-0009
│   └── IndexSearchResult.swift               # RFC-0009
├── Enums/
│   ├── AssetStatus.swift                      # RFC-0003/0004
│   ├── ToolType.swift                         # RFC-0004
│   ├── AIFunction.swift                       # RFC-0007
│   └── Supplier.swift                         # RFC-0004
├── Errors/
│   ├── AixplainError.swift                    # RFC-0005
│   ├── APIError.swift                         # RFC-0005
│   ├── AuthError.swift                        # RFC-0001
│   ├── ValidationError.swift                  # RFC-0005
│   ├── TimeoutError.swift                     # RFC-0005
│   ├── FileUploadError.swift                  # RFC-0005
│   └── ResourceError.swift                    # RFC-0005
└── aiXplainKit.docc/                          # KEEP from v1
    ├── aiXplainKit.md                         # Update
    └── Essential/
        └── GettingStarted.md                  # Rewrite for v2 API

Tests/aiXplainKitTests/
├── Unit/
│   ├── Auth/
│   │   └── CredentialTests.swift
│   ├── Client/
│   │   ├── AixplainClientTests.swift
│   │   └── RetryPolicyTests.swift
│   ├── Agents/
│   │   ├── AgentTests.swift
│   │   ├── AgentRunTests.swift
│   │   ├── ConversationMessageTests.swift
│   │   └── AgentTaskTests.swift
│   ├── Models/
│   │   ├── ModelTests.swift
│   │   ├── InputsProxyTests.swift
│   │   └── StreamingTests.swift
│   ├── Tools/
│   │   ├── ToolTests.swift
│   │   ├── IntegrationTests.swift
│   │   └── ActionsProxyTests.swift
│   ├── Index/
│   │   ├── IndexTests.swift
│   │   ├── RecordTests.swift
│   │   └── IndexFilterTests.swift
│   └── Errors/
│       └── ErrorMappingTests.swift
├── Contract/
│   ├── ContractFixtures.swift
│   ├── AgentContractTests.swift
│   ├── ModelContractTests.swift
│   ├── ToolContractTests.swift
│   └── ErrorContractTests.swift
└── Helpers/
    └── MockHTTPTransport.swift
```

## Implementation Order

Each step builds on the previous. After each step, the code should compile and tests should pass.

### Step 1: Foundation (RFC-0001 + RFC-0005 errors)

Create `Auth/`, `Errors/` directories with:
- `AuthenticationScheme`, `Credential`, `AuthError`
- `AixplainError`, `APIError`, `ValidationError`, `TimeoutError`, `FileUploadError`, `ResourceError`

Tests: credential resolution, header generation, error construction.

### Step 2: Client (RFC-0002)

Create `Client/` directory and `Aixplain.swift` with:
- `AixplainClient`, `ClientConfiguration`, `RetryPolicy`, `Response`, `HTTPMethod`
- `Aixplain` entry point with resource accessor stubs

Tests: URL resolution, retry logic, error parsing, credential attachment.

### Step 3: Resource Protocols (RFC-0004)

Create `Resources/` directory with:
- `BaseResource` protocol, `Gettable`, `Searchable`, `Deletable`, `Runnable`
- `Page`, `RunResult`, `AgentToolConvertible`, `AgentToolDict`

Tests: protocol default implementations, Page construction, RunResult decoding.

### Step 4: Models (RFC-0007)

Create `Models/` directory with:
- `Model` class conforming to resource protocols
- `ModelResult`, `ModelSearchParams`, `ModelRunParams`, `InputsProxy`, `StreamChunk`
- Sync/async routing based on `connectionType`
- `Utility` resource for custom code functions

Tests: model CRUD, run routing, InputsProxy, streaming SSE, contract fixtures.

### Step 5: Tools and Integrations (RFC-0008)

Create `Tools/` directory with:
- `Tool` class with CRUD, run (action-based), `as_tool()`
- `Integration` with `connect()` to create tools
- `ActionCapable` protocol, `Action`, `ActionsProxy`, `ActionInputsProxy`

Tests: tool lifecycle, action listing, integration connect, agent tool serialization.

### Step 6: Agents (RFC-0003)

Create `Agents/` directory with:
- `Agent` class conforming to resource protocols
- `AgentRunParams`, `AgentRunResult`, `ConversationMessage`, `AgentTask`, `OutputFormat`
- Save/clone/delete, run/runAsync/poll/syncPoll, generateSessionId
- Tool and subagent management

Tests: full agent lifecycle, payload construction, hook behavior, contract fixtures.

### Step 7: Index (RFC-0009)

Create `Index/` directory with:
- `Index` class with create/search/upsert/getDocument/count
- Adapted `Record`, `IndexFilter`, `EmbeddingModel` from v1
- `IndexEngine`, `IndexSearchResult`

Tests: index lifecycle, text/image search, record CRUD, filter construction.

### Step 8: Enums + DocC (cleanup)

Create `Enums/` directory and update DocC:
- `AssetStatus`, `ToolType`, `AIFunction`, `Supplier`
- Rewrite `aiXplainKit.md` and getting-started guide for v2 API

## Minimum Viable v2

The minimum to ship is Steps 1-6 (Auth + Client + Resource Protocols + Models + Tools + Agents). This gives users:

```swift
let aix = try Aixplain(apiKey: "your-key")

// Get and run a model
let model = try await aix.Model.get("model-id")
let modelResult = try await model.run(text: "Translate this to French")

// Stream a model response
for try await chunk in model.runStream(text: "Explain quantum computing") {
    print(chunk.data, terminator: "")
}

// Create a tool from a model for agent use
let tool = model.asAgentTool()

// Get and run an agent with tools
let agent = try await aix.Agent.get("agent-id")
let result = try await agent.run("Hello, what can you do?")
print(result.data?.output)

// Create a new agent with tools
let newAgent = Agent(name: "My Agent", instructions: "You are helpful", tools: [tool])
try await newAgent.save()

// Session with history
let sessionId = try await agent.generateSessionId(history: [
    ConversationMessage(role: .user, content: "Hi"),
    ConversationMessage(role: .assistant, content: "Hello!")
])
let result2 = try await agent.run("Follow up question", sessionId: sessionId)

// Create and search an index
let index = try await Index.create(name: "Knowledge", description: "My docs", context: aix)
try await index.upsert([Record(text: "Swift is a programming language")])
let hits = try await index.search("What is Swift?")
```

## Swift Version

Target Swift 5.9+ for `Sendable` support. Swift 6 strict concurrency can be adopted later via compiler flags.

## Resolved Questions

1. **DocC rewrite is a separate pass** -- not part of this plan. DocC will be updated after all RFCs are implemented.
2. **No Pipelines** -- pipelines are not part of the v2 SDK. They are removed and not reimplemented.
3. **Package name remains `aiXplainKit`** -- no rename.
