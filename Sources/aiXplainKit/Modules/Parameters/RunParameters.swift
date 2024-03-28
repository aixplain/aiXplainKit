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

/**
 A protocol defining the parameters for running a run or operation.
 
 This protocol establishes a set of properties that describe the configuration settings
 required to execute a run, such as the amount of time to wait between polling attempts,
 the number of retries allowed for polling and network calls, and the timeout interval
 for network requests.
 */
public protocol RunParameters {

    /// The time interval (in seconds) to wait before attempting another polling operation.
    var pollingWaitTimeInSeconds: TimeInterval { get set }

    /// The maximum number of retries allowed for polling operations.
    var maxPollingRetries: Int { get set }

}
