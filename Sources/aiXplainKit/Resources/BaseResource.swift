import Foundation
import OSLog

/// Base class for all aiXplain resources.
///
/// Mirrors Python v2 `BaseResource` from `resource.py`. Provides:
/// - Shared fields: `id`, `name`, `description`
/// - Context reference to `Aixplain` instance
/// - Modification tracking via `_savedState` diffing
/// - `save()` (create or update), `clone()`
///
/// All domain resources (`Agent`, `Model`, `Tool`, `Index`) inherit from this.
open class BaseResource: @unchecked Sendable {
    private static let logger = Logger(subsystem: "aiXplainKit", category: "BaseResource")

    /// Subclasses override to define the API path (e.g., `"v2/agents"`).
    open class var resourcePath: String { "" }

    // MARK: - Core fields

    public var id: String?
    public var name: String?
    public var description: String?

    /// Strong reference to the Aixplain context (resolved question: strong, not weak).
    public var context: Aixplain?

    // MARK: - State tracking

    private var _savedState: [String: String]?
    private var _deleted: Bool = false

    public var isModified: Bool {
        guard let saved = _savedState else { return true }
        return serializableSnapshot() != saved
    }

    public var isDeleted: Bool { _deleted }

    /// URL-encoded resource ID for use in API paths.
    /// URL-safe ID for use in API paths. Encodes all special characters including `/`.
    public var encodedId: String {
        guard let id else { return "" }
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")
        return id.addingPercentEncoding(withAllowedCharacters: allowed) ?? id
    }

    // MARK: - Init

    public required init(id: String? = nil, name: String? = nil, description: String? = nil, context: Aixplain? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.context = context
    }

    // MARK: - State management

    /// Snapshot current state for modification tracking.
    func serializableSnapshot() -> [String: String] {
        var snap: [String: String] = [:]
        if let id { snap["id"] = id }
        if let name { snap["name"] = name }
        if let description { snap["description"] = description }
        return snap
    }

    /// Mark the current state as "saved" (no modifications since).
    public func updateSavedState() {
        _savedState = serializableSnapshot()
    }

    /// Mark the resource as deleted.
    public func markAsDeleted() {
        _deleted = true
        id = nil
    }

    // MARK: - Validation

    /// Ensure the resource is in a valid state for operations.
    public func ensureValidState() throws {
        let typeName = String(describing: Swift.type(of: self))
        if isDeleted {
            throw AixplainError.validation(ValidationError("\(typeName) has been deleted and cannot be used."))
        }
        guard id != nil else {
            throw AixplainError.validation(ValidationError("\(typeName) has not been saved yet. Call .save() first."))
        }
    }

    /// Ensure the context is available.
    public func ensureContext() throws -> Aixplain {
        guard let ctx = context else {
            throw AixplainError.resource(ResourceError("Context is required for resource operations."))
        }
        return ctx
    }

    // MARK: - Save

    /// Build the payload for save operations. Subclasses override for custom serialization.
    open func buildSavePayload() throws -> [String: Any] {
        var payload: [String: Any] = [:]
        if let id { payload["id"] = id }
        if let name { payload["name"] = name }
        if let description { payload["description"] = description }
        return payload
    }

    /// Save the resource: POST (create) if no ID, PUT (update) if ID exists.
    /// Mirrors Python v2 `BaseResource.save()`.
    @discardableResult
    open func save() async throws -> Self {
        let ctx = try ensureContext()
        let payload = try buildSavePayload()

        if let existingId = id {
            let path = "\(Self.resourcePath)/\(encodedId)"
            _ = try await ctx.client.post(path, json: payload)
        } else {
            let result = try await ctx.client.post(Self.resourcePath, json: payload)
            if let newId = result["id"] as? String {
                self.id = newId
            }
            updateFromResponse(result)
        }

        updateSavedState()
        return self
    }

    /// Update local fields from a server response. Subclasses override for custom fields.
    open func updateFromResponse(_ response: [String: Any]) {
        if let id = response["id"] as? String { self.id = id }
        if let name = response["name"] as? String { self.name = name }
        if let desc = response["description"] as? String { self.description = desc }
    }

