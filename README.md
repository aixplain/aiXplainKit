# aiXplainKit v2

Swift SDK for the [aiXplain](https://aixplain.com/) AI platform.

## Quick Start

```swift
import aiXplainKit

let aix = try Aixplain(apiKey: "your-team-api-key")

// Run a model
let model = try await Model.get("model-id", context: aix)
let result = try await model.run(text: "Translate this to French")

// Run an agent
let agent = try await Agent.get("agent-id", context: aix)
let response = try await agent.run("What can you help me with?")
print(response.data?.output ?? "")
```

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aixplain/aiXplainKit.git", from: "2.0.0")
]
```

## API Key Setup

Get your team API key from the [aiXplain platform](https://platform.aixplain.com/).

**Option 1: Environment variable**
```bash
export TEAM_API_KEY="your-key-here"
```
```swift
let aix = try Aixplain() // resolves from environment
```

**Option 2: Explicit parameter**
```swift
let aix = try Aixplain(apiKey: "your-key-here")
```

## Features

### Models

```swift
// Search models
let page = try await Model.search(query: "gpt", pageSize: 10, context: aix)

// Run a model
let model = try await Model.get("model-id", context: aix)
let result = try await model.run(text: "Hello, world!")
```

### Agents

```swift
// Run an agent
let agent = try await Agent.get("agent-id", context: aix)
let result = try await agent.run("Summarize this article")

// Multi-turn conversation
let sessionId = try await agent.generateSessionId()
let turn1 = try await agent.run("My name is Alice", sessionId: sessionId)
let turn2 = try await agent.run("What's my name?", sessionId: sessionId)

// Create a new agent with tools
let agent = Agent(name: "Helper", instructions: "You are helpful", tools: [model], context: aix)
try await agent.save()
```

### Tools

```swift
// Search tools
let tools = try await Tool.searchTools(pageSize: 5, context: aix)

// Use a model as a tool for an agent
let toolDict = model.asAgentTool()
```

### Index & Search

```swift
// Create records and search
let records = [
    Record(text: "Swift is a programming language"),
    Record(text: "Python is used for AI"),
]

let index = try await Index.get("index-id", context: aix)
try await index.upsert(records)
let results = try await index.search("What is Swift?", topK: 5)
```

### Error Handling

```swift
do {
    let agent = try await Agent.get("bad-id", context: aix)
} catch let error as AixplainError {
    print(error.userMessage) // user-friendly message
}
```

## Examples

See the [`Examples/`](Examples/) directory for complete working examples:

| Example | Description |
|---------|-------------|
| [01-QuickStart](Examples/01-QuickStart.swift) | Minimal setup and first API call |
| [02-Models](Examples/02-Models.swift) | Search, fetch, run, and stream models |
| [03-Agents](Examples/03-Agents.swift) | Agents, sessions, and multi-turn conversations |
| [04-Tools](Examples/04-Tools.swift) | Tools, integrations, and agent tool composition |
| [05-Index](Examples/05-Index.swift) | Indexing, records, filters, and semantic search |
| [06-ErrorHandling](Examples/06-ErrorHandling.swift) | Unified error handling patterns |
| [07-TeamAgents](Examples/07-TeamAgents.swift) | Multi-agent teams (subagents) |
| [08-AdvancedAgent](Examples/08-AdvancedAgent.swift) | Tasks, history, output formats, cloning |

## Architecture

Aligned with [aiXplain Python SDK v2](https://github.com/aixplain/aiXplain/tree/main/aixplain/v2). See [`docs/rfcs/`](docs/rfcs/) for the full RFC series.

```
Aixplain (entry point)
  └── AixplainClient (HTTP transport)
        ├── Agent (get/search/save/run/delete)
        ├── Model (get/search/run/stream)
        ├── Tool (get/search/run, subclass of Model)
        ├── Integration (get/connect → Tool)
        └── Index (get/create/search/upsert)
```

## Requirements

- Swift 5.9+
- iOS 15+ / macOS 12+ / watchOS 8+ / tvOS 15+ / visionOS 1+
