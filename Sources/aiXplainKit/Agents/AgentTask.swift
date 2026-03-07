import Foundation

/// A task definition for agent workflows with dependency support.
///
/// Mirrors Python v2 `Task` dataclass from `agent.py`.
public struct AgentTask: Codable, Sendable {
    public let name: String
    public var instructions: String?
    public var expectedOutput: String?
    public var dependencies: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case instructions = "description"
        case expectedOutput
        case dependencies
    }

    public init(name: String, instructions: String? = nil, expectedOutput: String? = nil, dependencies: [String] = []) {
        self.name = name
        self.instructions = instructions
        self.expectedOutput = expectedOutput
        self.dependencies = dependencies
    }
}
