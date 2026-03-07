import Foundation
import OSLog

/// Agent resource -- the primary product surface of the aiXplain SDK.
///
/// Mirrors Python v2 `Agent(BaseResource, SearchResourceMixin, GetResourceMixin,
/// DeleteResourceMixin, RunnableResourceMixin)` from `agent.py`.
///
/// Agents with non-empty `subagents` are team agents (no separate class).
public final class Agent: BaseResource {
    private static let logger = Logger(subsystem: "aiXplainKit", category: "Agent")
    public override class var resourcePath: String { "v2/agents" }

    public static let defaultLLM = "669a63646eb56306647e1091"

    // MARK: - Agent fields

    public var instructions: String?
    public var status: AssetStatus = .draft
    public var teamId: Int?
    public var llmId: String = Agent.defaultLLM
    public var tools: [any AgentToolConvertible] = []
    public var subagents: [Agent] = []
    public var tasks: [AgentTask] = []
    public var outputFormat: OutputFormat = .text
    public var maxIterations: Int = 5
    public var maxTokens: Int = 2048
    public var createdAt: String?
    public var updatedAt: String?

    /// TeamAgent is just an Agent with subagents.
    public var isTeamAgent: Bool { !subagents.isEmpty }

    // MARK: - Init

    public required init(id: String? = nil, name: String? = nil, description: String? = nil, context: Aixplain? = nil) {
        super.init(id: id, name: name, description: description, context: context)
    }

    public required convenience init() {
        self.init(id: nil, name: nil, description: nil, context: nil)
    }

    public init(
        name: String,
        instructions: String = "",
        llmId: String = Agent.defaultLLM,
        tools: [any AgentToolConvertible] = [],
        description: String = "",
        context: Aixplain? = nil
    ) {
        super.init(id: nil, name: name, description: description, context: context)
        self.instructions = instructions
        self.llmId = llmId
        self.tools = tools
    }

    // MARK: - Get

    public class func get(_ id: String, context: Aixplain) async throws -> Agent {
        try await performGet(id, context: context, type: Agent.self)
    }

    // MARK: - Search

    public class func search(
        query: String? = nil,
        pageNumber: Int = 0,
        pageSize: Int = 20,
        context: Aixplain
    ) async throws -> Page<Agent> {
        var filters: [String: Any] = [
            "pageNumber": pageNumber,
            "pageSize": pageSize
        ]
        if let q = query { filters["q"] = q }
        return try await performSearch(filters: filters, context: context, type: Agent.self)
    }

    // MARK: - Save

    @discardableResult
    public override func save() async throws -> Self {
        try beforeSave()
        return try await super.save()
    }

    public func save(asDraft: Bool) async throws -> Agent {
        status = asDraft ? .draft : .onboarded
        return try await save()
    }

    func beforeSave() throws {
        // Validate subagent dependencies
        for sub in subagents where sub.id == nil {
            throw AixplainError.validation(ValidationError(
                "Subagent '\(sub.name ?? "unnamed")' must be saved before saving the team agent."
            ))
        }
    }

    public override func buildSavePayload() throws -> [String: Any] {
        var payload: [String: Any] = [:]
        if let id { payload["id"] = id }
        if let name { payload["name"] = name }
        if let description { payload["description"] = description }
        if let instructions { payload["instructions"] = instructions }
        payload["status"] = status.rawValue
        payload["model"] = ["id": llmId]
        payload["outputFormat"] = outputFormat.rawValue
        payload["maxIterations"] = maxIterations
        payload["maxTokens"] = maxTokens

        let convertedTools = tools.map { $0.asAgentTool() }
        let toolDicts: [[String: Any]] = try convertedTools.map { tool in
            let data = try JSONEncoder().encode(tool)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw AixplainError.validation(ValidationError("Failed to serialize tool"))
            }
            return dict
        }
        payload["tools"] = toolDicts

        if !subagents.isEmpty {
            payload["agents"] = subagents.compactMap { agent -> [String: Any]? in
                guard let id = agent.id else { return nil }
                return ["id": id, "inspectors": [] as [Any]]
            }
        }

        if !tasks.isEmpty {
            let tasksData = try JSONEncoder().encode(tasks)
            payload["tasks"] = try JSONSerialization.jsonObject(with: tasksData)
        }

