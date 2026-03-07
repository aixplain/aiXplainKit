# RFC-0009: Index and Search v2 API

| Field        | Value                                    |
|--------------|------------------------------------------|
| Status       | Implemented                              |
| Authors      |                                          |
| Created      | 2026-03-06                               |
| Depends on   | RFC-0002, RFC-0004, RFC-0005, RFC-0007   |
| Depended by  | --                                       |
| Priority     | P1 -- After core resources               |

## Context

### Current Swift SDK (well-developed)

The Swift SDK's Index module is one of the more complete areas. It includes:

- **`IndexModel`** -- subclass of `Model` with `search()` (text and image), `upsert()`, `get(documentID:)`, `count()`, and a subscript accessor.
- **`Record`** -- value type for index items with text/image variants, attributes, and Codable conformance.
- **`IndexFilter`** -- predicate type with `IndexFieldOperator` (equals, contains, greaterThan, etc.).
- **`EmbeddingModel`** -- enum of supported embedding models (Snowflake, OpenAI Ada, JINA, BGE-M3, etc.).
- **`AiXplainEngine`** -- enum for index engines (AIR or custom).
- **`IndexProvider`** -- creates and fetches indexes by ID.
- **`IndexSearchOutput`** -- response decoder for search results.

### Python v2 gaps

The Python v2 SDK does **not** have a dedicated Index module. Indexing is handled through generic model/tool execution (the index is a model with `function="search"`). There is no `index.py` file in the Python v2 directory.

This means the Swift SDK's Index module is **more advanced** than the Python v2 in this area. The v2 rewrite should preserve and improve the existing functionality while adapting it to the new architecture.

### What works well in the current Swift implementation

1. **`Record`** -- clean value type with text/image variants, metadata attributes, S3 upload for images.
2. **`IndexFilter`** -- expressive filter system with subscript shorthand.
3. **`EmbeddingModel`** -- convenient enum with model IDs.
4. **Subscript access** -- `index[documentID]` for single record fetch.
5. **Image search** -- supports image-to-image search with automatic upload.

### What needs to change for v2

1. **`IndexModel` subclasses `Model`** -- should use v2 `Model` as base or be standalone.
2. **`IndexProvider` uses `ModelProvider`** -- should use v2 `AixplainClient` directly.
3. **Custom networking** -- `runSearch()` and `pollingSearch()` duplicate the polling logic that now lives in `Runnable` protocol.
4. **`AiXplainEngine`** uses `ModelProvider` -- should use v2 model access.
5. **No pagination** -- `search()` returns all results in one call.
6. **Error types** -- uses `IndexErrors` and `ModelError` instead of unified `AixplainError`.

## Decision

Rebuild the Index module on top of v2 architecture (RFC-0002 client, RFC-0004 resource protocols, RFC-0007 model), preserving the well-designed `Record`, `IndexFilter`, and `EmbeddingModel` types.

## API Shape

### Index

```swift
/// An index resource backed by a search model on the aiXplain platform.
/// Functionally equivalent to a Model with function="search".
public final class Index: @unchecked Sendable {
    public static let resourcePath = "sdk/models"

    public var id: String?
    public var name: String?
    public var description: String?

    // The underlying model ID
    public var modelId: String?

    weak var context: Aixplain?
}
```

### Index CRUD

```swift
extension Index {
    /// Get an existing index by ID.
    public static func get(_ id: String, context: Aixplain) async throws -> Index

    /// Create a new index.
    /// Mirrors current `IndexProvider.create()` -- uses an engine model to create the index.
    public static func create(
        name: String,
        description: String,
        embedding: EmbeddingModel = .openaiAda002,
        engine: IndexEngine = .air,
        context: Aixplain
    ) async throws -> Index
}
```

### Index operations

