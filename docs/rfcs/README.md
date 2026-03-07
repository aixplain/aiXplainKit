# aiXplainKit Swift SDK v2 -- RFC Index

This directory contains the Request for Comments (RFC) series for rebuilding aiXplainKit as a v2 SDK, aligned with the [aiXplain Python SDK v2](https://github.com/aixplain/aiXplain/tree/main/aixplain/v2).

**Clean-slate approach**: the existing v1 SDK code is deleted entirely. There is no backward compatibility requirement. The v2 SDK is built from scratch following the Python v2 architecture.

## Execution Order

RFCs are dependency-ordered. Each RFC should be implemented only after its dependencies are complete.

| #    | RFC                                                                 | Priority | Depends on              | Status |
|------|---------------------------------------------------------------------|----------|--------------------------|--------|
| 0001 | [Auth and Credentials](RFC-0001-auth-and-credentials.md)            | P0       | --                       | Done |
| 0005 | [Error Model and Contract Tests](RFC-0005-error-model-and-contract-tests.md) | P0 | RFC-0001                | Done |
| 0002 | [Client Configuration and Transport](RFC-0002-client-configuration-and-transport.md) | P0 | RFC-0001, 0005      | Done |
| 0004 | [Resources and Tools Schema](RFC-0004-resources-tools-schema-alignment.md) | P0 | RFC-0002                | Done |
| 0007 | [Models v2 API](RFC-0007-models-v2-api.md)                          | P0       | RFC-0002, 0004, 0005     | Done |
| 0008 | [Tools and Integrations v2 API](RFC-0008-tools-and-integrations-v2-api.md) | **P0** | RFC-0002, 0004, 0005, 0007 | Done |
| 0003 | [Agents v2 API and Lifecycle](RFC-0003-agents-v2-api-and-lifecycle.md) | **P0** | RFC-0001, 0002, 0004, 0005, 0008 | Done |
| 0009 | [Index and Search v2 API](RFC-0009-index-and-search-v2-api.md)      | P1       | RFC-0002, 0004, 0005, 0007 | Done |
| 0006 | [Clean-Slate Implementation Plan](RFC-0006-clean-slate-implementation-plan.md) | P2 | All above            | Done |

## Dependency Graph

```
RFC-0001 (Auth)
    ├──▶ RFC-0005 (Errors)          ◀── error types used by everything
    └──▶ RFC-0002 (Client)          ◀── consumes Auth + Errors
              └──▶ RFC-0004 (Resources)  ◀── shared protocols/types hub
                        ├──▶ RFC-0007 (Models)
                        │         ├──▶ RFC-0008 (Tools)  ◀── critical for agents
                        │         └──▶ RFC-0009 (Index)
                        │
                        └──▶ RFC-0003 (Agents)  ◀── consumes ALL of the above
                                    │
                                    └──▶ RFC-0006 (Implementation Plan)
```

Key: RFC-0004 is the **interface hub** -- it defines `BaseResource`, `Page<T>`,
`AgentToolDict`, `AssetStatus`, `AIFunction`, `Supplier`, `ResponseStatus`, and
`AnyCodable` that every other RFC consumes.

## Implementation Phases

### Phase 1: Foundation (RFCs 0001, 0005)
Auth types and Error hierarchy. Every other RFC consumes these.

### Phase 2: Client (RFC 0002)
Unified HTTP client and `Aixplain` entry point. Consumes Auth + Errors.

### Phase 3: Shared Protocols (RFC 0004)
Resource protocols, shared enums, and `AgentToolDict`. This is the **interface hub** that all domain RFCs build on.

### Phase 4: Models + Tools (RFCs 0007, 0008)
Model and Tool resources. Tools depend on Models. Both produce `AgentToolConvertible` conformances consumed by Agents.

### Phase 5: Agents (RFC 0003)
The primary product surface. Consumes everything: Auth, Client, Resource protocols, Errors, Models (as LLM reference), and Tools (for agent capabilities).

### Phase 6: Index (RFC 0009)
Index and Search builds on Models. Important for RAG workflows.

### Phase 7: Cleanup (RFC 0006)
Final directory structure, DocC documentation, and verification.

## Deep Dive Status

Each RFC has been enriched with direct references to the Python v2 source code, showing:
- Exact Python v2 code snippets that the Swift implementation should mirror
- Line-by-line mapping of Python v2 patterns to proposed Swift API designs
- Contract test fixtures derived from the Python v2 response structures

## RFC Template

Each RFC follows this structure:

| Section         | Purpose |
|-----------------|---------|
| **Status**      | Draft / Accepted / Implemented |
| **Context**     | What exists today and the Python v2 reference |
| **Decision**    | The chosen approach |
| **API Shape**   | Proposed Swift API with code examples |
| **Implementation** | Files to delete and files to create |
| **Testing**     | Required test coverage |
| **Out of Scope** | What this RFC explicitly does not cover |
| **Resolved Questions** | Decisions made (previously Open Questions) |

## How to Use

1. Read the RFCs in order by phase (Phase 1 → Phase 5).
2. All Open Questions have been resolved -- decisions are documented in each RFC's "Resolved Questions" section.
3. Implement each RFC on a feature branch; update the Status column here when done.
4. RFC-0006 defines the full file deletion list and target directory structure.

## Reference

- [aiXplain Python SDK v2 source](https://github.com/aixplain/aiXplain/tree/main/aixplain/v2)