    // MARK: - Clone

    /// Create a deep copy with `id = nil`. Mirrors Python v2 `BaseResource.clone()`.
    open func clone(name: String? = nil) -> Self {
        let cloned = Self.init(
            id: nil,
            name: name ?? self.name,
            description: self.description,
            context: self.context
        )
        return cloned
    }

    // MARK: - Delete

    /// Delete this resource. Mirrors Python v2 `DeleteResourceMixin.delete()`.
    open func delete() async throws {
        try ensureValidState()
        let ctx = try ensureContext()
        let path = "\(Self.resourcePath)/\(encodedId)"
        _ = try await ctx.client.requestRaw(method: .delete, path: path)
        markAsDeleted()
    }

    // MARK: - Get

    /// Fetch a single resource by ID. Mirrors Python v2 `GetResourceMixin.get()`.
    class func performGet<T: BaseResource>(_ id: String, context: Aixplain, type: T.Type) async throws -> T {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")
        let encodedId = id.addingPercentEncoding(withAllowedCharacters: allowed) ?? id
        let path = "\(T.resourcePath)/\(encodedId)"
        let dict = try await context.client.get(path)
        let instance = try T.from(dict: dict, context: context)
        instance.updateSavedState()
        return instance
    }

    /// Deserialize from a dictionary. Subclasses must override.
    open class func from(dict: [String: Any], context: Aixplain) throws -> Self {
        let instance = Self.init(
            id: dict["id"] as? String,
            name: dict["name"] as? String,
            description: dict["description"] as? String,
            context: context
        )
        return instance
    }

    // MARK: - Search

    /// Search/list resources with pagination. Mirrors Python v2 `SearchResourceMixin.search()`.
    class func performSearch<T: BaseResource>(
        filters: [String: Any],
        context: Aixplain,
        type: T.Type,
        paginatePath: String = "paginate",
        itemsKey: String = "results"
    ) async throws -> Page<T> {
        let path = paginatePath.isEmpty ? T.resourcePath : "\(T.resourcePath)/\(paginatePath)"
        let response = try await context.client.post(path, json: filters)
        let items = response[itemsKey] as? [[String: Any]] ?? []
        let total = response["total"] as? Int ?? items.count
        let pageTotal = response["pageTotal"] as? Int ?? 1
        let pageNumber = filters["pageNumber"] as? Int ?? 0

        let results = try items.map { dict -> T in
            let instance = try T.from(dict: dict, context: context)
            instance.updateSavedState()
            return instance
        }

        return Page(results: results, pageNumber: pageNumber, pageTotal: pageTotal, total: total)
    }

    // MARK: - Run (polling)

    /// Poll a URL for completion. Mirrors Python v2 `RunnableResourceMixin.poll()`.
    public func poll(_ pollURL: String) async throws -> RunResult {
        let ctx = try ensureContext()
        let response = try await ctx.client.get(pollURL)
        let result = RunResult.from(response)
        if result.status == ResponseStatus.failed.rawValue {
            throw APIError.fromFailedOperation(response)
        }
        return result
    }

    /// Poll until completion with exponential backoff. Mirrors Python v2 `sync_poll()`.
    public func syncPoll(
        _ pollURL: String,
        timeout: TimeInterval = 300,
        waitTime: TimeInterval = 0.5
    ) async throws -> RunResult {
        let startTime = Date()
        var currentWait = max(waitTime, 0.2)

        while Date().timeIntervalSince(startTime) < timeout {
            let result = try await poll(pollURL)
            if result.completed {
                return result
            }
            try await Task.sleep(nanoseconds: UInt64(currentWait * 1_000_000_000))
            currentWait = min(currentWait * 1.1, 60)
        }

        throw AixplainError.timeout(TimeoutError(
            "Operation timed out after \(Int(timeout)) seconds",
            pollingURL: pollURL,
            timeout: timeout
        ))
    }

    // MARK: - Required init for clone/from

    public required convenience init() {
        self.init(id: nil, name: nil, description: nil, context: nil)
    }
}
