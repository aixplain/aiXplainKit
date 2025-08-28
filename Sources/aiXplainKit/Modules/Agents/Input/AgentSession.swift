//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 27/08/25.
//

import Foundation

public struct AgentSession:CustomStringConvertible {
    var id: String = UUID().uuidString
    var timestamp: Date = Date()
    
    public var description: String {
        return id
    }
    
    
}
