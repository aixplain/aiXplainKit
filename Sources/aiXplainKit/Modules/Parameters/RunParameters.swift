//
//  File.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 26/03/24.
//

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
