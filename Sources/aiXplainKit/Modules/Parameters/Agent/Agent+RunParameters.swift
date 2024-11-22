//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 18/11/24.
//

import Foundation

/// A struct representing the parameters used to run an agent.
///
/// The `AgentRunParameters` struct includes configurations for polling, networking, and agent execution. These parameters define how the agent should behave during its lifecycle, such as timeouts, retry limits, and additional settings for execution.
public struct AgentRunParameters: RunParameters, NetworkingParametersProtocol {

    // MARK: - Polling Parameters

    /// The time interval (in seconds) to wait before attempting another polling operation.
    public var pollingWaitTimeInSeconds: TimeInterval

    /// The maximum number of retries allowed for polling operations.
    public var maxPollingRetries: Int

    // MARK: - Networking Parameters

    /// The timeout interval (in seconds) for network requests.
    public var networkTimeoutInSecondsInterval: TimeInterval

    /// The maximum number of retries allowed for network calls.
    public var maxNetworkCallRetries: Int

    // MARK: - Agent Execution Parameters

    /// The chat history data.
    public var history: Data?

    /// The name of the model process.
    public var name: String

    /// The timeout interval (in seconds) for the agent execution.
    public var timeout: Float

    /// Additional parameters for agent execution, serialized as data.
    public var parameters: Data?

    /// The maximum number of tokens that the agent can generate.
    public var maxTokens: Int

    /// The maximum number of iterations the agent is allowed to execute.
    public var maxIterations: Int

    // MARK: - Default Parameters

    /// A set of default parameters for running an agent.
    public static let defaultParameters: AgentRunParameters = AgentRunParameters()

    // MARK: - Initializer

    /// Initializes a new `AgentRunParameters` instance with specified values.
    ///
    /// - Parameters:
    ///   - pollingWaitTimeInSeconds: Time interval between polling attempts (default is `0.5` seconds).
    ///   - maxPollingRetries: Maximum number of retries for polling operations (default is `300` retries).
    ///   - networkTimeoutInSecondsInterval: Timeout for network requests (default is `10` seconds).
    ///   - maxNetworkCallRetries: Maximum number of retries for network calls (default is `2` retries).
    ///   - history: Optional chat history data (default is `nil`).
    ///   - name: The name of the model process (default is `"model_process"`).
    ///   - timeout: Timeout for agent execution (default is `300` seconds).
    ///   - parameters: Additional parameters for execution (default is `nil`).
    ///   - maxTokens: Maximum number of tokens the agent can generate (default is `2500`).
    ///   - maxIterations: Maximum number of iterations for the agent (default is `10`).
    public init(
        pollingWaitTimeInSeconds: TimeInterval = 0.5,
        maxPollingRetries: Int = 300,
        networkTimeoutInSecondsInterval: TimeInterval = 10,
        maxNetworkCallRetries: Int = 2,
        history: Data? = nil,
        name: String = "model_process",
        timeout: Float = 300,
        parameters: Data? = nil,
        maxTokens: Int = 2500,
        maxIterations: Int = 10
    ) {
        self.pollingWaitTimeInSeconds = pollingWaitTimeInSeconds
        self.maxPollingRetries = maxPollingRetries
        self.networkTimeoutInSecondsInterval = networkTimeoutInSecondsInterval
        self.maxNetworkCallRetries = maxNetworkCallRetries
        self.history = history
        self.name = name
        self.timeout = timeout
        self.parameters = parameters
        self.maxTokens = maxTokens
        self.maxIterations = maxIterations
    }

    // MARK: - Utilities

    /// Returns an array of parameter names and their corresponding values.
    ///
    /// - Returns: A collection of tuples containing parameter names and values.
    func runParametersIterator() -> [(paramName: String, value: Any)] {
        let selectedProperties: [String: Any?] = [
            "history": history,
            "name": name,
            "timeout": timeout,
            "parameters": parameters,
            "max_tokens": maxTokens,
            "max_iterations": maxIterations
        ]
        return selectedProperties.compactMap { key, value in
            guard let value = value else { return nil }
            return (paramName: key, value: value)
        }
    }
}