```swift
extension Index {
    /// Text search.
    public func search(
        _ query: String,
        topK: Int = 10,
        filters: [IndexFilter] = []
    ) async throws -> IndexSearchResult

    /// Image search.
    public func search(
        image: URL,
        topK: Int = 10,
        filters: [IndexFilter] = []
    ) async throws -> IndexSearchResult

    /// Upsert documents into the index.
    @discardableResult
    public func upsert(_ records: [Record]) async throws -> Bool

    /// Get a single document by ID.
    public func getDocument(_ id: String) async throws -> Record?

    /// Count documents in the index.
    public func count() async throws -> Int

    /// Subscript access (mirrors current Swift SDK).
    public subscript(id: String) -> Record? {
        get async throws
    }
}
```

### Record (preserve from v1 -- well-designed)

```swift
/// A single item in the index. Preserved from v1 with minor cleanup.
public struct Record: Codable, Identifiable, Sendable {
    public enum DataType: String, Codable, Sendable {
        case text
        case image
    }

    public let id: String
    public let dataType: DataType
    public let value: String
    public let attributes: [String: String]
    public let uri: URL?

    /// Create a text record.
    public init(text: String, attributes: [String: String] = [:], id: String = UUID().uuidString)

    /// Create an image record (uploads to S3 if local file).
    public init(image: URL, attributes: [String: String] = [:], id: String = UUID().uuidString) async throws
}
```

### IndexFilter (preserve from v1 -- well-designed)

```swift
/// A filter for constraining index search queries. Preserved from v1.
public struct IndexFilter: Sendable {
    public let fieldName: String
    public let operation: FieldOperator

    /// Subscript shorthand: `IndexFilter["author", .equals("Woolf")]`
    public static subscript(fieldName: String, operation: FieldOperator) -> IndexFilter

    public func toDict() -> [String: String]
}

public enum FieldOperator: Sendable {
    case equals(String)
    case notEquals(String)
    case contains(String)
    case notContains(String)
    case greaterThan(String)
    case lessThan(String)
    case greaterThanOrEquals(String)
    case lessThanOrEquals(String)
}

/// Builder pattern for chaining filters.
/// Usage:
///   let filters = IndexFilter.builder()
///       .where("author", .equals("Woolf"))
///       .where("year", .greaterThan("1920"))
///       .build()
public class IndexFilterBuilder {
    private var filters: [IndexFilter] = []

    public func `where`(_ field: String, _ op: FieldOperator) -> IndexFilterBuilder {
        filters.append(IndexFilter(fieldName: field, operation: op))
        return self
    }

    public func build() -> [IndexFilter] { filters }
}

extension IndexFilter {
    public static func builder() -> IndexFilterBuilder { IndexFilterBuilder() }
}
```

### EmbeddingModel (preserve and extend)

```swift
/// Supported embedding models. Preserved from v1.
public enum EmbeddingModel: CaseIterable, Identifiable, Sendable {
    case snowflakeArcticEmbedMLong
    case openaiAda002
    case snowflakeArcticEmbedLV20
    case jinaClipV2Multimodal
    case multilingualE5Large
    case bgeM3
    case aixplainLegalEmbeddings
    case custom(id: String)

    public var id: String { ... }
}
```

### IndexEngine (renamed from AiXplainEngine)

```swift
/// Index engine backend. Renamed from `AiXplainEngine` for clarity.
public enum IndexEngine: Sendable {
    case air
    case custom(id: String)

    public var id: String { ... }
}
```

### IndexSearchResult

```swift
public struct IndexSearchResult: Codable, Sendable {
    public let results: [SearchHit]
    public let totalCount: Int?
}

public struct SearchHit: Codable, Sendable {
    public let documentId: String
    public let score: Double
    public let data: String
    public let attributes: [String: String]
}
```

## Shared Contracts

### Consumes from other RFCs

