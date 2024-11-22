// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let agentOutput = try AgentOutput(json)

import Foundation

// MARK: - AgentOutput
public struct AgentOutput: Codable {
    public let completed: Bool
    public let status: String
    public let data: DataClass
}

// MARK: AgentOutput convenience initializers and mutators

extension AgentOutput {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(AgentOutput.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        completed: Bool? = nil,
        status: String? = nil,
        data: DataClass? = nil
    ) -> AgentOutput {
        return AgentOutput(
            completed: completed ?? self.completed,
            status: status ?? self.status,
            data: data ?? self.data
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - DataClass
public struct DataClass: Codable {
    public let input, output, sessionID: String
    public let intermediateSteps: [IntermediateStep]

    enum CodingKeys: String, CodingKey {
        case input, output
        case sessionID = "session_id"
        case intermediateSteps = "intermediate_steps"
    }
}

// MARK: DataClass convenience initializers and mutators

extension DataClass {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(DataClass.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        input: String? = nil,
        output: String? = nil,
        sessionID: String? = nil,
        intermediateSteps: [IntermediateStep]? = nil
    ) -> DataClass {
        return DataClass(
            input: input ?? self.input,
            output: output ?? self.output,
            sessionID: sessionID ?? self.sessionID,
            intermediateSteps: intermediateSteps ?? self.intermediateSteps
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - IntermediateStep
public struct IntermediateStep: Codable {
    public let agent, input, output: String
    public let toolSteps: [ToolStep]?
    public let thought: String?
    public let runTime, usedCredits: Double

    enum CodingKeys: String, CodingKey {
        case agent, input, output
        case toolSteps = "tool_steps"
        case thought, runTime, usedCredits
    }
}

// MARK: IntermediateStep convenience initializers and mutators

extension IntermediateStep {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(IntermediateStep.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        agent: String? = nil,
        input: String? = nil,
        output: String? = nil,
        toolSteps: [ToolStep]? = nil,
        thought: String?? = nil,
        runTime: Double? = nil,
        usedCredits: Double? = nil
    ) -> IntermediateStep {
        return IntermediateStep(
            agent: agent ?? self.agent,
            input: input ?? self.input,
            output: output ?? self.output,
            toolSteps: toolSteps ?? self.toolSteps,
            thought: thought ?? self.thought,
            runTime: runTime ?? self.runTime,
            usedCredits: usedCredits ?? self.usedCredits
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - ToolStep
public struct ToolStep: Codable {
    public let tool, input, output: String
    public let runTime, usedCredits: JSONNull?
}

// MARK: ToolStep convenience initializers and mutators

extension ToolStep {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ToolStep.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        tool: String? = nil,
        input: String? = nil,
        output: String? = nil,
        runTime: JSONNull?? = nil,
        usedCredits: JSONNull?? = nil
    ) -> ToolStep {
        return ToolStep(
            tool: tool ?? self.tool,
            input: input ?? self.input,
            output: output ?? self.output,
            runTime: runTime ?? self.runTime,
            usedCredits: usedCredits ?? self.usedCredits
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}

// MARK: - Encode/decode helpers

public class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
            return true
    }

    public var hashValue: Int {
            return 0
    }

    public func hash(into hasher: inout Hasher) {
            // No-op
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if !container.decodeNil() {
                    throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
            }
    }

    public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
    }
}
