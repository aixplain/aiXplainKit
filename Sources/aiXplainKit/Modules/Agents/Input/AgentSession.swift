//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 27/08/25.
//

import Foundation

public struct AgentSession:CustomStringConvertible {
    public var id: String = UUID().uuidString
    public var timestamp: Date = Date()
    
    public var description: String {
        return id
    }
    
    
}