        return payload
    }

    // MARK: - Run

    /// Run the agent with a simple query string.
    public func run(_ query: String, sessionId: String? = nil) async throws -> AgentRunResult {
        try await run(query: query, sessionId: sessionId)
    }

    /// Run the agent with full parameters.
    public func run(
        query: String,
        sessionId: String? = nil,
        variables: [String: Any]? = nil,
        history: [ConversationMessage]? = nil,
        outputFormat: OutputFormat? = nil,
        maxTokens: Int? = nil,
        maxIterations: Int? = nil
    ) async throws -> AgentRunResult {
        try beforeRun()
        try ensureValidState()
        let ctx = try ensureContext()

        let payload = try buildRunPayload(
            query: query,
            sessionId: sessionId,
            variables: variables,
            history: history,
            outputFormat: outputFormat,
            maxTokens: maxTokens,
            maxIterations: maxIterations
        )

        let path = "\(Self.resourcePath)/\(encodedId)/run"
        let response = try await ctx.client.post(path, json: payload)

        let status = response["status"] as? String ?? "IN_PROGRESS"
        if status == ResponseStatus.failed.rawValue {
            throw APIError.fromFailedOperation(response)
        }

        let result = AgentRunResult.from(response)
        if result.completed { return result }

        if let pollURL = result.url, pollURL.hasPrefix("http") {
            return try await pollAgent(pollURL)
        }

        return result
    }

    /// Run async -- returns immediately without polling.
    public func runAsync(
        query: String,
        sessionId: String? = nil,
        variables: [String: Any]? = nil
    ) async throws -> AgentRunResult {
        try beforeRun()
        try ensureValidState()
        let ctx = try ensureContext()

        let payload = try buildRunPayload(query: query, sessionId: sessionId, variables: variables)
        let path = "\(Self.resourcePath)/\(encodedId)/run"
        let response = try await ctx.client.post(path, json: payload)
        return AgentRunResult.from(response)
    }

    // MARK: - Session

    /// Generate a unique session ID.
    /// Format: `"{agentId}_{timestamp}"` (matches Python v2).
    public func generateSessionId(history: [ConversationMessage]? = nil) async throws -> String {
        if id == nil {
            try await save(asDraft: true)
        }

        if let history {
            try ConversationMessage.validateHistory(history)
        }

        let timestamp = Self.timestampString()
        let sessionId = "\(id!)_\(timestamp)"

        if let history, !history.isEmpty {
            _ = try? await runAsync(
                query: "/",
                sessionId: sessionId
            )
        }

        return sessionId
    }

    // MARK: - Clone

    public override func clone(name: String? = nil) -> Self {
        let cloned = Self.init(
            id: nil,
            name: name ?? self.name,
            description: self.description,
            context: self.context
        )
        cloned.instructions = self.instructions
        cloned.llmId = self.llmId
        cloned.outputFormat = self.outputFormat
        cloned.maxIterations = self.maxIterations
        cloned.maxTokens = self.maxTokens
        cloned.status = .draft
        return cloned
    }

    // MARK: - Deserialization

    public override class func from(dict: [String: Any], context: Aixplain) throws -> Self {
        let instance = Self.init(
            id: dict["id"] as? String,
            name: dict["name"] as? String,
            description: dict["description"] as? String,
            context: context
        )
        instance.instructions = dict["instructions"] as? String
        instance.teamId = dict["teamId"] as? Int
        instance.createdAt = dict["createdAt"] as? String
        instance.updatedAt = dict["updatedAt"] as? String
        instance.maxIterations = dict["maxIterations"] as? Int ?? 5
        instance.maxTokens = dict["maxTokens"] as? Int ?? 2048

        if let statusStr = dict["status"] as? String {
            instance.status = AssetStatus(rawValue: statusStr) ?? .draft
        }
        if let modelDict = dict["model"] as? [String: Any], let llmId = modelDict["id"] as? String {
            instance.llmId = llmId
        } else if let llmId = dict["llmId"] as? String {
            instance.llmId = llmId
        }
        if let fmt = dict["outputFormat"] as? String {
            instance.outputFormat = OutputFormat(rawValue: fmt) ?? .text
        }
        if let taskList = dict["tasks"] as? [[String: Any]] {
            instance.tasks = taskList.compactMap { taskDict in
                guard let name = taskDict["name"] as? String else { return nil }
                return AgentTask(
                    name: name,
                    instructions: taskDict["description"] as? String,
                    expectedOutput: taskDict["expectedOutput"] as? String,
                    dependencies: taskDict["dependencies"] as? [String] ?? []
                )
            }
        }
        return instance
    }

    // MARK: - Private

    private func beforeRun() throws {
        if status == .draft && isModified {
            Agent.logger.info("Auto-saving draft agent before run")
        }
    }

    func buildRunPayload(
        query: String,
        sessionId: String? = nil,
        variables: [String: Any]? = nil,
        history: [ConversationMessage]? = nil,
        outputFormat: OutputFormat? = nil,
        maxTokens: Int? = nil,
        maxIterations: Int? = nil
    ) throws -> [String: Any] {
        var inputData: [String: Any] = ["input": query]
        if let variables { inputData.merge(variables) { _, new in new } }

        var executionParams: [String: Any] = [
            "outputFormat": (outputFormat ?? self.outputFormat).rawValue,
            "maxTokens": maxTokens ?? self.maxTokens,
            "maxIterations": maxIterations ?? self.maxIterations,
            "maxTime": 300
        ]

        var payload: [String: Any] = [
            "id": id!,
            "query": inputData,
            "executionParams": executionParams,
            "runResponseGeneration": true
        ]

        if let sessionId { payload["sessionId"] = sessionId }

        if let history {
            try ConversationMessage.validateHistory(history)
            let historyDicts = try history.map { msg -> [String: Any] in
                let data = try JSONEncoder().encode(msg)
                return try JSONSerialization.jsonObject(with: data) as! [String: Any]
            }
            payload["history"] = historyDicts
        }

        return payload
    }

    private func pollAgent(_ pollURL: String, timeout: TimeInterval = 300, waitTime: TimeInterval = 0.5) async throws -> AgentRunResult {
        let startTime = Date()
        var currentWait = max(waitTime, 0.2)
        let ctx = try ensureContext()

        while Date().timeIntervalSince(startTime) < timeout {
            let response = try await ctx.client.get(pollURL)
            let status = response["status"] as? String ?? "IN_PROGRESS"

            if status == ResponseStatus.failed.rawValue {
                throw APIError.fromFailedOperation(response)
            }

            if let err = response["supplierError"] as? String, !err.isEmpty {
                throw AixplainError.api(APIError(message: "Supplier error: \(err)", error: err))
            }

            if response["completed"] as? Bool == true {
                return AgentRunResult.from(response)
            }

            try await Task.sleep(nanoseconds: UInt64(currentWait * 1_000_000_000))
            currentWait = min(currentWait * 1.1, 60)
        }

        throw AixplainError.timeout(TimeoutError(
            "Agent polling timed out after \(Int(timeout))s",
            pollingURL: pollURL,
            timeout: timeout
        ))
    }

    private static func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter.string(from: Date())
    }
}

/// TeamAgent is just an Agent with subagents.
public typealias TeamAgent = Agent
