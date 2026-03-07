# ``aiXplainKit``

aiXplainKit v2 -- Swift SDK for the aiXplain AI platform.

## Overview

aiXplainKit enables Swift developers to integrate aiXplain's AI capabilities into their applications. The v2 SDK provides a clean, typed API aligned with the [aiXplain Python SDK v2](https://github.com/aixplain/aiXplain/tree/main/aixplain/v2).

## Quick Start

```swift
import aiXplainKit

// Initialize with your API key
let aix = try Aixplain(apiKey: "your-team-api-key")

// Run a model
let model = try await Model.get("model-id", context: aix)
let result = try await model.run(text: "Translate this to French")

// Run an agent
let agent = try await Agent.get("agent-id", context: aix)
let agentResult = try await agent.run("What can you help me with?")
print(agentResult.data?.output ?? "")
```

## Topics

### Entry Point
- ``Aixplain``

### Authentication
- ``Credential``
- ``AuthenticationScheme``

### Client
- ``AixplainClient``
- ``ClientConfiguration``

### Resources
- ``Agent``
- ``Model``
- ``Tool``
- ``Integration``
- ``Index``

### Errors
- ``AixplainError``
- ``APIError``
