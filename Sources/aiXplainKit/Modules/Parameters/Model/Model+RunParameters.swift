/*
 AiXplainKit Library.
 ---
 
 aiXplain SDK enables Swift programmers to add AI functions
 to their software.
 
 Copyright 2024 The aiXplain SDK authors
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 AUTHOR: João Pedro Maia
 */

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