| Type | From RFC | How it's used |
|------|----------|---------------|
| `AixplainClient` | RFC-0002 | Via `context.client` for HTTP calls (search, upsert, get, count) |
| `Aixplain` | RFC-0002 | `context` reference; provides `context.model_url` for index operations |
| `ClientConfiguration` | RFC-0002 | `modelsRunURL` for index run URL (indexes are models) |
| `Page<T>` | RFC-0004 | Could be used for paginated search results in future |
| `AnyCodable` | RFC-0004 | Search result data fields |
| `AixplainError` | RFC-0005 | Thrown on HTTP failures |
| `FileUploadError` | RFC-0005 | Thrown by `Record.init(image:)` on upload failure |
| `Model` | RFC-0007 | `Index.create()` uses an engine Model to create the index; index IS a model with function=search |

### Produces for other RFCs

| Type | Consumed by | How it's used |
|------|-------------|---------------|
| `Index` | RFC-0003 (agents can use indexes as tools) | Index could be exposed as an agent tool for RAG |
| `Record` | -- | Self-contained index item type |
| `IndexFilter` | -- | Self-contained filter type |
| `EmbeddingModel` | -- | Self-contained embedding model catalog |

### Key interaction: Index creation flow

```
Index.create(name: "KB", embedding: .openaiAda002, engine: .air, context: aix)
  └── engine = Model.get(IndexEngine.air.id)     // RFC-0007: get the AIR engine model
        └── engine.run(data: name, model: embeddingId)  // RFC-0007: run engine to create index
              └── response.output = indexModelId
                    └── Model.get(indexModelId)         // RFC-0007: fetch the created index model
                          └── Index(from: model)        // Wrap as Index
```

## Implementation

### Files to delete

- `Sources/aiXplainKit/Modules/Index/IndexModel.swift`
- `Sources/aiXplainKit/Modules/Index/IndexerModel.swift`
- `Sources/aiXplainKit/Provider/Indexing/IndexProvider.swift`
- `Sources/aiXplainKit/Networking/ResponseDecoders/IndexSearchOutput.swift`

### Files to preserve (adapted)

- `Sources/aiXplainKit/Modules/Index/Record.swift` → move to `Sources/aiXplainKit/Index/Record.swift`
- `Sources/aiXplainKit/Modules/Index/IndexFilter.swift` → move to `Sources/aiXplainKit/Index/IndexFilter.swift`
- `Sources/aiXplainKit/Modules/Index/EmbeddingModel.swift` → move to `Sources/aiXplainKit/Index/EmbeddingModel.swift`

### Files to create

| File | Content |
|------|---------|
| `Sources/aiXplainKit/Index/Index.swift` | Index class with CRUD and operations |
| `Sources/aiXplainKit/Index/IndexEngine.swift` | IndexEngine enum (renamed from AiXplainEngine) |
| `Sources/aiXplainKit/Index/IndexSearchResult.swift` | Search result types |

## Testing

- Unit: `Index.create()` calls engine model with correct payload.
- Unit: `Index.search()` (text) builds correct payload with action="search".
- Unit: `Index.search()` (image) uploads to S3 first, then searches.
- Unit: `Index.upsert()` sends records in correct format.
- Unit: `Index.getDocument()` dispatches action="get_document".
- Unit: `Index.count()` dispatches action="count".
- Unit: `Record` text/image initialization.
- Unit: `Record` Codable round-trip.
- Unit: `IndexFilter` subscript shorthand and `toDict()`.
- Unit: `IndexSearchResult` decoding from fixture JSON.
- Contract: search response fixture.
- Integration: create index → upsert records → search → verify results.

## Out of Scope

- Real-time index updates / webhooks.
- Index deletion (not supported by platform currently).
- Batch operations beyond upsert.
- Index metrics / analytics.

## Resolved Questions

1. **`Index` is a standalone type that wraps a `Model`** -- not a subclass. Holds a `modelId` reference and delegates execution to the underlying model via `context.client`.
2. **Keep `Record.init(image:)` async initializer** -- automatic S3 upload on init is convenient and matches v1 behavior.
3. **`EmbeddingModel` uses Swift `camelCase` convention** -- e.g., `.snowflakeArcticEmbedMLong`, `.openaiAda002`, `.bgeM3`.
4. **`IndexFilter` adopts a builder pattern** for chaining filters.
