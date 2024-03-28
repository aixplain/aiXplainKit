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
public protocol NetworkingParametersProtocol {
    /// The timeout interval (in seconds) for network requests.
    var networkTimeoutInSecondsInterval: TimeInterval {get set}

    /// The maximum number of retries allowed for network calls.
    var maxNetworkCallRetries: Int {get set}
}

public struct NetworkingParameters: NetworkingParametersProtocol {
    public var networkTimeoutInSecondsInterval: TimeInterval = 10
    public var maxNetworkCallRetries: Int = 2
}
