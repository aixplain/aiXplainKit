//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 26/03/24.
//

import Foundation
public protocol NetworkingParametersProtocol{
    /// The timeout interval (in seconds) for network requests.
    var networkTimeoutInSecondsInterval: TimeInterval {get set}
    
    /// The maximum number of retries allowed for network calls.
    var maxNetworkCallRetries: Int {get set}
}


public struct NetworkingParameters:NetworkingParametersProtocol{
    public var networkTimeoutInSecondsInterval: TimeInterval = 10
    public var maxNetworkCallRetries: Int = 2
}
