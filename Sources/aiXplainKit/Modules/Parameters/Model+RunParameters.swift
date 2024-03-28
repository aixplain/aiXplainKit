//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 26/03/24.
//

import Foundation

public struct ModelRunParameters: RunParameters, NetworkingParametersProtocol {

    /// The time interval (in seconds) to wait before attempting another polling operation.
    public var pollingWaitTimeInSeconds: TimeInterval = 0.5

    /// The maximum number of retries allowed for polling operations.
    public var maxPollingRetries: Int = 300

    /// The timeout interval (in seconds) for network requests.
    public var networkTimeoutInSecondsInterval: TimeInterval = 10

    /// The maximum number of retries allowed for network calls.
    public var maxNetworkCallRetries: Int = 2

    public static let defaultParameters: ModelRunParameters = ModelRunParameters()

    public init(pollingWaitTimeInSeconds: TimeInterval = 0.5, maxPollingRetries: Int = 300, networkTimeoutInSecondsInterval: TimeInterval = 10, maxNetworkCallRetries: Int = 2) {
        self.pollingWaitTimeInSeconds = pollingWaitTimeInSeconds
        self.maxPollingRetries = maxPollingRetries
        self.networkTimeoutInSecondsInterval = networkTimeoutInSecondsInterval
        self.maxNetworkCallRetries = maxNetworkCallRetries
    }
}
